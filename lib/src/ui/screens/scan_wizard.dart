/// Scan Wizard Screen
/// 
/// Multi-step wizard that guides users through the avatar creation process.
/// Handles camera permissions, video capture, and avatar scanning workflow.
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import '../../services/scan_service.dart';
import '../../services/video_processing_service.dart';
import '../../widgets/camera_overlay_widget.dart';
import 'processing_screen.dart';

class ScanWizard extends StatefulWidget {
  const ScanWizard({super.key});

  @override
  State<ScanWizard> createState() => _ScanWizardState();
}

enum WizardStep {
  permissions,
  camera,
  countdown,
  recording,
  preview,
  uploading,
  complete,
}

class _ScanWizardState extends State<ScanWizard>
    with TickerProviderStateMixin {
  WizardStep _currentStep = WizardStep.permissions;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Camera variables
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isFrontCamera = true;
  
  // Recording variables
  bool _isRecording = false;
  String? _recordedVideoPath;
  double _recordingProgress = 0.0;
  late AnimationController _recordingController;
  
  // Countdown variables
  bool _showCountdown = false;
  int _countdownValue = 3;
  late AnimationController _countdownController;
  
  // Upload variables
  double _uploadProgress = 0.0;
  bool _uploadSuccess = false;
  String? _sessionId;
  
  final ScanService _scanService = ScanService();
  final VideoProcessingService _videoService = VideoProcessingService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCamera();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    
    _recordingController = AnimationController(
      duration: const Duration(seconds: 10), // Max recording time
      vsync: this,
    );
    _recordingController.addListener(() {
      if (mounted) {
        setState(() {
          _recordingProgress = _recordingController.value;
        });
      }
    });
    
    _countdownController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
  }

  Future<void> _initializeCamera() async {
    try {
      // Check permissions first
      final status = await _checkCameraPermission();
      if (!status) {
        if (mounted) {
          setState(() {
            _currentStep = WizardStep.permissions;
          });
        }
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showError('No cameras found on this device');
        return;
      }

      // Initialize front camera
      await _initializeCameraController(_isFrontCamera);
      
      if (mounted) {
        setState(() {
          _currentStep = WizardStep.camera;
        });
      }
    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  Future<void> _initializeCameraController(bool useFrontCamera) async {
    try {
      // Dispose previous controller
      await _controller?.dispose();
      
      final cameraIndex = useFrontCamera ? _getFrontCameraIndex() : _getBackCameraIndex();
      if (cameraIndex == -1) {
        _showError('Camera not available');
        return;
      }

      _controller = CameraController(
        _cameras[cameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      _showError('Failed to initialize camera controller: $e');
    }
  }

  int _getFrontCameraIndex() {
    for (int i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == CameraLensDirection.front) {
        return i;
      }
    }
    return 0;
  }

  int _getBackCameraIndex() {
    for (int i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == CameraLensDirection.back) {
        return i;
      }
    }
    return 1; // Fallback to first camera if no back camera found
  }

  Future<bool> _checkCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _startCountdown() async {
    if (_currentStep != WizardStep.camera) return;
    
    setState(() {
      _currentStep = WizardStep.countdown;
      _showCountdown = true;
      _countdownValue = 3;
    });

    for (int i = 3; i > 0; i--) {
      if (!mounted) return;
      setState(() {
        _countdownValue = i;
      });
      await Future.delayed(const Duration(seconds: 1));
    }

    await _startRecording();
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      _showError('Camera not ready');
      return;
    }

    try {
      setState(() {
        _currentStep = WizardStep.recording;
        _isRecording = true;
        _recordingProgress = 0.0;
      });

      // Start recording
      await _controller!.startVideoRecording();
      _recordingController.reset();
      _recordingController.forward();

    } catch (e) {
      _showError('Failed to start recording: $e');
      setState(() {
        _isRecording = false;
        _currentStep = WizardStep.camera;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _controller == null) return;

    try {
      setState(() {
        _isRecording = false;
      });

      _recordingController.stop();
      final video = await _controller!.stopVideoRecording();
      
      if (mounted) {
        setState(() {
          _recordedVideoPath = video.path;
          _currentStep = WizardStep.preview;
        });
      }
    } catch (e) {
      _showError('Failed to stop recording: $e');
      if (mounted) {
        setState(() {
          _currentStep = WizardStep.camera;
        });
      }
    }
  }

  Future<void> _uploadVideo() async {
    if (_recordedVideoPath == null) return;

    try {
      setState(() {
        _currentStep = WizardStep.uploading;
        _uploadProgress = 0.0;
      });

      // Start a new scan session
      final sessionResult = await _scanService.startScan('user123'); // Replace with actual user ID
      if (!sessionResult.isSuccess || sessionResult.data == null) {
        throw Exception(sessionResult.error ?? 'Failed to create scan session');
      }

      _sessionId = sessionResult.data!;

      // Upload video to server
      final videoFile = File(_recordedVideoPath!);
      final uploadResult = await _scanService.uploadScanVideo(_sessionId!, videoFile);

      if (!uploadResult.isSuccess) {
        throw Exception(uploadResult.error ?? 'Upload failed');
      }

      // Update progress to complete
      if (!mounted) return;
      setState(() {
        _uploadProgress = 1.0;
        _uploadSuccess = true;
      });

      await Future.delayed(const Duration(milliseconds: 500)); // Brief pause for UX

      if (mounted) {
        // Generate a session ID and navigate to processing screen
        _sessionId = 'scan_${DateTime.now().millisecondsSinceEpoch}';
        setState(() {
          _currentStep = WizardStep.complete;
        });
      }

      _showSuccess('Video uploaded successfully! Avatar generation started.');
      
      // Extract frames from video for local processing
      await _extractFramesFromVideo(_recordedVideoPath!);
      
      // Navigate to processing screen
      if (mounted && _sessionId != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ProcessingScreen(scanId: _sessionId!),
          ),
        );
      }
      
    } catch (e) {
      _showError('Upload failed: $e');
      if (mounted) {
        setState(() {
          _currentStep = WizardStep.preview;
        });
      }
    }
  }

  Future<void> _extractFramesFromVideo(String videoPath) async {
    try {
      print('Starting frame extraction from video: $videoPath');
      
      // Create frames directory
      final framesDir = await _videoService.createFramesDirectory();
      print('Created frames directory: $framesDir');
      
      // Extract frames at 2 fps (every 0.5 seconds)
      final framePaths = await _videoService.extractFramesFromVideo(
        videoPath,
        framesDir,
        fps: 2,
      );
      
      print('Extracted ${framePaths.length} frames to: $framesDir');
      
      // Create thumbnail for preview
      final thumbnailPath = '$framesDir/thumbnail.jpg';
      await _videoService.createVideoThumbnail(videoPath, thumbnailPath);
      
      // You can now upload frames separately if needed
      // or use them for local processing
      
    } catch (e) {
      print('Error extracting frames: $e');
      // Don't show error to user as this is background processing
    }
  }

  void _resetWizard() {
    _controller?.dispose();
    _recordingController.dispose();
    _countdownController.dispose();
    _pulseController.dispose();
    
    setState(() {
      _currentStep = WizardStep.permissions;
      _isCameraInitialized = false;
      _isRecording = false;
      _recordedVideoPath = null;
      _recordingProgress = 0.0;
      _uploadProgress = 0.0;
      _uploadSuccess = false;
      _showCountdown = false;
    });
    
    _initializeAnimations();
    _initializeCamera();
  }

  void _switchCamera() async {
    if (!_isCameraInitialized) return;
    
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
    
    await _initializeCameraController(_isFrontCamera);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _recordingController.dispose();
    _countdownController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Avatar'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentStep) {
      case WizardStep.permissions:
        return _buildPermissionsStep();
      case WizardStep.camera:
        return _buildCameraStep();
      case WizardStep.countdown:
        return _buildCountdownStep();
      case WizardStep.recording:
        return _buildRecordingStep();
      case WizardStep.preview:
        return _buildPreviewStep();
      case WizardStep.uploading:
        return _buildUploadingStep();
      case WizardStep.complete:
        return _buildCompleteStep();
    }
  }

  Widget _buildPermissionsStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 32),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'We need access to your camera to create a 3D avatar from your scan.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final granted = await _checkCameraPermission();
                if (granted) {
                  _initializeCamera();
                } else {
                  _showError('Camera permission is required to continue');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraStep() {
    if (!_isCameraInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      children: [
        // Camera Preview
        Positioned.fill(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),
        ),
        
        // Overlay Guide
        Positioned.fill(
          child: CameraOverlayWidget(
            isVisible: true,
            animation: _pulseAnimation,
          ),
        ),
        
        // Camera Controls
        Positioned(
          top: 50,
          right: 20,
          child: FloatingActionButton(
            onPressed: _switchCamera,
            backgroundColor: Colors.black54,
            child: const Icon(Icons.flip_camera_ios, color: Colors.white),
          ),
        ),
        
        // Start Recording Button
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: _startCountdown,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Start Scan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        
        // Instructions
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Text(
            'Position yourself within the circle and foot markers. Tap "Start Scan" when ready.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownStep() {
    return Container(
      color: Colors.black,
      child: Center(
        child: AnimatedBuilder(
          animation: _countdownController,
          builder: (context, child) {
            return Text(
              '$_countdownValue',
              style: const TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecordingStep() {
    return Stack(
      children: [
        // Camera Preview
        Positioned.fill(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),
        ),
        
        // Recording Overlay
        Positioned.fill(
          child: Container(
            color: Colors.black54,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.circle,
                  color: Colors.red,
                  size: 80,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Recording...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 200,
                  height: 4,
                  child: LinearProgressIndicator(
                    value: _recordingProgress,
                    backgroundColor: Colors.grey,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${(_recordingProgress * 10).toInt()} seconds',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Stop Recording Button
        Positioned(
          bottom: 50,
          left: 20,
          right: 20,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: _stopRecording,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Recording'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Recording Complete!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_circle_outline,
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Video Preview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = WizardStep.camera;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Retake'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _uploadVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Upload'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.blue,
              strokeWidth: 6,
            ),
            const SizedBox(height: 32),
            const Text(
              'Uploading Video...',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${(_uploadProgress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 300,
              height: 6,
              child: LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Please wait while we process your scan and create your avatar.',
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

  Widget _buildCompleteStep() {
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
              'Upload Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your avatar is being generated. This may take a few minutes.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Navigate to processing screen
                if (_sessionId != null) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => ProcessingScreen(scanId: _sessionId!),
                    ),
                  );
                } else {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Check Status'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resetWizard,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
              child: const Text('Scan Another Person'),
            ),
          ],
        ),
      ),
    );
  }
}
