/// Try-On Viewer Screen
/// 
/// Comprehensive full-screen virtual try-on viewer with:
/// - Advanced lighting control system (Studio, Day, Night, Custom)
/// - Pose presets for different viewing angles
/// - Intelligent fit estimation and recommendations
/// - Smart product recommendations and styling tips
/// - Before/after comparison modes
/// - Social sharing and outfit saving functionality
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../../themes/app_theme.dart';
import '../../models/avatar_model.dart';
import '../../models/interactive_avatar_model.dart';
import '../../models/pose_preset_model.dart';
import '../../models/fit_estimation_model.dart';
import '../../models/smart_recommendations_model.dart';
import '../../providers/interactive_avatar_provider.dart';
import '../../services/mock_avatar_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/loading_indicator.dart';

class TryOnViewer extends ConsumerStatefulWidget {
  final String? productId;
  final String? productName;
  final String? productCategory;
  final String? productSize;
  final List<String>? compatibleSizes;
  final AvatarMeasurements? avatarMeasurements;
  final bool showComparisonMode;

  const TryOnViewer({
    super.key,
    this.productId,
    this.productName,
    this.productCategory,
    this.productSize,
    this.compatibleSizes,
    this.avatarMeasurements,
    this.showComparisonMode = false,
  });

  @override
  ConsumerState<TryOnViewer> createState() => _TryOnViewerState();
}

class _TryOnViewerState extends ConsumerState<TryOnViewer>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _fitSlideController;
  late AnimationController _recommendationsSlideController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _fitSlideAnimation;
  late Animation<double> _recommendationsSlideAnimation;
  
  bool _showControls = true;
  bool _showFitEstimation = true;
  bool _showRecommendations = true;
  bool _isLoading = true;
  String? _error;
  PosePreset _currentPose = PosePreset.frontView;
  LightingPreset _currentLighting = LightingPreset.studio;
  
  // Fit estimation data
  FitEstimationResult? _currentFit;
  List<SizeRecommendation> _sizeRecommendations = [];
  List<ComplementaryProductRecommendation> _complementaryProducts = [];
  List<StylingTip> _stylingTips = [];
  
  // User preferences for recommendations
  UserPreferences _userPreferences = const UserPreferences();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTryOnData();
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
    _fitSlideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _recommendationsSlideController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
    
    _fitSlideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fitSlideController,
      curve: Curves.easeInOut,
    ));
    
    _recommendationsSlideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _recommendationsSlideController,
      curve: Curves.easeInOut,
    ));
    
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _fitSlideController.dispose();
    _recommendationsSlideController.dispose();
    super.dispose();
  }

  Future<void> _loadTryOnData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load avatar with mock data
      final avatarId = 'tryon_avatar';
      final baseAvatar = await MockAvatarService.getAvatarWithFallback(avatarId);
      
      // Initialize interactive avatar provider
      await ref.read(interactiveAvatarProvider.notifier).initializeAvatar(baseAvatar);
      
      // Generate fit estimation
      _generateFitEstimation();
      
      // Generate smart recommendations
      _generateSmartRecommendations();
      
    } catch (e) {
      setState(() {
        _error = 'Failed to load try-on data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateFitEstimation() {
    // Mock avatar measurements
    final avatar = widget.avatarMeasurements ?? const AvatarMeasurements(
      height: 175.0,
      chest: 95.0,
      waist: 80.0,
      hip: 100.0,
      measuredAt: null,
    );
    
    // Mock product size chart
    final productSize = ProductSizeChart(
      size: widget.productSize ?? 'M',
      chest: 96.0,
      waist: 81.0,
      hip: 101.0,
      sizeSystem: 'US',
      brand: 'Sample Brand',
      productCategory: widget.productCategory,
    );
    
    _currentFit = FitEstimationEngine.estimateFit(
      avatar: avatar,
      product: productSize,
      brand: 'Sample Brand',
    );
    
    // Generate size recommendations
    final availableSizes = widget.compatibleSizes ?? ['S', 'M', 'L', 'XL']
        .map((size) => ProductSizeChart(
            size: size,
            chest: size == 'S' ? 92.0 : size == 'L' ? 100.0 : size == 'XL' ? 104.0 : 96.0,
            waist: size == 'S' ? 77.0 : size == 'L' ? 85.0 : size == 'XL' ? 89.0 : 81.0,
            hip: size == 'S' ? 97.0 : size == 'L' ? 105.0 : size == 'XL' ? 109.0 : 101.0,
          ))
        .toList();
    
    _sizeRecommendations = SmartRecommendationsEngine.generateSizeRecommendations(
      avatar: avatar,
      availableSizes: availableSizes,
      currentFit: _currentFit!,
    );
  }

  void _generateSmartRecommendations() {
    if (widget.productCategory == null) return;
    
    _complementaryProducts = SmartRecommendationsEngine.generateComplementaryRecommendations(
      primaryProductId: widget.productId ?? 'unknown',
      primaryProductCategory: widget.productCategory!,
      brand: 'Sample Brand',
    );
    
    _stylingTips = SmartRecommendationsEngine.generateStylingTips(
      productId: widget.productId ?? 'unknown',
      productCategory: widget.productCategory!,
    );
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
          Text(
            widget.productName ?? 'Virtual Try-On',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Size: ${widget.productSize ?? "M"} • Pose: ${_currentPose.displayName}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
      actions: [
        // Fit confidence indicator
        if (_currentFit != null)
          _buildFitConfidenceIndicator(),
        
        // Share button
        IconButton(
          onPressed: _shareTryOnResult,
          icon: const Icon(Icons.share),
          tooltip: 'Share Try-On Result',
        ),
        
        // Save outfit
        IconButton(
          onPressed: _saveOutfit,
          icon: const Icon(Icons.bookmark_border),
          tooltip: 'Save Outfit',
        ),
        
        // Settings menu
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'save-avatar',
              child: ListTile(
                leading: Icon(Icons.save),
                title: Text('Save Avatar'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'export-data',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Export Data'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'feedback',
              child: ListTile(
                leading: Icon(Icons.feedback),
                title: Text('Send Feedback'),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFitConfidenceIndicator() {
    if (_currentFit == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _currentFit!.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _currentFit!.color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getConfidenceIcon(),
            size: 14,
            color: _currentFit!.color,
          ),
          const SizedBox(width: 4),
          Text(
            '${_currentFit!.confidenceScore.round()}%',
            style: TextStyle(
              color: _currentFit!.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getConfidenceIcon() {
    switch (_currentFit!.confidence) {
      case FitConfidence.veryHigh:
        return Icons.check_circle;
      case FitConfidence.high:
        return Icons.check_circle_outline;
      case FitConfidence.medium:
        return Icons.help_outline;
      case FitConfidence.low:
        return Icons.warning;
    }
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingIndicator(),
          SizedBox(height: 24),
          Text(
            'Setting up your virtual try-on...',
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
              'Failed to load try-on',
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
              onPressed: _loadTryOnData,
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
        'No avatar data available for try-on',
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
      child: Stack(
        children: [
          // Main avatar display area
          Row(
            children: [
              // Avatar viewport
              Expanded(
                child: _buildAvatarViewport(provider),
              ),
              
              // Controls panel (right side)
              if (_showControls)
                SizeTransition(
                  sizeFactor: _slideAnimation,
                  child: _buildControlsPanel(),
                ),
            ],
          ),
          
          // Pose presets overlay (bottom center)
          _buildPosePresetsOverlay(),
          
          // Lighting controls overlay (top right)
          _buildLightingControlsOverlay(),
          
          // Fit estimation panel (top left)
          if (_showFitEstimation && _currentFit != null)
            Positioned(
              top: 16,
              left: 16,
              child: FadeTransition(
                opacity: _fitSlideAnimation,
                child: _buildFitEstimationPanel(),
              ),
            ),
          
          // Recommendations panel (bottom left)
          if (_showRecommendations)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: FadeTransition(
                opacity: _recommendationsSlideAnimation,
                child: _buildRecommendationsPanel(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarViewport(InteractiveAvatarProvider provider) {
    final avatar = provider.currentAvatar!;
    final config = avatar.getModelViewerConfig();

    return Container(
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
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
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
          ),
          
          // Pose indicator
          _buildPoseIndicator(),
          
          // Lighting preset indicator
          _buildLightingIndicator(),
          
          // Loading overlay during animations
          if (avatar.controls.isAnimating)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlsPanel() {
    return Container(
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
          _buildPanelHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPoseControls(),
                const SizedBox(height: 20),
                _buildLightingControls(),
                const SizedBox(height: 20),
                _buildViewingControls(),
                const SizedBox(height: 20),
                _buildComparisonControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelHeader() {
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
            'Try-On Controls',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => setState(() => _showControls = false),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPoseControls() {
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
              final isSelected = _currentPose == preset;
              return _PosePresetButton(
                onPressed: () => _applyPosePreset(preset),
                icon: preset.icon,
                label: preset.displayName,
                isSelected: isSelected,
                description: preset.description,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLightingControls() {
    return _ControlSection(
      title: 'Lighting Presets',
      icon: Icons.lightbulb,
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LightingPreset.values.map((preset) {
              final isSelected = _currentLighting == preset;
              return _LightingPresetButton(
                onPressed: () => _applyLightingPreset(preset),
                label: preset.displayName,
                isSelected: isSelected,
                intensity: preset.intensity,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _buildCustomLightingControls(),
        ],
      ),
    );
  }

  Widget _buildCustomLightingControls() {
    return Column(
      children: [
        const Text(
          'Custom Lighting',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ControlButton(
                onPressed: _openCustomLightingDialog,
                icon: Icons.tune,
                label: 'Adjust',
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewingControls() {
    return _ControlSection(
      title: 'Viewing Options',
      icon: Icons.visibility,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ControlButton(
                  onPressed: _resetToDefault,
                  icon: Icons.refresh,
                  label: 'Reset',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ControlButton(
                  onPressed: _toggleComparison,
                  icon: Icons.compare,
                  label: 'Compare',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ControlButton(
                  onPressed: () => setState(() => _showFitEstimation = !_showFitEstimation),
                  icon: Icons.straighten,
                  label: _showFitEstimation ? 'Hide Fit' : 'Show Fit',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ControlButton(
                  onPressed: () => setState(() => _showRecommendations = !_showRecommendations),
                  icon: Icons.tips_and_updates,
                  label: _showRecommendations ? 'Hide Tips' : 'Show Tips',
                  color: Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonControls() {
    return _ControlSection(
      title: 'Comparison & Sharing',
      icon: Icons.share,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _shareTryOnResult,
              icon: const Icon(Icons.share, size: 16),
              label: const Text('Share Result', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _saveOutfit,
              icon: const Icon(Icons.bookmark_border, size: 16),
              label: const Text('Save Outfit', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade400,
                side: BorderSide(color: Colors.grey.shade600),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosePresetsOverlay() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Poses',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final preset in PosePreset.values)
                    _PoseQuickButton(
                      onPressed: () => _applyPosePreset(preset),
                      icon: preset.icon,
                      label: preset.displayName.split(' ').first,
                      isSelected: _currentPose == preset,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightingControlsOverlay() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Lighting',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                for (final preset in LightingPreset.values)
                  _LightingQuickButton(
                    onPressed: () => _applyLightingPreset(preset),
                    isSelected: _currentLighting == preset,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFitEstimationPanel() {
    if (_currentFit == null) return const SizedBox.shrink();
    
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _currentFit!.color.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  _getConfidenceIcon(),
                  color: _currentFit!.color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fit Estimation',
                        style: TextStyle(
                          color: _currentFit!.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${_currentFit!.confidenceScore.round()}% confidence',
                        style: TextStyle(
                          color: _currentFit!.color.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _showFitEstimation = false),
                  icon: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
          
          // Fit recommendation
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentFit!.recommendation.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentFit!.recommendation.description,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Area-specific estimations
                ..._currentFit!.areaEstimations.map((area) => _buildFitAreaItem(area)),
                
                const SizedBox(height: 12),
                if (_sizeRecommendations.isNotEmpty) ...[
                  Text(
                    'Size Recommendations',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._sizeRecommendations.take(2).map((rec) => _buildSizeRecommendation(rec)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFitAreaItem(FitAreaEstimation area) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              area.areaName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: area.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${area.deviation > 0 ? '+' : ''}${area.deviation.round()}%',
              style: TextStyle(
                color: area.color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeRecommendation(SizeRecommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              recommendation.actionText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${(recommendation.confidence * 100).round()}%',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsPanel() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Smart Recommendations',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _showRecommendations = false),
                  icon: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (_complementaryProducts.isNotEmpty) ...[
                  Text(
                    'Complete the Look',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._complementaryProducts.take(2).map((rec) => _buildComplementaryProduct(rec)),
                  const SizedBox(height: 16),
                ],
                
                if (_stylingTips.isNotEmpty) ...[
                  Text(
                    'Styling Tips',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._stylingTips.take(2).map((tip) => _buildStylingTip(tip)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplementaryProduct(ComplementaryProductRecommendation rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.shopping_bag,
              color: Colors.blue,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.complementaryProductName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  rec.reason,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${(rec.compatibilityScore * 100).round()}%',
              style: TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStylingTip(StylingTip tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Colors.orange,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.tip,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Best for: ${tip.categoryDisplay}',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoseIndicator() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_currentPose.icon, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Text(
              _currentPose.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightingIndicator() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.yellow.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lightbulb, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Text(
              _currentLighting.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action methods
  void _applyPosePreset(PosePreset preset) async {
    final provider = ref.read(interactiveAvatarProvider.notifier);
    
    setState(() {
      _currentPose = preset;
    });
    
    // Animate to the preset rotation
    await provider.rotateTo(preset.rotationY, animate: true);
    
    // Show haptic feedback if supported
    HapticFeedback.lightImpact();
  }

  void _applyLightingPreset(LightingPreset preset) async {
    final provider = ref.read(interactiveAvatarProvider.notifier);
    
    setState(() {
      _currentLighting = preset;
    });
    
    // Apply lighting preset
    provider.applyLighting(preset);
    
    // Animate lighting transition
    HapticFeedback.mediumImpact();
  }

  void _openCustomLightingDialog() {
    showDialog(
      context: context,
      builder: (context) => _CustomLightingDialog(),
    );
  }

  void _resetToDefault() {
    final provider = ref.read(interactiveAvatarProvider.notifier);
    
    setState(() {
      _currentPose = PosePreset.frontView;
      _currentLighting = LightingPreset.studio;
    });
    
    provider.reset();
    HapticFeedback.lightImpact();
  }

  void _toggleComparison() {
    final provider = ref.read(interactiveAvatarProvider.notifier);
    provider.toggleComparison();
    HapticFeedback.mediumImpact();
  }

  void _shareTryOnResult() {
    // Implementation for sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _saveOutfit() {
    // Implementation for saving outfit
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Outfit saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'save-avatar':
        _saveOutfit();
        break;
      case 'export-data':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data export feature coming soon!'),
            backgroundColor: Colors.blue,
          ),
        );
        break;
      case 'feedback':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
          ),
        );
        break;
    }
  }
}

/// Custom lighting configuration dialog
class _CustomLightingDialog extends StatefulWidget {
  @override
  State<_CustomLightingDialog> createState() => _CustomLightingDialogState();
}

class _CustomLightingDialogState extends State<_CustomLightingDialog> {
  double _intensity = 1.0;
  double _angle = 45.0;
  double _elevation = 30.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: const Text(
        'Custom Lighting',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSlider('Intensity', _intensity, 0.0, 2.0, (value) {
            setState(() => _intensity = value);
          }),
          _buildSlider('Angle', _angle, 0.0, 360.0, (value) {
            setState(() => _angle = value);
          }),
          _buildSlider('Elevation', _elevation, -90.0, 90.0, (value) {
            setState(() => _elevation = value);
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Apply custom lighting
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white)),
            Text(
              '${value.toStringAsFixed(1)}${label == 'Angle' || label == 'Elevation' ? '°' : ''}',
              style: TextStyle(color: Colors.blue),
            ),
          ],
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          min: min,
          max: max,
          activeColor: Colors.blue,
          inactiveColor: Colors.grey.shade600,
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
          ),
        ],
      ),
    );
  }
}

/// Lighting preset button widget
class _LightingPresetButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final bool isSelected;
  final double intensity;

  const _LightingPresetButton({
    required this.onPressed,
    required this.label,
    required this.isSelected,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.yellow.shade600 : Colors.grey.shade700,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lightbulb, size: 14),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Quick pose button widget
class _PoseQuickButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isSelected;

  const _PoseQuickButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.grey.shade800,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

/// Quick lighting button widget
class _LightingQuickButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isSelected;

  const _LightingQuickButton({
    required this.onPressed,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          Icons.lightbulb,
          color: isSelected ? Colors.yellow : Colors.grey.shade400,
          size: 20,
        ),
        style: IconButton.styleFrom(
          backgroundColor: isSelected 
              ? Colors.yellow.withOpacity(0.2) 
              : Colors.grey.shade800,
        ),
      ),
    );
  }
}

/// Control button widget
class _ControlButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color? color;

  const _ControlButton({
    this.onPressed,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.grey.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
