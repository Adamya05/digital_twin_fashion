/// Scan Service
/// 
/// Service for handling avatar scanning and image processing operations.
/// Manages camera access, image capture, and AI processing for avatar generation.
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/avatar_model.dart';

class ScanService {
  final ApiService _apiService = ApiService();

  /// Start the avatar scanning process
  /// Returns a scan session ID that can be used to track progress
  Future<ApiResponse<String>> startScan(String userId) async {
    return _apiService.post<String>(
      '/scan/start',
      {'userId': userId},
      (json) => json['sessionId'] as String,
    );
  }

  /// Upload scan video for processing
  /// Takes a video file and session ID
  Future<ApiResponse<bool>> uploadScanVideo(
    String sessionId,
    File videoFile,
  ) async {
    try {
      // Create multipart request
      final uri = Uri.parse('${ApiService.baseUrl}/api/scan');
      final request = http.MultipartRequest('POST', uri);
      
      // Add session ID
      request.fields['sessionId'] = sessionId;
      
      // Add video file
      final videoStream = videoFile.openRead();
      final videoLength = await videoFile.length();
      final videoMultipart = http.MultipartFile(
        'video',
        videoStream,
        videoLength,
        filename: 'scan_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      request.files.add(videoMultipart);
      
      // Send request
      final response = await request.send();
      
      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Failed to upload video: $e');
    }
  }

  /// Upload scan images for processing (legacy support)
  /// Takes a list of image files and a session ID
  Future<ApiResponse<bool>> uploadScanImages(
    String sessionId,
    List<File> images,
  ) async {
    try {
      // Create multipart request
      final uri = Uri.parse('${ApiService.baseUrl}/api/scan/images');
      final request = http.MultipartRequest('POST', uri);
      
      // Add session ID
      request.fields['sessionId'] = sessionId;
      
      // Add image files
      for (int i = 0; i < images.length; i++) {
        final imageStream = images[i].openRead();
        final imageLength = await images[i].length();
        final imageMultipart = http.MultipartFile(
          'images',
          imageStream,
          imageLength,
          filename: 'scan_frame_$i.jpg',
        );
        request.files.add(imageMultipart);
      }
      
      // Send request
      final response = await request.send();
      
      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Failed to upload images: $e');
    }
  }

  /// Check the status of avatar generation (original format)
  Future<ApiResponse<ScanStatus>> checkScanStatus(String sessionId) async {
    return _apiService.get<ScanStatus>(
      '/scan/status/$sessionId',
      (json) => ScanStatus.fromJson(json),
    );
  }

  /// Check scan status using the specific endpoint format: /api/scan/{id}/status
  Future<ApiResponse<ScanStatus>> pollScanStatus(String scanId) async {
    try {
      // Mock API call for polling - simulates realistic scan processing
      return await _mockApiPollScanStatus(scanId);
    } catch (e) {
      return ApiResponse.error('Failed to poll scan status: $e');
    }
  }

  /// Mock API implementation that simulates realistic scan processing
  Future<ApiResponse<ScanStatus>> _mockApiPollScanStatus(String scanId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Generate mock data based on scanId hash for consistency
    final hashCode = scanId.hashCode.abs();
    final random = (DateTime.now().millisecondsSinceEpoch + hashCode) % 1000;
    
    // Determine processing stage based on time elapsed
    final currentTime = DateTime.now();
    final startTime = DateTime.fromMillisecondsSinceEpoch(random);
    final elapsedSeconds = currentTime.difference(startTime).inSeconds;
    
    String status;
    double progress;
    String message;
    
    if (elapsedSeconds < 2) {
      status = 'processing';
      progress = 0.2;
      message = 'Scanning your unique features...';
    } else if (elapsedSeconds < 4) {
      status = 'processing';
      progress = 0.4;
      message = 'Creating 3D mesh from video...';
    } else if (elapsedSeconds < 6) {
      status = 'processing';
      progress = 0.6;
      message = 'Generating realistic textures...';
    } else if (elapsedSeconds < 8) {
      status = 'processing';
      progress = 0.8;
      message = 'Optimizing for performance...';
    } else if (elapsedSeconds < 10) {
      status = 'ready';
      progress = 1.0;
      message = 'Avatar generation complete!';
      
      // Return ready status - will trigger avatar retrieval
      return ApiResponse.success(
        ScanStatus(
          status: status,
          progress: progress,
          message: message,
        ),
      );
    } else {
      // After 10 seconds, randomly decide to complete or fail (for testing)
      final randomOutcome = random % 10;
      if (randomOutcome == 0) {
        // 10% chance of failure for testing
        status = 'failed';
        progress = 0.0;
        message = 'AI processing failed. Please try again.';
        return ApiResponse.error(message);
      } else {
        // Complete successfully
        status = 'avatar_glb_url';
        progress = 1.0;
        message = 'Your avatar is ready!';
        return ApiResponse.success(
          ScanStatus(
            status: status,
            progress: progress,
            message: message,
            // In a real implementation, this would contain the avatar GLB URL
            extraData: {'avatarUrl': 'https://example.com/generated_avatar.glb'},
          ),
        );
      }
    }
    
    return ApiResponse.success(
      ScanStatus(
        status: status,
        progress: progress,
        message: message,
      ),
    );
  }

  /// Get the completed avatar once processing is finished
  Future<ApiResponse<Avatar>> getGeneratedAvatar(String sessionId) async {
    return _apiService.get<Avatar>(
      '/scan/result/$sessionId',
      (json) => Avatar.fromJson(json),
    );
  }
}

/// Scan status enum for tracking avatar generation progress
class ScanStatus {
  final String status;
  final double? progress;
  final String? message;
  final Map<String, dynamic>? extraData;

  ScanStatus({
    required this.status,
    this.progress,
    this.message,
    this.extraData,
  });

  factory ScanStatus.fromJson(Map<String, dynamic> json) {
    return ScanStatus(
      status: json['status'] as String? ?? 'unknown',
      progress: (json['progress'] as num?)?.toDouble(),
      message: json['message'] as String?,
      extraData: json['extraData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'progress': progress,
      'message': message,
      'extraData': extraData,
    };
  }

  bool get isCompleted => status == 'completed' || status == 'avatar_glb_url';
  bool get isProcessing => status == 'processing';
  bool get hasError => status == 'error' || status == 'failed';
  bool get isReady => status == 'ready';
  
  /// Get avatar URL from extra data if available
  String? get avatarUrl {
    return extraData?['avatarUrl'] as String?;
  }
}
