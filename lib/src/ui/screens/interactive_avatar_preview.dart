/// Interactive Avatar Preview Screen
/// 
/// Enhanced avatar preview with comprehensive interactive controls:
/// - 3D Model Viewer with real-time manipulation
/// - Interactive controls panel with smooth animations
/// - Rotation, height, and body shape adjustments
/// - Lighting presets and custom lighting
/// - Comparison mode (before/after)
/// - Preset management and tutorials
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../../themes/app_theme.dart';
import '../../models/avatar_model.dart';
import '../../models/interactive_avatar_model.dart';
import '../../providers/interactive_avatar_provider.dart';
import '../../services/mock_avatar_service.dart';
import '../../widgets/interactive_controls_panel.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/app_button.dart';

/// Interactive Avatar Preview Screen
class InteractiveAvatarPreview extends ConsumerStatefulWidget {
  final String? avatarId;
  final String? scanId;
  final bool showTutorial;

  const InteractiveAvatarPreview({
    super.key,
    this.avatarId,
    this.scanId,
    this.showTutorial = false,
  });

  @override
  ConsumerState<InteractiveAvatarPreview> createState() => _InteractiveAvatarPreviewState();
}

class _InteractiveAvatarPreviewState extends ConsumerState<InteractiveAvatarPreview>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _showControls = true;
  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAvatar();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadAvatar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load mock avatar
      final avatarId = widget.avatarId ?? 'avatar_demo';
      final baseAvatar = await MockAvatarService.getAvatarWithFallback(avatarId);
      
      // Initialize interactive avatar provider
      await ref.read(interactiveAvatarProvider.notifier).initializeAvatar(baseAvatar);
      
    } catch (e) {
      setState(() {
        _error = 'Failed to load avatar: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = ref.watch(interactiveAvatarProvider);
    final currentAvatar = avatarProvider.currentAvatar;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(avatarProvider),
      body: _isLoading
          ? _buildLoadingView()
          : _error != null
              ? _buildErrorView()
              : currentAvatar == null
                  ? _buildEmptyView()
                  : _buildMainView(avatarProvider),
      bottomNavigationBar: _buildBottomBar(avatarProvider),
    );
  }

  PreferredSizeWidget _buildAppBar(InteractiveAvatarProvider provider) {
    return AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interactive Avatar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (provider.currentAvatar?.currentPreset != null)
            Text(
              'Preset: ${provider.currentAvatar!.currentPreset}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
        ],
      ),
      actions: [
        // Comparison toggle
        IconButton(
          onPressed: () => provider.toggleComparison(),
          icon: Icon(
            provider.showComparison ? Icons.compare : Icons.compare_arrows,
          ),
          tooltip: 'Toggle Comparison Mode',
        ),
        // Settings
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, provider),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'tutorial',
              child: ListTile(
                leading: Icon(Icons.help),
                title: Text('Tutorial'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Export Settings'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'haptic',
              child: ListTile(
                leading: Icon(Icons.vibration),
                title: Text('Haptic Feedback'),
                trailing: Switch(
                  value: true,
                  onChanged: null,
                ),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'about',
              child: ListTile(
                leading: Icon(Icons.info),
                title: Text('About'),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingIndicator(),
          SizedBox(height: 24),
          Text(
            'Loading interactive avatar...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load avatar',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              onPressed: _loadAvatar,
              label: 'Try Again',
              backgroundColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Text(
        'No avatar data available',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildMainView(InteractiveAvatarProvider provider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Row(
        children: [
          // Main avatar display area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey.shade900,
                    Colors.black,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Model viewer
                  _buildModelViewer(provider),
                  
                  // Rotation controls overlay
                  if (!provider.showComparison) _buildRotationOverlay(provider),
                  
                  // Comparison indicator
                  if (provider.showComparison) _buildComparisonIndicator(provider),
                  
                  // Loading overlay during animations
                  if (provider.currentAvatar?.controls.isAnimating ?? false)
                    _buildAnimationOverlay(),
                ],
              ),
            ),
          ),
          
          // Controls panel
          if (_showControls)
            SizeTransition(
              sizeFactor: _slideAnimation,
              child: InteractiveControlsPanel(
                panelHeight: MediaQuery.of(context).size.height,
                onClose: () => setState(() => _showControls = false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModelViewer(InteractiveAvatarProvider provider) {
    final avatar = provider.currentAvatar!;
    final config = avatar.getModelViewerConfig();

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: ModelViewer(
          src: config['src'] as String,
          alt: config['alt'] as String,
          ar: config['ar'] as bool,
          autoRotate: config['auto-rotate'] as bool,
          cameraControls: true,
          interactionPrompt: InteractionPrompt.automatic,
          shadowIntensity: config['shadow-intensity'] as double,
          exposure: config['exposure'] as double,
          environmentImage: config['environment-image'] as String,
          skyboxImage: config['skybox-image'] as String,
          loading: Loading.eager,
          reveal: Reveal.auto,
          scale: config['scale'] as String,
          style: '''
            model-viewer {
              width: 100%;
              height: 100%;
              background: transparent;
            }
          ''',
        ),
      ),
    );
  }

  Widget _buildRotationOverlay(InteractiveAvatarProvider provider) {
    final avatar = provider.currentAvatar!;
    final controls = avatar.controls;

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left rotation button
          _OverlayButton(
            icon: Icons.rotate_left,
            onPressed: () => provider.rotateTo((controls.rotationY - 15) % 360),
            color: Colors.blue.withOpacity(0.8),
          ),
          
          // Center info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${controls.rotationY.round()}°',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Right rotation button
          _OverlayButton(
            icon: Icons.rotate_right,
            onPressed: () => provider.rotateTo((controls.rotationY + 15) % 360),
            color: Colors.blue.withOpacity(0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonIndicator(InteractiveAvatarProvider provider) {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.compare,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Comparison Mode',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.blue,
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(InteractiveAvatarProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick stats
            if (provider.currentAvatar != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    'Height',
                    '${provider.currentAvatar!.controls.height.round()} cm',
                  ),
                  _buildStatItem(
                    'Chest',
                    '${provider.currentAvatar!.controls.chestSize.round()}%',
                  ),
                  _buildStatItem(
                    'Waist',
                    '${provider.currentAvatar!.controls.waistSize.round()}%',
                  ),
                  _buildStatItem(
                    'Hips',
                    '${provider.currentAvatar!.controls.hipSize.round()}%',
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: provider.reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade400,
                      side: BorderSide(color: Colors.grey.shade600),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showControls ? null : () => setState(() => _showControls = true),
                    icon: Icon(_showControls ? Icons.close : Icons.tune),
                    label: Text(_showControls ? 'Hide Controls' : 'Show Controls'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showControls ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _continueToShopping,
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('Shop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action, InteractiveAvatarProvider provider) {
    switch (action) {
      case 'tutorial':
        _showTutorial();
        break;
      case 'export':
        _exportSettings(provider);
        break;
      case 'haptic':
        provider.toggleHapticFeedback();
        break;
      case 'about':
        _showAboutDialog();
        break;
    }
  }

  void _showTutorial() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Avatar Controls Tutorial',
          style: TextStyle(color: Colors.white),
        ),
        content: const SingleChildScrollView(
          child: Text(
            '''Welcome to the Interactive Avatar Controls!

🎯 Rotation Controls:
• Use the arrow buttons to rotate 360°
• Toggle auto-rotation for hands-free viewing
• Reset to front-facing position anytime

📏 Height Adjustment:
• Drag the slider to adjust height (150-200cm)
• Real-time scaling applies instantly

👤 Body Shape:
• Adjust chest, waist, and hip percentages (90-110%)
• Use quick presets: Slim, Regular, Athletic
• Fine-tune with individual sliders

💡 Lighting:
• Choose from Studio, Day, Night, or Dramatic lighting
• Each preset optimizes the avatar display

🎨 Tips:
• All changes are saved automatically
• Use comparison mode to see before/after
• Undo/redo buttons for easy adjustments
• Haptic feedback for mobile users''',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _exportSettings(InteractiveAvatarProvider provider) {
    final settings = provider.exportSettings();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings exported: ${settings.length} parameters'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'FitTwin Interactive Avatar',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.person, size: 48),
      children: [
        const Text(
          'Advanced 3D avatar manipulation with real-time controls.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text('• 360° rotation with auto-rotate'),
        const Text('• Height adjustment (150-200cm)'),
        const Text('• Body shape modifications'),
        const Text('• Multiple lighting presets'),
        const Text('• Comparison mode'),
        const Text('• Preset management'),
        const Text('• Smooth animations'),
      ],
    );
  }

  void _continueToShopping() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shopping feature coming soon!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

/// Overlay button widget for rotation controls
class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _OverlayButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        constraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
      ),
    );
  }
}