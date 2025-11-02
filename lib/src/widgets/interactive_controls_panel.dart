/// Interactive Controls Panel
/// 
/// Comprehensive control panel for avatar manipulation including:
/// - Rotation controls (360° rotation, auto-rotate toggle)
/// - Height slider (150cm - 200cm range)
/// - Body shape adjustments (chest, waist, hip percentages)
/// - Lighting presets and custom lighting
/// - Body type presets (Slim, Regular, Athletic)
/// - Pose presets for try-on scenarios
/// - Real-time parameter updates with smooth animations
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../models/interactive_avatar_model.dart';
import '../models/pose_preset_model.dart';
import '../providers/interactive_avatar_provider.dart';

/// Main interactive controls panel widget
class InteractiveControlsPanel extends ConsumerStatefulWidget {
  final double panelHeight;
  final bool showTutorial;
  final VoidCallback? onClose;

  const InteractiveControlsPanel({
    super.key,
    this.panelHeight = 400,
    this.showTutorial = false,
    this.onClose,
  });

  @override
  ConsumerState<InteractiveControlsPanel> createState() => _InteractiveControlsPanelState();
}

class _InteractiveControlsPanelState extends ConsumerState<InteractiveControlsPanel>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = ref.read(interactiveAvatarProvider.notifier);
    final avatarState = ref.watch(interactiveAvatarProvider);
    
    if (avatarState.currentAvatar == null) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Container(
        height: widget.panelHeight,
        width: 320,
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.95),
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPoseControls(avatarProvider),
                  const SizedBox(height: 20),
                  _buildRotationControls(avatarState),
                  const SizedBox(height: 20),
                  _buildHeightControl(avatarState),
                  const SizedBox(height: 20),
                  _buildBodyShapeControls(avatarState),
                  const SizedBox(height: 20),
                  _buildBodyPresets(avatarProvider),
                  const SizedBox(height: 20),
                  _buildLightingControls(avatarProvider),
                  const SizedBox(height: 20),
                  _buildActionButtons(avatarProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.tune,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Avatar Controls',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            icon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.white,
            ),
          ),
          if (widget.onClose != null)
            IconButton(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildPoseControls(InteractiveAvatarProvider provider) {
    return _ControlSection(
      title: 'Pose Presets',
      icon: Icons.accessibility,
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: PosePreset.values.map((preset) {
              final isSelected = _isPoseSelected(preset);
              return _PosePresetButton(
                onPressed: () => _applyPosePreset(preset, provider),
                icon: preset.icon,
                label: preset.displayName,
                isSelected: isSelected,
                description: preset.description,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Quick pose switching
          Row(
            children: [
              Expanded(
                child: _ControlButton(
                  onPressed: () => _applyPosePreset(PosePreset.frontView, provider),
                  icon: Icons.person,
                  label: 'Front',
                  color: _isPoseSelected(PosePreset.frontView) ? Colors.blue : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ControlButton(
                  onPressed: () => _applyPosePreset(PosePreset.sideView, provider),
                  icon: Icons.person_outline,
                  label: 'Side',
                  color: _isPoseSelected(PosePreset.sideView) ? Colors.blue : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ControlButton(
                  onPressed: () => _applyPosePreset(PosePreset.threeQuarterView, provider),
                  icon: Icons.rotate_right,
                  label: '3/4',
                  color: _isPoseSelected(PosePreset.threeQuarterView) ? Colors.blue : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isPoseSelected(PosePreset preset) {
    // This would be tracked in provider state in a real implementation
    return false;
  }

  void _applyPosePreset(PosePreset preset, InteractiveAvatarProvider provider) {
    provider.rotateTo(preset.rotationY);
    // In a real implementation, this would also apply recommended lighting
    // and body position adjustments
  }

  Widget _buildRotationControls(InteractiveAvatarProvider provider) {
    final avatar = provider.currentAvatar!;
    final controls = avatar.controls;

    return _ControlSection(
      title: 'Rotation',
      icon: Icons.rotate_90_degrees_ccw,
      child: Column(
        children: [
          Row(
            children: [
              _RotationButton(
                icon: Icons.rotate_left,
                onPressed: () => provider.rotateTo(
                  (controls.rotationY - 30) % 360,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${controls.rotationY.round()}°',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _RotationButton(
                icon: Icons.rotate_right,
                onPressed: () => provider.rotateTo(
                  (controls.rotationY + 30) % 360,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ControlButton(
                  onPressed: () => provider.rotateTo(0),
                  icon: Icons.front_hand,
                  label: 'Front',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ControlButton(
                  onPressed: () => provider.rotateTo(180),
                  icon: Icons.back_hand,
                  label: 'Back',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: controls.autoRotate,
            onChanged: (value) => provider.toggleAutoRotate(enabled: value),
            title: const Text(
              'Auto Rotate',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            secondary: const Icon(Icons.autorenew, color: Colors.blue),
            activeColor: Colors.blue,
            dense: true,
          ),
          if (controls.autoRotate) ...[
            const SizedBox(height: 8),
            Text(
              'Speed: ${controls.autoRotateSpeed.toStringAsFixed(1)}°/s',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
            Slider(
              value: controls.autoRotateSpeed,
              onChanged: (value) => provider.toggleAutoRotate(speed: value),
              min: 0.5,
              max: 5.0,
              activeColor: Colors.blue,
              inactiveColor: Colors.grey.shade600,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeightControl(InteractiveAvatarProvider provider) {
    final avatar = provider.currentAvatar!;
    final controls = avatar.controls;

    return _ControlSection(
      title: 'Height',
      icon: Icons.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${controls.height.round()} cm',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.blue,
              inactiveTrackColor: Colors.grey.shade600,
              thumbColor: Colors.blue,
              overlayColor: Colors.blue.withOpacity(0.3),
              thumbShape: const RoundSliderThumbShape(enabledRadius: 8),
            ),
            child: Slider(
              value: controls.height,
              onChanged: (value) => provider.updateHeight(value),
              min: 150.0,
              max: 200.0,
              divisions: 50,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '150cm',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
              Text(
                '200cm',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyShapeControls(InteractiveAvatarProvider provider) {
    final avatar = provider.currentAvatar!;
    final controls = avatar.controls;

    return _ControlSection(
      title: 'Body Shape',
      icon: Icons.accessibility,
      child: Column(
        children: [
          _BodyShapeSlider(
            label: 'Chest',
            value: controls.chestSize,
            onChanged: (value) => provider.updateBodyShape(chest: value),
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 12),
          _BodyShapeSlider(
            label: 'Waist',
            value: controls.waistSize,
            onChanged: (value) => provider.updateBodyShape(waist: value),
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 12),
          _BodyShapeSlider(
            label: 'Hips',
            value: controls.hipSize,
            onChanged: (value) => provider.updateBodyShape(hip: value),
            color: Colors.blue.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildBodyPresets(InteractiveAvatarProvider provider) {
    return _ControlSection(
      title: 'Quick Presets',
      icon: Icons.preset,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _PresetButton(
                  onPressed: () => provider.applyBodyPreset(BodyPreset.slim),
                  label: 'Slim',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PresetButton(
                  onPressed: () => provider.applyBodyPreset(BodyPreset.regular),
                  label: 'Regular',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PresetButton(
                  onPressed: () => provider.applyBodyPreset(BodyPreset.athletic),
                  label: 'Athletic',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLightingControls(InteractiveAvatarProvider provider) {
    final avatar = provider.currentAvatar!;
    final controls = avatar.controls;

    return _ControlSection(
      title: 'Lighting Presets',
      icon: Icons.lightbulb,
      child: Column(
        children: [
          // Main lighting presets
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LightingPreset.values.map((preset) {
              final isSelected = controls.lightingPreset == preset;
              return _LightingPresetChip(
                label: preset.displayName,
                isSelected: isSelected,
                intensity: preset.intensity,
                onSelected: () => provider.applyLighting(preset),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Custom lighting controls
          _buildCustomLightingControls(provider),
          
          const SizedBox(height: 16),
          
          // Lighting comparison mode
          _buildLightingComparisonControls(),
        ],
      ),
    );
  }

  Widget _buildCustomLightingControls(InteractiveAvatarProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.tune, color: Colors.purple, size: 16),
            const SizedBox(width: 8),
            const Text(
              'Custom Lighting',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ControlButton(
                onPressed: () => _openCustomLightingDialog(provider),
                icon: Icons.tune,
                label: 'Adjust',
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ControlButton(
                onPressed: () => _resetLighting(provider),
                icon: Icons.refresh,
                label: 'Reset',
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLightingComparisonControls() {
    return Row(
      children: [
        Expanded(
          child: _ControlButton(
            onPressed: _toggleLightingComparison,
            icon: Icons.compare,
            label: 'Compare',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ControlButton(
            onPressed: _cycleLightingPresets,
            icon: Icons.autorenew,
            label: 'Cycle',
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  void _openCustomLightingDialog(InteractiveAvatarProvider provider) {
    // This would open a dialog with custom lighting controls
    // Implementation similar to the TryOnViewer
  }

  void _resetLighting(InteractiveAvatarProvider provider) {
    provider.applyLighting(LightingPreset.studio);
  }

  void _toggleLightingComparison() {
    // Toggle lighting comparison mode
  }

  void _cycleLightingPresets() {
    // Cycle through lighting presets
  }

  Widget _buildActionButtons(InteractiveAvatarProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ControlButton(
                onPressed: provider.canUndo ? () => provider.undo() : null,
                icon: Icons.undo,
                label: 'Undo',
                enabled: provider.canUndo,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ControlButton(
                onPressed: provider.reset,
                icon: Icons.refresh,
                label: 'Reset',
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => provider.toggleComparison(),
            icon: Icon(
              provider.showComparison ? Icons.compare : Icons.compare_arrows,
            ),
            label: Text(
              provider.showComparison ? 'Exit Comparison' : 'Compare View',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Control section wrapper widget
class _ControlSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ControlSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.blue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Rotation button widget
class _RotationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const _RotationButton({
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.grey.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(36, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Icon(icon, size: 16),
    );
  }
}

/// Control button widget
class _ControlButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color? color;
  final bool enabled;

  const _ControlButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.color,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled 
            ? (color ?? Colors.grey.shade700) 
            : Colors.grey.shade800,
        foregroundColor: enabled ? Colors.white : Colors.grey.shade500,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Body shape slider widget
class _BodyShapeSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final Color color;

  const _BodyShapeSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${value.round()}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: Colors.grey.shade600,
            thumbColor: color,
            overlayColor: color.withOpacity(0.3),
            thumbShape: const RoundSliderThumbShape(enabledRadius: 6),
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
            min: 90.0,
            max: 110.0,
            divisions: 20,
          ),
        ),
      ],
    );
  }
}

/// Preset button widget
class _PresetButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final Color color;

  const _PresetButton({
    required this.onPressed,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}

/// Pose preset button widget
class _PosePresetButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isSelected;
  final String description;

  const _PosePresetButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Lighting preset chip widget
class _LightingPresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final double intensity;
  final VoidCallback onSelected;

  const _LightingPresetChip({
    required this.label,
    required this.isSelected,
    required this.intensity,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lightbulb,
            size: 14,
            color: isSelected ? Colors.white : Colors.grey.shade400,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade400,
              fontSize: 11,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.grey.shade800,
      selectedColor: _getIntensityColor(intensity),
      side: BorderSide(
        color: isSelected ? _getIntensityColor(intensity) : Colors.grey.shade600,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Color _getIntensityColor(double intensity) {
    if (intensity >= 1.5) return Colors.yellow.shade600;
    if (intensity >= 1.0) return Colors.orange;
    return Colors.blue;
  }
}