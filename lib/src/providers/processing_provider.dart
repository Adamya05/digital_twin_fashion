/// Processing Provider
/// 
/// State management for avatar processing and scan status tracking.
/// Handles polling, progress updates, and error states during avatar generation.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/scan_service.dart';
import '../ui/screens/processing_screen.dart';

/// Processing status enum
enum ProcessingStatus {
  idle,
  processing,
  completed,
  error,
  timeout,
}

/// Processing state
class ProcessingState {
  final ProcessingStatus status;
  final String? scanId;
  final double? progress;
  final String? statusMessage;
  final String? avatarUrl;
  final String? errorMessage;

  ProcessingState({
    this.status = ProcessingStatus.idle,
    this.scanId,
    this.progress,
    this.statusMessage,
    this.avatarUrl,
    this.errorMessage,
  });

  ProcessingState copyWith({
    ProcessingStatus? status,
    String? scanId,
    double? progress,
    String? statusMessage,
    String? avatarUrl,
    String? errorMessage,
  }) {
    return ProcessingState(
      status: status ?? this.status,
      scanId: scanId ?? this.scanId,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Processing provider
class ProcessingNotifier extends StateNotifier<ProcessingState> {
  final ScanService _scanService = ScanService();

  ProcessingNotifier() : super(const ProcessingState());

  /// Start the processing workflow
  void startPolling(String scanId) {
    state = state.copyWith(
      status: ProcessingStatus.processing,
      scanId: scanId,
      progress: 0.0,
      statusMessage: 'Initializing...',
      errorMessage: null,
    );
  }

  /// Poll scan status and update state
  Future<bool> pollScanStatus(String scanId) async {
    if (state.status != ProcessingStatus.processing) {
      return false;
    }

    try {
      // Use the scan service's polling method
      final response = await _scanService.pollScanStatus(scanId);
      
      if (response.isSuccess && response.data != null) {
        final scanStatus = response.data!;
        
        // Update progress based on status
        final progress = _calculateProgress(scanStatus);
        
        state = state.copyWith(
          progress: progress,
          statusMessage: _getStatusMessage(scanStatus),
        );

        // Check if processing is complete
        if (scanStatus.isCompleted) {
          // Get avatar URL from the status or fetch it
          final avatarUrl = scanStatus.avatarUrl ?? 
                           await _getAvatarUrlFromScanId(scanId);
          
          state = state.copyWith(
            status: ProcessingStatus.completed,
            avatarUrl: avatarUrl,
            progress: 1.0,
            statusMessage: 'Completed successfully!',
          );
          return true;
        } else if (scanStatus.hasError) {
          state = state.copyWith(
            status: ProcessingStatus.error,
            errorMessage: scanStatus.message ?? 'Unknown processing error',
          );
          return true;
        }
      } else {
        state = state.copyWith(
          status: ProcessingStatus.error,
          errorMessage: response.error ?? 'Failed to check scan status',
        );
        return true;
      }
      
      return false;
    } catch (e) {
      state = state.copyWith(
        status: ProcessingStatus.error,
        errorMessage: 'Network error: ${e.toString()}',
      );
      return true;
    }
  }

  /// Get avatar URL from scan ID
  Future<String?> _getAvatarUrlFromScanId(String scanId) async {
    try {
      final response = await _scanService.getGeneratedAvatar(scanId);
      if (response.isSuccess && response.data != null) {
        return response.data!.imageUrl;
      }
    } catch (e) {
      // Log error but don't fail the process
      print('Failed to get avatar URL: $e');
    }
    
    // Return null to indicate no avatar URL found
    return null;
  }

  /// Calculate progress based on scan status
  double _calculateProgress(ScanStatus scanStatus) {
    if (scanStatus.progress != null) {
      return scanStatus.progress!;
    }
    
    // Fallback progress calculation based on status
    switch (scanStatus.status) {
      case 'processing':
        return 0.5; // 50% progress for processing state
      case 'ready':
        return 1.0; // 100% progress for ready state
      case 'completed':
        return 1.0; // 100% progress for completed state
      case 'error':
        return 0.0; // 0% progress for error state
      default:
        return 0.0;
    }
  }

  /// Get status message for UI display
  String _getStatusMessage(ScanStatus scanStatus) {
    return scanStatus.message ?? 'Processing your avatar...';
  }

  /// Set timeout error
  void setTimeoutError() {
    if (state.status == ProcessingStatus.processing) {
      state = state.copyWith(
        status: ProcessingStatus.timeout,
        errorMessage: 'Processing timeout after 30 seconds',
      );
    }
  }

  /// Reset processing state
  void reset() {
    state = const ProcessingState();
  }

  /// Clear error state
  void clearError() {
    if (state.status == ProcessingStatus.error) {
      state = state.copyWith(
        status: ProcessingStatus.processing,
        errorMessage: null,
      );
    }
  }
}

/// Provider instances
final processingProvider = StateNotifierProvider<ProcessingNotifier, ProcessingState>(
  (ref) => ProcessingNotifier(),
);

/// Helper function to navigate to processing screen
void navigateToProcessingScreen({
  required BuildContext context,
  required String scanId,
}) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (context) => ProcessingScreen(scanId: scanId),
    ),
  );
}