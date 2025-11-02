/// Tutorial Overlay Widget
/// 
/// Interactive tutorial system for teaching users how to use
/// the avatar controls. Features step-by-step guidance with
/// highlighted UI elements and interactive demonstrations.
import 'package:flutter/material.dart';
import 'dart:math' as math;

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final Color? backgroundColor;

  const TutorialOverlay({
    super.key,
    required this.steps,
    this.onComplete,
    this.onSkip,
    this.backgroundColor,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  int _currentStep = 0;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _completeTutorial();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _completeTutorial() {
    _animationController.reverse().then((_) {
      setState(() {
        _isVisible = false;
      });
      widget.onComplete?.call();
    });
  }

  void _skipTutorial() {
    _animationController.reverse().then((_) {
      setState(() {
        _isVisible = false;
      });
      widget.onSkip?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || widget.steps.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentStep = widget.steps[_currentStep];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // Dark overlay background
          Positioned.fill(
            child: Container(
              color: (widget.backgroundColor ?? Colors.black).withOpacity(0.7),
            ),
          ),
          
          // Highlighted area for target element
          if (currentStep.targetRect != null)
            _buildHighlightArea(currentStep),
          
          // Tutorial content
          _buildTutorialContent(currentStep),
        ],
      ),
    );
  }

  Widget _buildHighlightArea(TutorialStep step) {
    final rect = step.targetRect!;
    
    return Positioned(
      left: rect.left - 20,
      top: rect.top - 20,
      width: rect.width + 40,
      height: rect.height + 40,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.blue,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.blue.withOpacity(0.1),
        ),
        child: Stack(
          children: [
            // Pulsing animation effect
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 + (_animationController.value * 0.1),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialContent(TutorialStep step) {
    final screenSize = MediaQuery.of(context).size;
    
    return Positioned(
      left: 20,
      right: 20,
      bottom: 20,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    step.icon ?? Icons.lightbulb,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Progress indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentStep + 1}/${widget.steps.length}',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Content
              Text(
                step.description,
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade400,
                          side: BorderSide(color: Colors.grey.shade600),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Previous'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _currentStep == widget.steps.length - 1 
                            ? 'Get Started!' 
                            : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Skip button
              Center(
                child: TextButton(
                  onPressed: _skipTutorial,
                  child: Text(
                    'Skip Tutorial',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tutorial step definition
class TutorialStep {
  final String title;
  final String description;
  final IconData? icon;
  final Rect? targetRect;
  final VoidCallback? onShown;
  final List<String>? highlights;

  const TutorialStep({
    required this.title,
    required this.description,
    this.icon,
    this.targetRect,
    this.onShown,
    this.highlights,
  });

  TutorialStep copyWith({
    String? title,
    String? description,
    IconData? icon,
    Rect? targetRect,
    VoidCallback? onShown,
    List<String>? highlights,
  }) {
    return TutorialStep(
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      targetRect: targetRect ?? this.targetRect,
      onShown: onShown ?? this.onShown,
      highlights: highlights ?? this.highlights,
    );
  }
}

/// Tutorial system manager
class TutorialManager {
  static List<TutorialStep> getAvatarControlTutorial() {
    return [
      const TutorialStep(
        title: 'Welcome to Avatar Controls!',
        description: 'Learn how to customize your avatar with these powerful interactive controls. You can adjust height, body shape, rotation, and lighting in real-time.',
        icon: Icons.person,
      ),
      const TutorialStep(
        title: 'Rotation Controls',
        description: 'Use the rotation buttons to view your avatar from any angle. You can rotate 360° or enable auto-rotation for hands-free viewing.',
        icon: Icons.rotate_90_degrees_ccw,
      ),
      const TutorialStep(
        title: 'Height Adjustment',
        description: 'Drag the height slider to adjust your avatar\'s height from 150cm to 200cm. Changes apply instantly with smooth scaling.',
        icon: Icons.height,
      ),
      const TutorialStep(
        title: 'Body Shape Controls',
        description: 'Fine-tune chest, waist, and hip measurements using the percentage sliders. Range is 90% to 110% for subtle adjustments.',
        icon: Icons.accessibility,
      ),
      const TutorialStep(
        title: 'Quick Presets',
        description: 'Use body type presets for instant changes: Slim, Regular, or Athletic. These provide balanced proportions for different body types.',
        icon: Icons.tune,
      ),
      const TutorialStep(
        title: 'Lighting Options',
        description: 'Choose from different lighting presets to optimize avatar viewing: Studio for bright, even light, or Day for natural outdoor lighting.',
        icon: Icons.lightbulb,
      ),
      const TutorialStep(
        title: 'Comparison Mode',
        description: 'Toggle comparison mode to see before and after views of your adjustments. Perfect for tracking your changes.',
        icon: Icons.compare,
      ),
      const TutorialStep(
        title: 'Ready to Start!',
        description: 'You\'re all set! Remember: all changes are saved automatically, and you can undo/redo anytime. Start customizing your avatar now!',
        icon: Icons.check_circle,
      ),
    ];
  }

  /// Show tutorial overlay with automatic step highlighting
  static Future<void> showTutorial(
    BuildContext context, {
    List<TutorialStep>? steps,
    VoidCallback? onComplete,
    VoidCallback? onSkip,
  }) async {
    final tutorialSteps = steps ?? getAvatarControlTutorial();
    
    // Find target elements and calculate their positions
    await Future.delayed(const Duration(milliseconds: 100)); // Allow UI to settle
    
    // Note: In a real implementation, you would find specific widgets and calculate their rects
    // For now, we'll show a simplified tutorial without targeting specific elements
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TutorialOverlay(
        steps: tutorialSteps,
        onComplete: onComplete,
        onSkip: onSkip,
      ),
    );
  }

  /// Create tutorial step with automatic element targeting
  static TutorialStep withTarget({
    required String title,
    required String description,
    required GlobalKey targetKey,
    IconData? icon,
  }) {
    // This would be implemented to find the widget by key and get its rect
    // For now, returning a step without target
    return TutorialStep(
      title: title,
      description: description,
      icon: icon,
    );
  }
}