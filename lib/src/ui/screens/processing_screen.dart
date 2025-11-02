/// Processing Screen
/// 
/// Loading screen displayed during avatar generation and image processing.
/// Shows progress indicators and status updates while users wait for AI processing.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/scan_service.dart';
import '../../providers/processing_provider.dart';
import 'avatar_preview.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  final String scanId;
  
  const ProcessingScreen({
    super.key,
    required this.scanId,
  });

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _knittingController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _knittingAnimation;
  
  Timer? _pollingTimer;
  Timer? _timeoutTimer;
  int _pollAttempts = 0;
  final int _maxPollAttempts = 30; // 30 seconds max
  int _currentRetryDelay = 1;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startProcessing();
    _startTimeout();
  }

  void _initializeAnimations() {
    // Pulse animation for the main message
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    
    // Knitting animation for the skeleton-loader
    _knittingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _knittingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _knittingController, curve: Curves.linear),
    );
    _knittingController.repeat();
  }

  void _startProcessing() {
    ref.read(processingProvider.notifier).startPolling(widget.scanId);
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final provider = ref.read(processingProvider.notifier);
      final success = await provider.pollScanStatus(widget.scanId);
      
      if (success) {
        _stopPolling();
        _handleProcessingComplete();
      } else {
        _pollAttempts++;
        _handlePollingAttempt();
      }
    });
  }

  void _handlePollingAttempt() {
    if (_pollAttempts >= _maxPollAttempts) {
      _stopPolling();
      ref.read(processingProvider.notifier).setTimeoutError();
    } else {
      // Exponential backoff: 1s, 2s, 4s, 8s, etc.
      _currentRetryDelay = (1 * (2 ^ (_pollAttempts ~/5))).clamp(1, 8);
    }
  }

  void _startTimeout() {
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        _stopPolling();
        ref.read(processingProvider.notifier).setTimeoutError();
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _handleProcessingComplete() {
    final processingState = ref.read(processingProvider);
    
    if (processingState.status == ProcessingStatus.completed) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AvatarPreview(
            avatarUrl: processingState.avatarUrl,
            scanId: widget.scanId,
          ),
        ),
      );
    }
  }

  void _retryProcessing() {
    ref.read(processingProvider.notifier).reset();
    setState(() {
      _pollAttempts = 0;
      _currentRetryDelay = 1;
    });
    _startProcessing();
  }

  void _cancelProcessing() {
    _stopPolling();
    _timeoutTimer?.cancel();
    Navigator.of(context).pop(); // Return to scan method selection
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _knittingController.dispose();
    _pollingTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final processingState = ref.watch(processingProvider);
    
    return WillPopScope(
      onWillPop: () async {
        if (processingState.status == ProcessingStatus.processing) {
          _cancelProcessing();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _buildBody(processingState),
        ),
      ),
    );
  }

  Widget _buildBody(ProcessingState state) {
    switch (state.status) {
      case ProcessingStatus.idle:
        return const Center(
          child: CircularProgressIndicator(color: Colors.blue),
        );
      
      case ProcessingStatus.processing:
        return _buildProcessingView();
      
      case ProcessingStatus.completed:
        return _buildCompletedView();
      
      case ProcessingStatus.error:
        return _buildErrorView(state.errorMessage ?? 'Unknown error');
      
      case ProcessingStatus.timeout:
        return _buildTimeoutView();
    }
  }

  Widget _buildProcessingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKnittingAnimation(),
            const SizedBox(height: 48),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: const Text(
                    "We're building your twin — private & encrypted",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildStatusMessages(),
            const SizedBox(height: 24),
            _buildPrivacyNotice(),
            const SizedBox(height: 24),
            _buildProgressIndicator(),
            const SizedBox(height: 24),
            _buildCancelButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildKnittingAnimation() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.withOpacity(0.1),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
      ),
      child: Stack(
        children: [
          // Skeleton knitting pattern
          AnimatedBuilder(
            animation: _knittingAnimation,
            builder: (context, child) {
              return Center(
                child: CustomPaint(
                  size: const Size(100, 100),
                  painter: KnittingPainter(
                    progress: _knittingAnimation.value,
                    color: Colors.blue,
                  ),
                ),
              );
            },
          ),
          // Central icon
          const Center(
            child: Icon(
              Icons.architecture,
              color: Colors.blue,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessages() {
    final messages = [
      'Scanning your unique features...',
      'Creating 3D mesh from video...',
      'Generating realistic textures...',
      'Optimizing for performance...',
      'Almost ready!',
    ];
    
    return Column(
      children: [
        for (int i = 0; i < messages.length; i++)
          AnimatedBuilder(
            animation: _knittingAnimation,
            builder: (context, child) {
              final opacity = (_knittingAnimation.value * messages.length)
                  .clamp(0.0, 1.0);
              
              return Opacity(
                opacity: (opacity - i).clamp(0.0, 1.0) * 
                       (i < (opacity.floor() + 1) ? 1.0 : 0.3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    messages[i],
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade300,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        // Circular progress indicator
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            backgroundColor: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        // Progress percentage
        Text(
          '${((_knittingAnimation.value * 100)).toInt()}%',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        // Spinning dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDot(0),
            const SizedBox(width: 8),
            _buildDot(1),
            const SizedBox(width: 8),
            _buildDot(2),
          ],
        ),
      ],
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _knittingAnimation,
      builder: (context, child) {
        final delay = index * 0.3;
        final animProgress = ((_knittingAnimation.value - delay) * 3)
            .clamp(0.0, 1.0);
        
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withOpacity(animProgress),
          ),
        );
      },
    );
  }

  Widget _buildCancelButton() {
    return TextButton.icon(
      onPressed: _cancelProcessing,
      icon: const Icon(Icons.close, color: Colors.grey),
      label: const Text(
        'Cancel',
        style: TextStyle(color: Colors.grey),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _buildCompletedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 100,
            ),
            const SizedBox(height: 32),
            const Text(
              'Avatar Ready!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your digital twin has been created successfully.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 100,
            ),
            const SizedBox(height: 32),
            const Text(
              'Processing Failed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade300,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _retryProcessing,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _cancelProcessing,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeoutView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.timer_outlined,
              color: Colors.orange,
              size: 100,
            ),
            const SizedBox(height: 32),
            const Text(
              'Processing Timeout',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'The processing is taking longer than expected. Please try again or contact support.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _retryProcessing,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _cancelProcessing,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: Colors.blue.shade300,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Your data is protected',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Processed on secure India-based servers\n'
            '• End-to-end encrypted transmission\n'
            '• Deleted automatically after 30 days\n'
            '• Never shared with third parties',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the knitting animation
class KnittingPainter extends CustomPainter {
  final double progress;
  final Color color;
  
  KnittingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    // Draw knitting pattern
    final totalLines = 20;
    final completedLines = (progress * totalLines).floor();
    
    for (int i = 0; i < completedLines; i++) {
      final angle = (i / totalLines) * 2 * 3.14159;
      final start = Offset(
        center.dx + (radius - 20) * angle.cos(),
        center.dy + (radius - 20) * angle.sin(),
      );
      final end = Offset(
        center.dx + radius * angle.cos(),
        center.dy + radius * angle.sin(),
      );
      
      canvas.drawLine(start, end, paint);
    }
    
    // Draw partial line if animating
    if (completedLines < totalLines) {
      final angle = (completedLines / totalLines) * 2 * 3.14159 * progress;
      final start = Offset(
        center.dx + (radius - 20) * angle.cos(),
        center.dy + (radius - 20) * angle.sin(),
      );
      final end = Offset(
        center.dx + radius * angle.cos(),
        center.dy + radius * angle.sin(),
      );
      
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(KnittingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
