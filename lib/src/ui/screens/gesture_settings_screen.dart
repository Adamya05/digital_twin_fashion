/// Gesture Settings Screen
/// 
/// Allows users to customize swipe gestures, haptic feedback, and accessibility settings.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/gesture_settings.dart';

class GestureSettingsScreen extends ConsumerStatefulWidget {
  const GestureSettingsScreen({super.key});

  @override
  ConsumerState<GestureSettingsScreen> createState() => _GestureSettingsScreenState();
}

class _GestureSettingsScreenState extends ConsumerState<GestureSettingsScreen> {
  late GestureSettings _currentSettings;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Load user's current settings (would come from provider in real app)
    _currentSettings = const GestureSettings();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Gesture Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1B1E),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _resetToDefaults,
            child: const Text(
              'Reset',
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _slideAnimation,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildPresetCards(),
            const SizedBox(height: 30),
            _buildSwipeThresholdSlider(),
            const SizedBox(height: 20),
            _buildVelocityThresholdSlider(),
            const SizedBox(height: 20),
            _buildAnimationSpeedSlider(),
            const SizedBox(height: 30),
            _buildHapticFeedbackSection(),
            const SizedBox(height: 20),
            _buildAudioFeedbackSection(),
            const SizedBox(height: 20),
            _buildVisualFeedbackSection(),
            const SizedBox(height: 30),
            _buildAccessibilitySection(),
            const SizedBox(height: 50),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Presets',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPresetCard(
                'Fast Gestures',
                'Quick swipes for rapid browsing',
                Icons.flash_on,
                Colors.orange,
                GestureSettings.fastGestures(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPresetCard(
                'Precise',
                'Accurate control for careful selection',
                Icons.tune,
                Colors.blue,
                GestureSettings.preciseGestures(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPresetCard(
                'Accessible',
                'Optimized for accessibility needs',
                Icons.accessibility,
                Colors.green,
                GestureSettings.accessibilityFriendly(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    GestureSettings preset,
  ) {
    final isSelected = _currentSettings == preset;
    
    return GestureDetector(
      onTap: () => setState(() => _currentSettings = preset),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : const Color(0xFF1A1B1E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeThresholdSlider() {
    return _buildSliderCard(
      title: 'Swipe Sensitivity',
      subtitle: 'How far you need to swipe to trigger an action',
      child: Column(
        children: [
          Slider(
            value: _currentSettings.swipeThreshold,
            min: GestureSettings.minSwipeThreshold,
            max: GestureSettings.maxSwipeThreshold,
            divisions: 12,
            activeColor: const Color(0xFF6366F1),
            label: '${_currentSettings.swipeThreshold.round()}px',
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(swipeThreshold: value);
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sensitive',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
              Text(
                '${_currentSettings.swipeThreshold.round()}px',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Less Sensitive',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVelocityThresholdSlider() {
    return _buildSliderCard(
      title: 'Swipe Velocity',
      subtitle: 'Speed required for swipe detection',
      child: Column(
        children: [
          Slider(
            value: _currentSettings.swipeVelocityThreshold,
            min: 500.0,
            max: 2000.0,
            divisions: 30,
            activeColor: const Color(0xFF6366F1),
            label: '${(_currentSettings.swipeVelocityThreshold / 1000).toStringAsFixed(1)}k',
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(swipeVelocityThreshold: value);
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Slow',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
              Text(
                '${(_currentSettings.swipeVelocityThreshold / 1000).toStringAsFixed(1)}k',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Fast',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationSpeedSlider() {
    Duration currentDuration = _currentSettings.animationDuration;
    double speedMultiplier = 300 / currentDuration.inMilliseconds; // Normalize to 300ms baseline

    return _buildSliderCard(
      title: 'Animation Speed',
      subtitle: 'How fast card animations play',
      child: Column(
        children: [
          Slider(
            value: speedMultiplier,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            activeColor: const Color(0xFF6366F1),
            label: '${speedMultiplier.toStringAsFixed(1)}x',
            onChanged: (value) {
              final newDuration = Duration(milliseconds: (300 / value).round());
              setState(() {
                _currentSettings = _currentSettings.copyWith(animationDuration: newDuration);
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Slow',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
              Text(
                '${speedMultiplier.toStringAsFixed(1)}x',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Fast',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHapticFeedbackSection() {
    return _buildSectionCard(
      title: 'Haptic Feedback',
      subtitle: 'Vibration feedback for gestures',
      child: Column(
        children: [
          ...HapticFeedbackType.values.map((type) {
            final isSelected = _currentSettings.hapticFeedbackLevel == type;
            return RadioListTile<HapticFeedbackType>(
              title: Text(_getHapticTypeLabel(type)),
              subtitle: Text(_getHapticTypeDescription(type)),
              value: type,
              groupValue: _currentSettings.hapticFeedbackLevel,
              activeColor: const Color(0xFF6366F1),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currentSettings = _currentSettings.copyWith(hapticFeedbackLevel: value);
                  });
                }
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAudioFeedbackSection() {
    return _buildSectionCard(
      title: 'Audio Feedback',
      subtitle: 'Sound effects for gestures',
      child: SwitchListTile(
        title: const Text('Enable Sound Effects'),
        subtitle: Text(
          _currentSettings.soundEffectsEnabled ? 'Sounds are enabled' : 'Sounds are disabled',
        ),
        value: _currentSettings.soundEffectsEnabled,
        activeColor: const Color(0xFF6366F1),
        onChanged: (value) {
          setState(() {
            _currentSettings = _currentSettings.copyWith(soundEffectsEnabled: value);
          });
        },
      ),
    );
  }

  Widget _buildVisualFeedbackSection() {
    return _buildSectionCard(
      title: 'Visual Feedback',
      subtitle: 'Visual cues during gestures',
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Gesture Indicators'),
            subtitle: const Text('Show direction indicators during swipes'),
            value: _currentSettings.visualFeedbackEnabled,
            activeColor: const Color(0xFF6366F1),
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(visualFeedbackEnabled: value);
              });
            },
          ),
          SwitchListTile(
            title: const Text('Gesture Haptics'),
            subtitle: const Text('Haptic feedback during swipe gestures'),
            value: _currentSettings.gestureHapticsEnabled,
            activeColor: const Color(0xFF6366F1),
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(gestureHapticsEnabled: value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilitySection() {
    return _buildSectionCard(
      title: 'Accessibility',
      subtitle: 'Settings for enhanced accessibility',
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Quick Actions'),
            subtitle: const Text('Show large action buttons'),
            value: _currentSettings.quickActionsEnabled,
            activeColor: const Color(0xFF6366F1),
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(quickActionsEnabled: value);
              });
            },
          ),
          SwitchListTile(
            title: const Text('Undo Feature'),
            subtitle: const Text('Allow undoing recent swipes'),
            value: _currentSettings.undoEnabled,
            activeColor: const Color(0xFF6366F1),
            onChanged: (value) {
              setState(() {
                _currentSettings = _currentSettings.copyWith(undoEnabled: value);
              });
            },
          ),
          ListTile(
            title: const Text('Undo Timeout'),
            subtitle: Text('${_currentSettings.undoTimeout.inSeconds} seconds'),
            trailing: SizedBox(
              width: 120,
              child: Slider(
                value: _currentSettings.undoTimeout.inSeconds.toDouble(),
                min: 3.0,
                max: 10.0,
                divisions: 7,
                activeColor: const Color(0xFF6366F1),
                label: '${_currentSettings.undoTimeout.inSeconds}s',
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings.copyWith(
                      undoTimeout: Duration(seconds: value.round()),
                    );
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Save Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getHapticTypeLabel(HapticFeedbackType type) {
    switch (type) {
      case HapticFeedbackType.none:
        return 'None';
      case HapticFeedbackType.light:
        return 'Light';
      case HapticFeedbackType.medium:
        return 'Medium';
      case HapticFeedbackType.heavy:
        return 'Heavy';
    }
  }

  String _getHapticTypeDescription(HapticFeedbackType type) {
    switch (type) {
      case HapticFeedbackType.none:
        return 'No vibration feedback';
      case HapticFeedbackType.light:
        return 'Subtle vibration';
      case HapticFeedbackType.medium:
        return 'Moderate vibration';
      case HapticFeedbackType.heavy:
        return 'Strong vibration';
    }
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('Are you sure you want to reset all gesture settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _currentSettings = const GestureSettings();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    // In a real app, this would save to SharedPreferences or a backend
    _animationController.forward().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gesture settings saved!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    });
  }
}