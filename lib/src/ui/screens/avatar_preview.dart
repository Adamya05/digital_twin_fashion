/// Avatar Preview Screen
/// 
/// Comprehensive 3D avatar preview with interactive controls for real-time adjustments.
/// Features full-screen 3D canvas, body shape controls, lighting presets, and zoom functionality.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../providers/avatar_provider.dart';
import '../../models/avatar_model.dart';
import '../../widgets/canvas_container.dart';
import '../../widgets/app_button.dart';

class AvatarPreview extends ConsumerStatefulWidget {
  final String avatarId;
  final bool showControls;
  
  const AvatarPreview({
    super.key,
    required this.avatarId,
    this.showControls = true,
  });

  @override
  ConsumerState<AvatarPreview> createState() => _AvatarPreviewState();
}

class _AvatarPreviewState extends ConsumerState<AvatarPreview>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _showControls = false;
  bool _isCapturingSnapshot = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAvatar();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _scaleController.forward();
  }

  Future<void> _loadAvatar() async {
    await ref.read(avatarProvider.notifier).loadAvatar(widget.avatarId);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarAsync = ref.watch(avatarProvider);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Avatar Preview'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showAvatarInfo,
          ),
          IconButton(
            icon: AnimatedRotation(
              turns: _showControls ? 0.125 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.tune),
            ),
            onPressed: () => setState(() => _showControls = !_showControls),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: avatarAsync.when(
                data: (avatar) => _buildAvatarView(avatar),
                loading: () => _buildLoadingView(),
                error: (error, stack) => _buildErrorView(error),
              ),
            ),
            if (widget.showControls) _buildControlsPanel(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.blue,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your 3D avatar...',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Downloading GLB model and textures',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load avatar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _retryLoad,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade400,
                    side: BorderSide(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarView(Avatar avatar) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            child: CanvasContainer(
              borderRadius: 24,
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.3),
              backgroundColor: Colors.grey.shade900,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    _buildModelViewer(avatar),
                    if (avatar.state == AvatarState.adjusting)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Updating...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: FloatingActionButton.small(
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/swipe-feed'),
                        backgroundColor: const Color(0xFF6366F1),
                        child: const Icon(
                          Icons.swipe,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton.small(
                        onPressed: _toggleAutoRotate,
                        backgroundColor: Colors.black.withOpacity(0.7),
                        child: const Icon(
                          Icons.rotate_90_degrees_ccw,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModelViewer(Avatar avatar) {
    return ModelViewer(
      src: avatar.modelUrl.isNotEmpty ? avatar.modelUrl : _getFallbackModelUrl(),
      alt: "Your Digital Twin - ${avatar.name}",
      ar: true,
      autoRotate: false, // We control rotation manually
      cameraControls: true,
      interactionPrompt: InteractionPrompt.automatic,
      poster: null,
      reveal: "auto",
      shadowIntensity: 1,
      exposure: 1,
      environmentImage: avatar.lighting.environmentImage,
      skyboxImage: avatar.lighting.skyboxImage,
      loading: Loading.eager,
      scale: "${avatar.heightScale} 1 ${avatar.heightScale}",
      style: _getModelViewerStyle(),
      onLoad: () => debugPrint('Model loaded successfully'),
      onError: (event) => debugPrint('Model loading error: $event'),
    );
  }

  String _getFallbackModelUrl() {
    return 'https://modelviewer.dev/shared-assets/models/Astronaut.glb';
  }

  String _getModelViewerStyle() {
    return """
      model-viewer {
        width: 100%;
        height: 100%;
        background-color: transparent;
        border-radius: 24px;
      }
      model-viewer::part(load-button) {
        border-radius: 24px;
      }
    """;
  }

  Widget _buildControlsPanel() {
    final adjustments = ref.watch(avatarAdjustmentsProvider);
    final avatar = ref.read(avatarProvider).value;
    
    if (avatar == null || !_showControls) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showControls ? null : 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          color: Colors.grey.shade900.withOpacity(0.95),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.tune,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Avatar Controls',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _resetToDefaults,
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          color: Colors.blue.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Height Control
                _buildSliderControl(
                  label: 'Height',
                  value: adjustments.heightAdjust,
                  min: -1.0,
                  max: 1.0,
                  divisions: 20,
                  onChanged: (value) => _updateHeightAdjust(value),
                  formatValue: (value) => '${(value * 20).round()}%',
                ),
                
                const SizedBox(height: 16),
                
                // Body Shape Controls
                const Text(
                  'Body Shape',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                
                _buildSliderControl(
                  label: 'Chest',
                  value: (adjustments.chestSize - 1.0) * 5, // Convert to percentage
                  min: -5,
                  max: 5,
                  divisions: 20,
                  onChanged: (value) => _updateBodyShape('chest', value),
                  formatValue: (value) => '${value.round()}%',
                ),
                
                _buildSliderControl(
                  label: 'Waist',
                  value: (adjustments.waistSize - 1.0) * 5,
                  min: -5,
                  max: 5,
                  divisions: 20,
                  onChanged: (value) => _updateBodyShape('waist', value),
                  formatValue: (value) => '${value.round()}%',
                ),
                
                _buildSliderControl(
                  label: 'Hips',
                  value: (adjustments.hipSize - 1.0) * 5,
                  min: -5,
                  max: 5,
                  divisions: 20,
                  onChanged: (value) => _updateBodyShape('hips', value),
                  formatValue: (value) => '${value.round()}%',
                ),
                
                const SizedBox(height: 16),
                
                // Lighting Control
                const Text(
                  'Lighting',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _buildLightingControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderControl({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String Function(double) formatValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            Text(
              formatValue(value),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.blue.shade400,
            inactiveTrackColor: Colors.grey.shade700,
            thumbColor: Colors.blue.shade400,
            overlayColor: Colors.blue.shade400.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            trackHeight: 2,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildLightingControls() {
    final adjustments = ref.watch(avatarAdjustmentsProvider);
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: LightingPreset.values.map((preset) {
        final isSelected = adjustments.lighting == preset;
        return FilterChip(
          selected: isSelected,
          label: Text(
            preset.label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.grey.shade400,
            ),
          ),
          onSelected: (_) => _updateLighting(preset),
          backgroundColor: Colors.grey.shade800,
          selectedColor: Colors.blue.shade600,
          checkmarkColor: Colors.white,
          showCheckmark: true,
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Primary action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _rescanAvatar,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Re-scan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade400,
                    side: BorderSide(color: Colors.grey.shade600),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _captureSnapshot,
                  icon: _isCapturingSnapshot
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Save Avatar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Interactive controls button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openInteractiveControls,
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Advanced Interactive Controls'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Unlock 360° rotation, height adjustment, body presets, and more!',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Control callback methods
  
  void _retryLoad() async {
    await _loadAvatar();
  }

  void _toggleAutoRotate() {
    // Toggle auto-rotation functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Auto-rotation toggled'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _updateHeightAdjust(double value) {
    ref.read(avatarAdjustmentsProvider.notifier).state = 
        ref.read(avatarAdjustmentsProvider.notifier).state.copyWith(
              heightAdjust: value,
            );
    _applyAvatarAdjustments();
  }

  void _updateBodyShape(String bodyPart, double percentageValue) {
    final adjustedValue = 1.0 + (percentageValue / 100.0); // Convert percentage to scale
    
    final currentAdjustments = ref.read(avatarAdjustmentsProvider.notifier).state;
    
    switch (bodyPart) {
      case 'chest':
        ref.read(avatarAdjustmentsProvider.notifier).state = 
            currentAdjustments.copyWith(chestSize: adjustedValue);
        break;
      case 'waist':
        ref.read(avatarAdjustmentsProvider.notifier).state = 
            currentAdjustments.copyWith(waistSize: adjustedValue);
        break;
      case 'hips':
        ref.read(avatarAdjustmentsProvider.notifier).state = 
            currentAdjustments.copyWith(hipSize: adjustedValue);
        break;
    }
    
    _applyAvatarAdjustments();
  }

  void _updateLighting(LightingPreset preset) {
    ref.read(avatarAdjustmentsProvider.notifier).state = 
        ref.read(avatarAdjustmentsProvider.notifier).state.copyWith(
              lighting: preset,
            );
    _applyAvatarAdjustments();
  }

  void _resetToDefaults() {
    ref.read(avatarAdjustmentsProvider.notifier).state = const AvatarAdjustments();
    _applyAvatarAdjustments();
  }

  Future<void> _applyAvatarAdjustments() async {
    final adjustments = ref.read(avatarAdjustmentsProvider.notifier).state;
    final avatar = ref.read(avatarProvider).value;
    
    if (avatar == null) return;

    // Update avatar with new adjustments
    await ref.read(avatarProvider.notifier).updateAvatarAdjustments(
      heightAdjust: adjustments.heightAdjust,
      chestSize: adjustments.chestSize,
      waistSize: adjustments.waistSize,
      hipSize: adjustments.hipSize,
      lighting: adjustments.lighting,
    );
  }

  void _rescanAvatar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Re-scan Avatar',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will start a new 3D scan process. Your current avatar will be replaced. Continue?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() => _showControls = false);
              await ref.read(avatarProvider.notifier).rescanAvatar();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Re-scan'),
          ),
        ],
      ),
    );
  }

  Future<void> _captureSnapshot() async {
    setState(() => _isCapturingSnapshot = true);
    
    try {
      final snapshotUrl = await ref.read(avatarProvider.notifier).captureSnapshot();
      
      if (snapshotUrl != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar snapshot saved!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        await ref.read(avatarProvider.notifier).saveAvatar();
      } else {
        throw Exception('Failed to capture snapshot');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save avatar: $error'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isCapturingSnapshot = false);
    }
  }

  void _openInteractiveControls() {
    Navigator.of(context).pushNamed(
      '/interactive-avatar',
      arguments: {
        'avatarId': widget.scanId ?? 'demo_avatar',
        'showTutorial': true,
      },
    );
  }

  void _showAvatarInfo() {
    final avatar = ref.read(avatarProvider).value;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Avatar Information',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Avatar ID', avatar?.id ?? 'N/A'),
              _buildInfoRow('Model Format', avatar?.metadata.fileFormat.toUpperCase() ?? 'N/A'),
              _buildInfoRow('Quality', avatar?.metadata.qualityLevel ?? 'N/A'),
              _buildInfoRow('Height', '${avatar?.measurements.height ?? 0} cm'),
              _buildInfoRow('Weight', '${avatar?.measurements.weight ?? 0} kg'),
              _buildInfoRow('Body Type', avatar?.attributes.bodyType ?? 'N/A'),
              _buildInfoRow('Lighting', avatar?.lighting.label ?? 'N/A'),
              const SizedBox(height: 12),
              const Text(
                'Your avatar was generated using advanced AI technology with precise body measurements.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
