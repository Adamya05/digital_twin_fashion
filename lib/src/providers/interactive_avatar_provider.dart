/// Interactive Avatar Provider
/// 
/// State management for interactive avatar controls including:
/// - Real-time parameter updates
/// - Animation states
/// - Undo/redo functionality  
/// - Preset management
/// - Comparison mode
/// - Local storage persistence
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/interactive_avatar_model.dart';
import '../models/avatar_model.dart';

/// Interactive Avatar State notifier
class InteractiveAvatarProvider extends ChangeNotifier {
  static const String _preferencesKey = 'interactive_avatar_settings';
  static const String _historyKey = 'avatar_adjustment_history';
  
  InteractiveAvatar? _currentAvatar;
  AvatarComparison? _comparison;
  bool _isLoading = false;
  String? _error;
  bool _showComparison = false;
  ComparisonMode _comparisonMode = ComparisonMode.sideBySide;
  bool _hapticFeedbackEnabled = true;

  // Getters
  InteractiveAvatar? get currentAvatar => _currentAvatar;
  AvatarComparison? get comparison => _comparison;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get showComparison => _showComparison;
  ComparisonMode get comparisonMode => _comparisonMode;
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  bool get canUndo => _currentAvatar?.history?.undo != null;
  bool get canRedo => _currentAvatar?.history != null;

  /// Initialize provider with base avatar
  Future<void> initializeAvatar(Avatar baseAvatar) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load saved settings if available
      final savedControls = await _loadSavedControls();
      final savedPreset = await _loadSavedPreset();
      
      _currentAvatar = InteractiveAvatar.fromAvatar(baseAvatar).copyWith(
        controls: savedControls,
        currentPreset: savedPreset,
      );
      
      // Restore from history if available
      await _loadHistory();
      
    } catch (e) {
      _error = 'Failed to initialize avatar: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update avatar height with real-time scaling
  Future<void> updateHeight(double height, {bool animate = true}) async {
    if (_currentAvatar == null) return;

    _hapticFeedback();
    
    _currentAvatar = _currentAvatar!.updateHeight(height, animate: animate);
    
    if (animate) {
      // Simulate animation duration
      await Future.delayed(const Duration(milliseconds: 300));
      _currentAvatar = _currentAvatar!.completeAnimation();
    }
    
    await _saveControls();
    notifyListeners();
  }

  /// Update body shape dimensions
  Future<void> updateBodyShape({
    double? chest,
    double? waist,
    double? hip,
    bool animate = true,
  }) async {
    if (_currentAvatar == null) return;

    _hapticFeedback();
    
    _currentAvatar = _currentAvatar!.updateBodyShape(
      chest: chest,
      waist: waist,
      hip: hip,
      animate: animate,
    );
    
    if (animate) {
      await Future.delayed(const Duration(milliseconds: 300));
      _currentAvatar = _currentAvatar!.completeAnimation();
    }
    
    await _saveControls();
    notifyListeners();
  }

  /// Apply body preset
  Future<void> applyBodyPreset(BodyPreset preset, {bool animate = true}) async {
    if (_currentAvatar == null) return;

    _hapticFeedback();
    
    _currentAvatar = _currentAvatar!
        .applyBodyPreset(preset, animate: animate)
        .saveToHistory();
    
    if (animate) {
      await Future.delayed(const Duration(milliseconds: 500));
      _currentAvatar = _currentAvatar!.completeAnimation();
    }
    
    await _savePreset(preset.displayName);
    await _saveControls();
    notifyListeners();
  }

  /// Rotate avatar to specific angle
  Future<void> rotateTo(double angle, {bool animate = true}) async {
    if (_currentAvatar == null) return;

    _hapticFeedback();
    
    _currentAvatar = _currentAvatar!.rotateTo(angle, animate: animate);
    
    if (animate) {
      await Future.delayed(const Duration(milliseconds: 200));
      _currentAvatar = _currentAvatar!.completeAnimation();
    }
    
    await _saveControls();
    notifyListeners();
  }

  /// Toggle auto-rotation
  Future<void> toggleAutoRotate({bool? enabled, double? speed}) async {
    if (_currentAvatar == null) return;

    _currentAvatar = _currentAvatar!.toggleAutoRotate(
      enabled: enabled,
      speed: speed,
    );
    
    await _saveControls();
    notifyListeners();
  }

  /// Apply lighting preset
  Future<void> applyLighting(LightingPreset preset) async {
    if (_currentAvatar == null) return;

    _hapticFeedback();
    
    _currentAvatar = _currentAvatar!.applyLighting(preset);
    await _saveControls();
    notifyListeners();
  }

  /// Reset all adjustments
  Future<void> reset({bool animate = true}) async {
    if (_currentAvatar == null) return;

    _hapticFeedback();
    
    _currentAvatar = _currentAvatar!.reset(animate: animate);
    
    if (animate) {
      await Future.delayed(const Duration(milliseconds: 500));
      _currentAvatar = _currentAvatar!.completeAnimation();
    }
    
    await _clearSavedPreset();
    await _saveControls();
    notifyListeners();
  }

  /// Save current state to history
  Future<void> saveToHistory() async {
    if (_currentAvatar == null) return;
    
    _currentAvatar = _currentAvatar!.saveToHistory();
    await _saveHistory();
    notifyListeners();
  }

  /// Undo last change
  Future<void> undo() async {
    if (_currentAvatar?.history?.undo == null) return;

    final previousState = _currentAvatar!.history!.undo!;
    _currentAvatar = _currentAvatar!.copyWith(
      controls: previousState.controls,
      history: previousState.previous,
      currentPreset: previousState.preset,
    );
    
    _hapticFeedback();
    await _saveControls();
    await _savePreset(previousState.preset);
    notifyListeners();
  }

  /// Redo last undone change
  Future<void> redo() async {
    if (_currentAvatar == null) return;
    // In a full implementation, this would manage redo stack
    // For now, we'll just trigger a save to history
    await saveToHistory();
  }

  /// Toggle comparison mode
  void toggleComparison({ComparisonMode? mode}) {
    if (_currentAvatar == null) return;

    if (_showComparison && mode != null) {
      _comparisonMode = mode;
    } else {
      _showComparison = !_showComparison;
      if (_showComparison && mode != null) {
        _comparisonMode = mode;
      }
    }

    if (_showComparison) {
      // Create comparison with original avatar
      final originalAvatar = InteractiveAvatar.fromAvatar(_currentAvatar!.baseAvatar);
      _comparison = AvatarComparison(
        original: originalAvatar,
        modified: _currentAvatar!,
        mode: _comparisonMode,
      );
    } else {
      _comparison = null;
    }

    notifyListeners();
  }

  /// Toggle haptic feedback
  void toggleHapticFeedback() {
    _hapticFeedbackEnabled = !_hapticFeedbackEnabled;
    _savePreferences();
    notifyListeners();
  }

  /// Save avatar configuration
  Future<void> saveAvatarConfiguration() async {
    if (_currentAvatar == null) return;

    try {
      final config = _currentAvatar!.controls.toString();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_preferencesKey}_config', config);
      
      _showSuccessMessage('Avatar configuration saved!');
    } catch (e) {
      _error = 'Failed to save configuration: $e';
      notifyListeners();
    }
  }

  /// Export avatar settings
  Map<String, dynamic> exportSettings() {
    if (_currentAvatar == null) return {};

    return {
      'controls': {
        'height': _currentAvatar!.controls.height,
        'chestSize': _currentAvatar!.controls.chestSize,
        'waistSize': _currentAvatar!.controls.waistSize,
        'hipSize': _currentAvatar!.controls.hipSize,
        'rotationY': _currentAvatar!.controls.rotationY,
        'autoRotate': _currentAvatar!.controls.autoRotate,
        'autoRotateSpeed': _currentAvatar!.controls.autoRotateSpeed,
        'lightingPreset': _currentAvatar!.controls.lightingPreset.name,
      },
      'preset': _currentAvatar!.currentPreset,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Import avatar settings
  Future<void> importSettings(Map<String, dynamic> settings) async {
    if (_currentAvatar == null) return;

    try {
      final controls = settings['controls'] as Map<String, dynamic>;
      final preset = settings['preset'] as String?;
      
      final newControls = InteractiveAvatarControls(
        height: (controls['height'] as num?)?.toDouble() ?? 175.0,
        chestSize: (controls['chestSize'] as num?)?.toDouble() ?? 100.0,
        waistSize: (controls['waistSize'] as num?)?.toDouble() ?? 100.0,
        hipSize: (controls['hipSize'] as num?)?.toDouble() ?? 100.0,
        rotationY: (controls['rotationY'] as num?)?.toDouble() ?? 0.0,
        autoRotate: controls['autoRotate'] as bool? ?? false,
        autoRotateSpeed: (controls['autoRotateSpeed'] as num?)?.toDouble() ?? 2.0,
        lightingPreset: LightingPreset.values.firstWhere(
          (p) => p.name == controls['lightingPreset'],
          orElse: () => LightingPreset.studio,
        ),
      );

      _currentAvatar = _currentAvatar!.copyWith(
        controls: newControls,
        currentPreset: preset,
      );

      if (preset != null) {
        await _savePreset(preset);
      }
      await _saveControls();
      
      _showSuccessMessage('Settings imported successfully!');
    } catch (e) {
      _error = 'Failed to import settings: $e';
    }

    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Private methods
  void _hapticFeedback() {
    if (_hapticFeedbackEnabled) {
      // In a real implementation, this would trigger actual haptic feedback
      // For now, we'll just log it
      debugPrint('Haptic feedback triggered');
    }
  }

  Future<void> _saveControls() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final controls = _currentAvatar!.controls;
      
      await prefs.setDouble('height', controls.height);
      await prefs.setDouble('chestSize', controls.chestSize);
      await prefs.setDouble('waistSize', controls.waistSize);
      await prefs.setDouble('hipSize', controls.hipSize);
      await prefs.setDouble('rotationY', controls.rotationY);
      await prefs.setBool('autoRotate', controls.autoRotate);
      await prefs.setDouble('autoRotateSpeed', controls.autoRotateSpeed);
      await prefs.setString('lightingPreset', controls.lightingPreset.name);
    } catch (e) {
      debugPrint('Failed to save controls: $e');
    }
  }

  Future<InteractiveAvatarControls> _loadSavedControls() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return InteractiveAvatarControls(
        height: prefs.getDouble('height') ?? 175.0,
        chestSize: prefs.getDouble('chestSize') ?? 100.0,
        waistSize: prefs.getDouble('waistSize') ?? 100.0,
        hipSize: prefs.getDouble('hipSize') ?? 100.0,
        rotationY: prefs.getDouble('rotationY') ?? 0.0,
        autoRotate: prefs.getBool('autoRotate') ?? false,
        autoRotateSpeed: prefs.getDouble('autoRotateSpeed') ?? 2.0,
        lightingPreset: LightingPreset.values.firstWhere(
          (p) => p.name == prefs.getString('lightingPreset'),
          orElse: () => LightingPreset.studio,
        ),
      );
    } catch (e) {
      debugPrint('Failed to load controls: $e');
      return const InteractiveAvatarControls();
    }
  }

  Future<void> _savePreset(String preset) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentPreset', preset);
    } catch (e) {
      debugPrint('Failed to save preset: $e');
    }
  }

  Future<String?> _loadSavedPreset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('currentPreset');
    } catch (e) {
      debugPrint('Failed to load preset: $e');
      return null;
    }
  }

  Future<void> _clearSavedPreset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentPreset');
    } catch (e) {
      debugPrint('Failed to clear preset: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // In a full implementation, this would save the entire history
      await prefs.setInt('historyDepth', _currentAvatar?.history?.depth ?? 0);
    } catch (e) {
      debugPrint('Failed to save history: $e');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final depth = prefs.getInt('historyDepth') ?? 0;
      // In a full implementation, this would restore the entire history
      debugPrint('Loaded history with $depth steps');
    } catch (e) {
      debugPrint('Failed to load history: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hapticFeedback', _hapticFeedbackEnabled);
    } catch (e) {
      debugPrint('Failed to save preferences: $e');
    }
  }

  void _showSuccessMessage(String message) {
    // In a real implementation, this would show a toast or snackbar
    debugPrint('Success: $message');
  }

  @override
  void dispose() {
    // Clean up any resources
    super.dispose();
  }
}