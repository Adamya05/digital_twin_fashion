import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import '../models/avatar_model.dart';
import '../models/product_model.dart';

/// Advanced try-on configuration system with realistic fitting algorithms
class TryOnConfigurationService extends ChangeNotifier {
  static TryOnConfigurationService? _instance;
  static TryOnConfigurationService get instance => _instance ??= TryOnConfigurationService._internal();
  
  factory TryOnConfigurationService() => instance;
  TryOnConfigurationService._internal();

  // Fitting algorithms configuration
  final Map<String, FittingAlgorithm> _fittingAlgorithms = {};
  final Map<String, MaterialProperties> _materialProperties = {};
  final Map<String, PhysicsSimulation> _physicsConfig = {};
  
  // Realistic measurements database
  final Map<String, Map<String, Map<String, double>>> _bodyMeasurements = {};
  final Map<String, Map<String, Map<String, double>>> _productMeasurements = {};
  
  // Collision detection system
  final CollisionDetector _collisionDetector = CollisionDetector();
  
  // Fit quality metrics
  final Map<String, FitQualityMetrics> _fitQualityCache = {};
  
  /// Initialize service with default configurations
  Future<void> initialize() async {
    _initializeFittingAlgorithms();
    _initializeMaterialProperties();
    _initializePhysicsConfiguration();
    _initializeMeasurementsDatabase();
  }
  
  /// Configure try-on parameters for avatar-product combination
  TryOnConfiguration configureTryOn({
    required String avatarId,
    required String productId,
    required AvatarType avatarType,
    required ProductCategory category,
    String size = 'M',
    Map<String, dynamic>? customSettings,
  }) {
    // Get base measurements
    final avatarMeasurements = _getAvatarMeasurements(avatarId, avatarType);
    final productMeasurements = _getProductMeasurements(productId, category, size);
    
    // Calculate fitting parameters
    final fittingParams = _calculateFittingParameters(
      avatarMeasurements,
      productMeasurements,
      category,
    );
    
    // Apply physics simulation
    final physicsConfig = _getPhysicsConfiguration(category, productId);
    
    // Configure collision detection
    final collisionConfig = _configureCollisionDetection(
      avatarMeasurements,
      category,
      fittingParams,
    );
    
    // Apply material properties
    final materialProps = _getMaterialProperties(category, productId);
    
    // Calculate fit quality
    final fitQuality = _calculateFitQuality(fittingParams, materialProps);
    
    // Create final configuration
    return TryOnConfiguration(
      productId: productId,
      avatarId: avatarId,
      avatarType: avatarType,
      category: category,
      size: size,
      fittingParameters: fittingParams,
      physicsSimulation: physicsConfig,
      collisionDetection: collisionConfig,
      materialProperties: materialProps,
      fitQuality: fitQuality,
      customSettings: customSettings ?? {},
    );
  }
  
  /// Calculate realistic size scaling based on body measurements
  Map<String, double> calculateSizeScaling({
    required Map<String, double> avatarMeasurements,
    required Map<String, double> productMeasurements,
    required ProductCategory category,
  }) {
    final scaling = <String, double>{};
    
    // Core measurement scaling
    scaling['chest'] = _calculateScalingRatio(
      avatarMeasurements['chest'] ?? 100.0,
      productMeasurements['chest'] ?? 100.0,
      category,
    );
    
    scaling['waist'] = _calculateScalingRatio(
      avatarMeasurements['waist'] ?? 80.0,
      productMeasurements['waist'] ?? 80.0,
      category,
    );
    
    scaling['hips'] = _calculateScalingRatio(
      avatarMeasurements['hips'] ?? 95.0,
      productMeasurements['hips'] ?? 95.0,
      category,
    );
    
    scaling['shoulders'] = _calculateScalingRatio(
      avatarMeasurements['shoulders'] ?? 45.0,
      productMeasurements['shoulders'] ?? 45.0,
      category,
    );
    
    // Additional measurements for specific categories
    if (category == ProductCategory.dresses) {
      scaling['bust'] = scaling['chest'];
      scaling['sleeve'] = _calculateArmScaling(avatarMeasurements, productMeasurements);
    } else if (category == ProductCategory.pants) {
      scaling['inseam'] = _calculateInseamScaling(avatarMeasurements, productMeasurements);
      scaling['thigh'] = _calculateThighScaling(avatarMeasurements, productMeasurements);
    } else if (category == ProductCategory.outerwear) {
      scaling['arm_length'] = _calculateArmScaling(avatarMeasurements, productMeasurements);
      scaling['torso_length'] = _calculateTorsoScaling(avatarMeasurements, productMeasurements);
    }
    
    // Apply realistic constraints
    _applyRealisticConstraints(scaling, category);
    
    return scaling;
  }
  
  /// Simulate realistic fabric behavior
  FabricBehavior simulateFabricBehavior({
    required String productId,
    required ProductCategory category,
    required Map<String, double> bodyMeasurements,
    required List<String> movementActions,
  }) {
    final materialProps = _materialProperties[category.toString()] ?? MaterialProperties.cotton;
    final physicsConfig = _physicsConfig[productId] ?? _getDefaultPhysics(category);
    
    final behavior = FabricBehavior();
    
    for (final action in movementActions) {
      final actionResponse = _simulateMovementResponse(
        action,
        materialProps,
        physicsConfig,
        bodyMeasurements,
      );
      behavior.movementResponses[action] = actionResponse;
    }
    
    // Calculate wrinkle patterns based on fabric properties
    behavior.wrinklePattern = _calculateWrinklePattern(materialProps, physicsConfig, bodyMeasurements);
    
    // Simulate fabric stretching
    behavior.stretchSimulation = _simulateStretching(materialProps, physicsConfig, bodyMeasurements);
    
    return behavior;
  }
  
  /// Perform collision detection for clothing items
  CollisionResult detectCollision({
    required String primaryProductId,
    required List<String> secondaryProductIds,
    required Map<String, dynamic> bodyStructure,
  }) {
    return _collisionDetector.detectCollisions(
      primaryProductId: primaryProductId,
      secondaryProductIds: secondaryProductIds,
      bodyStructure: bodyStructure,
    );
  }
  
  /// Get fit quality score
  FitQualityMetrics calculateFitQuality({
    required String productId,
    required String avatarId,
    required Map<String, double> sizeScaling,
    required MaterialProperties materialProps,
  }) {
    final cacheKey = '${productId}_${avatarId}';
    
    if (_fitQualityCache.containsKey(cacheKey)) {
      return _fitQualityCache[cacheKey]!;
    }
    
    // Calculate various fit quality metrics
    final comfortScore = _calculateComfortScore(sizeScaling, materialProps);
    final appearanceScore = _calculateAppearanceScore(sizeScaling);
    final mobilityScore = _calculateMobilityScore(sizeScaling, materialProps);
    final realismScore = _calculateRealismScore(sizeScaling, materialProps);
    
    final overallScore = (comfortScore + appearanceScore + mobilityScore + realismScore) / 4;
    
    final metrics = FitQualityMetrics(
      overallScore: overallScore,
      comfortScore: comfortScore,
      appearanceScore: appearanceScore,
      mobilityScore: mobilityScore,
      realismScore: realismScore,
      recommendations: _generateFitRecommendations(sizeScaling, materialProps),
    );
    
    _fitQualityCache[cacheKey] = metrics;
    return metrics;
  }
  
  /// Private helper methods
  
  void _initializeFittingAlgorithms() {
    _fittingAlgorithms.addAll({
      'basic_scaling': FittingAlgorithm(
        name: 'Basic Scaling',
        description: 'Simple proportional scaling',
        parameters: {'scale_factor': 1.0, 'preserve_ratios': true},
        accuracy: 0.7,
      ),
      'advanced_spline': FittingAlgorithm(
        name: 'Advanced Spline',
        description: 'Spline-based fitting with curve preservation',
        parameters: {'curve_preservation': true, 'anchor_points': ['shoulders', 'waist', 'hips']},
        accuracy: 0.85,
      ),
      'physics_based': FittingAlgorithm(
        name: 'Physics-Based',
        description: 'Realistic physics simulation',
        parameters: {'gravity_effect': true, 'material_response': true, 'collision_detection': true},
        accuracy: 0.95,
      ),
      'ai_optimized': FittingAlgorithm(
        name: 'AI Optimized',
        description: 'Machine learning optimized fitting',
        parameters: {'learning_rate': 0.01, 'training_iterations': 100},
        accuracy: 0.9,
      ),
    });
  }
  
  void _initializeMaterialProperties() {
    _materialProperties.addAll({
      'cotton': MaterialProperties(
        name: 'Cotton',
        stiffness: 0.6,
        damping: 0.4,
        stretchFactor: 1.1,
        wrinkleResistance: 0.7,
        texture: 'cotton_weave',
        colorRetention: 0.8,
        breathability: 0.9,
        careLevel: CareLevel.medium,
      ),
      'silk': MaterialProperties(
        name: 'Silk',
        stiffness: 0.2,
        damping: 0.8,
        stretchFactor: 1.05,
        wrinkleResistance: 0.3,
        texture: 'smooth_satin',
        colorRetention: 0.9,
        breathability: 0.6,
        careLevel: CareLevel.high,
      ),
      'wool': MaterialProperties(
        name: 'Wool',
        stiffness: 0.8,
        damping: 0.6,
        stretchFactor: 1.15,
        wrinkleResistance: 0.9,
        texture: 'fiber_knit',
        colorRetention: 0.7,
        breathability: 0.5,
        careLevel: CareLevel.medium,
      ),
      'polyester': MaterialProperties(
        name: 'Polyester',
        stiffness: 0.7,
        damping: 0.3,
        stretchFactor: 1.2,
        wrinkleResistance: 0.95,
        texture: 'synthetic_weave',
        colorRetention: 0.9,
        breathability: 0.4,
        careLevel: CareLevel.low,
      ),
      'spandex': MaterialProperties(
        name: 'Spandex',
        stiffness: 0.1,
        damping: 0.1,
        stretchFactor: 1.5,
        wrinkleResistance: 1.0,
        texture: 'elastic_knit',
        colorRetention: 0.8,
        breathability: 0.7,
        careLevel: CareLevel.low,
      ),
    });
  }
  
  void _initializePhysicsConfiguration() {
    _physicsConfig.addAll({
      'dress_silk': PhysicsSimulation(
        gravityInfluence: 0.8,
        windResistance: 0.6,
        stretchLimit: 1.3,
        compressionResistance: 0.4,
        surfaceFriction: 0.3,
        collisionThreshold: 0.05,
      ),
      'jacket_wool': PhysicsSimulation(
        gravityInfluence: 0.9,
        windResistance: 0.8,
        stretchLimit: 1.1,
        compressionResistance: 0.8,
        surfaceFriction: 0.7,
        collisionThreshold: 0.02,
      ),
      'tshirt_cotton': PhysicsSimulation(
        gravityInfluence: 0.85,
        windResistance: 0.5,
        stretchLimit: 1.25,
        compressionResistance: 0.6,
        surfaceFriction: 0.5,
        collisionThreshold: 0.03,
      ),
      'leggings_spandex': PhysicsSimulation(
        gravityInfluence: 0.95,
        windResistance: 0.7,
        stretchLimit: 1.8,
        compressionResistance: 0.9,
        surfaceFriction: 0.4,
        collisionThreshold: 0.01,
      ),
    });
  }
  
  void _initializeMeasurementsDatabase() {
    // Avatar measurements database
    _bodyMeasurements['male'] = {
      'slim': {'chest': 90, 'waist': 72, 'hips': 88, 'shoulders': 42},
      'regular': {'chest': 100, 'waist': 85, 'hips': 95, 'shoulders': 48},
      'athletic': {'chest': 108, 'waist': 82, 'hips': 97, 'shoulders': 52},
      'muscular': {'chest': 115, 'waist': 88, 'hips': 100, 'shoulders': 55},
    };
    
    _bodyMeasurements['female'] = {
      'petite': {'chest': 82, 'waist': 62, 'hips': 90, 'shoulders': 35},
      'slim': {'chest': 84, 'waist': 64, 'hips': 92, 'shoulders': 36},
      'regular': {'chest': 88, 'waist': 70, 'hips': 96, 'shoulders': 38},
      'athletic': {'chest': 92, 'waist': 68, 'hips': 98, 'shoulders': 40},
      'plussize': {'chest': 105, 'waist': 92, 'hips': 112, 'shoulders': 44},
    };
    
    // Product measurements database (size M as baseline)
    _productMeasurements['tops'] = {
      'chest': {'XS': 82, 'S': 86, 'M': 90, 'L': 96, 'XL': 102},
      'shoulders': {'XS': 35, 'S': 37, 'M': 39, 'L': 41, 'XL': 43},
      'length': {'XS': 60, 'S': 62, 'M': 64, 'L': 66, 'XL': 68},
    };
    
    _productMeasurements['dresses'] = {
      'bust': {'XS': 82, 'S': 86, 'M': 90, 'L': 96, 'XL': 102},
      'waist': {'XS': 64, 'S': 68, 'M': 72, 'L': 78, 'XL': 84},
      'hips': {'XS': 88, 'S': 92, 'M': 96, 'L': 102, 'XL': 108},
    };
    
    _productMeasurements['pants'] = {
      'waist': {'XS': 62, 'S': 66, 'M': 70, 'L': 76, 'XL': 82},
      'hips': {'XS': 88, 'S': 92, 'M': 96, 'L': 102, 'XL': 108},
      'inseam': {'XS': 68, 'S': 70, 'M': 72, 'L': 74, 'XL': 76},
    };
  }
  
  FittingParameters _calculateFittingParameters(
    Map<String, double> avatarMeasurements,
    Map<String, double> productMeasurements,
    ProductCategory category,
  ) {
    final scaling = calculateSizeScaling(
      avatarMeasurements: avatarMeasurements,
      productMeasurements: productMeasurements,
      category: category,
    );
    
    // Choose fitting algorithm based on category and complexity
    String algorithmId;
    switch (category) {
      case ProductCategory.dresses:
        algorithmId = 'ai_optimized';
        break;
      case ProductCategory.outerwear:
        algorithmId = 'physics_based';
        break;
      case ProductCategory.activewear:
        algorithmId = 'advanced_spline';
        break;
      default:
        algorithmId = 'basic_scaling';
    }
    
    final algorithm = _fittingAlgorithms[algorithmId]!;
    
    return FittingParameters(
      scalingFactors: scaling,
      fittingAlgorithm: algorithm,
      adjustPoints: _calculateAdjustmentPoints(category),
      constraints: _calculateConstraints(category),
      optimizationWeights: _calculateOptimizationWeights(category),
    );
  }
  
  PhysicsSimulation _getPhysicsConfiguration(ProductCategory category, String productId) {
    final configKey = '${category.toString().toLowerCase()}_${productId.split('_').last}';
    return _physicsConfig[configKey] ?? _getDefaultPhysics(category);
  }
  
  CollisionConfiguration _configureCollisionDetection(
    Map<String, double> avatarMeasurements,
    ProductCategory category,
    FittingParameters fittingParams,
  ) {
    return CollisionConfiguration(
      enabled: true,
      sensitivity: _getCollisionSensitivity(category),
      priority: _getCollisionPriority(category),
      excludedAreas: _getExcludedAreas(category),
      resolutionStrategy: _getResolutionStrategy(category),
    );
  }
  
  MaterialProperties _getMaterialProperties(ProductCategory category, String productId) {
    // Extract material from product ID or use category defaults
    final materialKey = _extractMaterialFromProduct(productId) ?? 
                       _getDefaultMaterialForCategory(category);
    return _materialProperties[materialKey] ?? MaterialProperties.cotton;
  }
  
  FitQualityMetrics _calculateFitQuality(
    FittingParameters fittingParams,
    MaterialProperties materialProps,
  ) {
    final sizeScaling = fittingParams.scalingFactors;
    
    return calculateFitQuality(
      productId: 'temp',
      avatarId: 'temp',
      sizeScaling: sizeScaling,
      materialProps: materialProps,
    );
  }
  
  double _calculateScalingRatio(double avatarValue, double productValue, ProductCategory category) {
    final ratio = avatarValue / productValue;
    
    // Apply category-specific constraints
    switch (category) {
      case ProductCategory.activewear:
        return math.min(ratio * 1.1, 1.5); // Allow more stretch for activewear
      case ProductCategory.outerwear:
        return math.min(ratio * 1.05, 1.3); // Slight allowance for outer layers
      case ProductCategory.formal:
        return math.min(ratio * 1.02, 1.15); // Tight fit for formal wear
      default:
        return math.min(ratio * 1.08, 1.25); // Standard allowance
    }
  }
  
  double _calculateArmScaling(Map<String, double> avatar, Map<String, double> product) {
    final armLengthRatio = (avatar['arm_length'] ?? 60) / (product['arm_length'] ?? 60);
    return math.min(armLengthRatio * 1.05, 1.2);
  }
  
  double _calculateInseamScaling(Map<String, double> avatar, Map<String, double> product) {
    final inseamRatio = (avatar['inseam'] ?? 75) / (product['inseam'] ?? 75);
    return math.min(inseamRatio * 1.03, 1.1);
  }
  
  double _calculateThighScaling(Map<String, double> avatar, Map<String, double> product) {
    final thighRatio = (avatar['thigh'] ?? 55) / (product['thigh'] ?? 55);
    return math.min(thighRatio * 1.08, 1.25);
  }
  
  double _calculateTorsoScaling(Map<String, double> avatar, Map<String, double> product) {
    final torsoRatio = (avatar['torso_length'] ?? 40) / (product['torso_length'] ?? 40);
    return math.min(torsoRatio * 1.05, 1.15);
  }
  
  void _applyRealisticConstraints(Map<String, double> scaling, ProductCategory category) {
    // Ensure realistic scaling bounds
    for (final entry in scaling.entries) {
      switch (category) {
        case ProductCategory.activewear:
          scaling[entry.key] = entry.value.clamp(0.8, 1.8);
          break;
        case ProductCategory.outerwear:
          scaling[entry.key] = entry.value.clamp(0.9, 1.3);
          break;
        default:
          scaling[entry.key] = entry.value.clamp(0.85, 1.25);
      }
    }
  }
  
  Map<String, double> _getAvatarMeasurements(String avatarId, AvatarType avatarType) {
    final gender = _getGenderFromAvatarType(avatarType);
    final build = _getBuildFromAvatarType(avatarType);
    
    return _bodyMeasurements[gender]?[build] ?? _bodyMeasurements['regular']!['regular']!;
  }
  
  Map<String, double> _getProductMeasurements(String productId, ProductCategory category, String size) {
    final categoryKey = _getCategoryKey(category);
    final measurements = _productMeasurements[categoryKey] ?? {};
    
    final result = <String, double>{};
    for (final measurementType in measurements.keys) {
      final sizeData = measurements[measurementType] ?? {};
      result[measurementType] = sizeData[size] ?? sizeData['M'] ?? 0.0;
    }
    
    return result;
  }
  
  String _getGenderFromAvatarType(AvatarType avatarType) {
    if (avatarType.toString().contains('Male')) return 'male';
    return 'female';
  }
  
  String _getBuildFromAvatarType(AvatarType avatarType) {
    final typeStr = avatarType.toString().toLowerCase();
    if (typeStr.contains('slim')) return 'slim';
    if (typeStr.contains('athletic')) return 'athletic';
    if (typeStr.contains('muscular')) return 'muscular';
    if (typeStr.contains('tall')) return 'regular';
    if (typeStr.contains('petite')) return 'petite';
    if (typeStr.contains('plussize')) return 'plussize';
    return 'regular';
  }
  
  String _getCategoryKey(ProductCategory category) {
    switch (category) {
      case ProductCategory.tops:
      case ProductCategory.dresses:
        return 'tops';
      case ProductCategory.pants:
        return 'pants';
      default:
        return 'tops';
    }
  }
  
  String? _extractMaterialFromProduct(String productId) {
    final parts = productId.toLowerCase().split('_');
    for (final part in parts) {
      if (_materialProperties.containsKey(part)) {
        return part;
      }
    }
    return null;
  }
  
  String _getDefaultMaterialForCategory(ProductCategory category) {
    switch (category) {
      case ProductCategory.dresses:
        return 'silk';
      case ProductCategory.outerwear:
        return 'wool';
      case ProductCategory.activewear:
        return 'spandex';
      default:
        return 'cotton';
    }
  }
  
  List<AdjustmentPoint> _calculateAdjustmentPoints(ProductCategory category) {
    final points = <AdjustmentPoint>[];
    
    // Common adjustment points
    points.add(AdjustmentPoint(name: 'shoulders', weight: 1.0));
    points.add(AdjustmentPoint(name: 'waist', weight: 1.0));
    points.add(AdjustmentPoint(name: 'hips', weight: 1.0));
    
    // Category-specific points
    if (category == ProductCategory.dresses) {
      points.add(AdjustmentPoint(name: 'bust', weight: 1.2));
      points.add(AdjustmentPoint(name: 'neckline', weight: 0.8));
    } else if (category == ProductCategory.outerwear) {
      points.add(AdjustmentPoint(name: 'armholes', weight: 1.1));
      points.add(AdjustmentPoint(name: 'sleeves', weight: 1.0));
    }
    
    return points;
  }
  
  Map<String, double> _calculateConstraints(ProductCategory category) {
    switch (category) {
      case ProductCategory.activewear:
        return {'max_stretch': 1.8, 'compression': 0.9, 'flexibility': 0.8};
      case ProductCategory.outerwear:
        return {'max_stretch': 1.1, 'compression': 0.3, 'flexibility': 0.4};
      default:
        return {'max_stretch': 1.3, 'compression': 0.6, 'flexibility': 0.6};
    }
  }
  
  Map<String, double> _calculateOptimizationWeights(ProductCategory category) {
    switch (category) {
      case ProductCategory.formal:
        return {'appearance': 0.6, 'comfort': 0.2, 'mobility': 0.2};
      case ProductCategory.activewear:
        return {'mobility': 0.5, 'comfort': 0.3, 'appearance': 0.2};
      default:
        return {'appearance': 0.4, 'comfort': 0.4, 'mobility': 0.2};
    }
  }
  
  PhysicsSimulation _getDefaultPhysics(ProductCategory category) {
    return PhysicsSimulation(
      gravityInfluence: 0.8,
      windResistance: 0.6,
      stretchLimit: 1.3,
      compressionResistance: 0.6,
      surfaceFriction: 0.5,
      collisionThreshold: 0.03,
    );
  }
  
  double _getCollisionSensitivity(ProductCategory category) {
    switch (category) {
      case ProductCategory.outerwear:
        return 0.02;
      case ProductCategory.activewear:
        return 0.01;
      default:
        return 0.03;
    }
  }
  
  int _getCollisionPriority(ProductCategory category) {
    switch (category) {
      case ProductCategory.outerwear:
        return 1;
      case ProductCategory.activewear:
        return 2;
      default:
        return 3;
    }
  }
  
  List<String> _getExcludedAreas(ProductCategory category) {
    switch (category) {
      case ProductCategory.dresses:
        return ['neckline', 'armholes'];
      case ProductCategory.outerwear:
        return ['pockets', 'lapels'];
      default:
        return [];
    }
  }
  
  CollisionResolutionStrategy _getResolutionStrategy(ProductCategory category) {
    switch (category) {
      case ProductCategory.activewear:
        return CollisionResolutionStrategy.elastic_deformation;
      case ProductCategory.outerwear:
        return CollisionResolutionStrategy.reposition;
      default:
        return CollisionResolutionStrategy.blend;
    }
  }
  
  MovementResponse _simulateMovementResponse(
    String action,
    MaterialProperties materialProps,
    PhysicsSimulation physicsConfig,
    Map<String, double> bodyMeasurements,
  ) {
    final response = MovementResponse();
    
    switch (action) {
      case 'walking':
        response.fabricMovement = 0.3 * materialProps.stretchFactor;
        response.wrinkleIntensity = 0.2;
        break;
      case 'running':
        response.fabricMovement = 0.7 * materialProps.stretchFactor;
        response.wrinkleIntensity = 0.4;
        break;
      case 'sitting':
        response.fabricMovement = 0.5 * materialProps.stretchFactor;
        response.wrinkleIntensity = 0.6;
        break;
      case 'reaching':
        response.fabricMovement = 0.4 * materialProps.stretchFactor;
        response.wrinkleIntensity = 0.3;
        break;
    }
    
    response.returnToShape = materialProps.stiffness;
    response.dampingEffect = materialProps.damping;
    
    return response;
  }
  
  WrinklePattern _calculateWrinklePattern(
    MaterialProperties materialProps,
    PhysicsSimulation physicsConfig,
    Map<String, double> bodyMeasurements,
  ) {
    return WrinklePattern(
      intensity: (1.0 - materialProps.wrinkleResistance) * physicsConfig.gravityInfluence,
      frequency: materialProps.stiffness * 2.0,
      direction: 'vertical',
      affectedAreas: _getWrinkleAffectedAreas(materialProps),
    );
  }
  
  List<String> _getWrinkleAffectedAreas(MaterialProperties materialProps) {
    if (materialProps.wrinkleResistance > 0.8) return [];
    if (materialProps.wrinkleResistance > 0.5) return ['knees', 'elbows'];
    return ['knees', 'elbows', 'armpits', 'waist'];
  }
  
  StretchSimulation _simulateStretching(
    MaterialProperties materialProps,
    PhysicsSimulation physicsConfig,
    Map<String, double> bodyMeasurements,
  ) {
    return StretchSimulation(
      maxStretch: materialProps.stretchFactor * physicsConfig.stretchLimit,
      recoveryTime: Duration(milliseconds: (1000 / materialProps.stiffness).round()),
      permanentDeformation: 0.0,
      elasticity: materialProps.stretchFactor,
    );
  }
  
  double _calculateComfortScore(Map<String, double> sizeScaling, MaterialProperties materialProps) {
    double score = 1.0;
    
    // Penalize excessive scaling
    for (final value in sizeScaling.values) {
      if (value > 1.3) score -= 0.2;
      else if (value > 1.15) score -= 0.1;
    }
    
    // Reward breathable materials
    score += materialProps.breathability * 0.1;
    
    return score.clamp(0.0, 1.0);
  }
  
  double _calculateAppearanceScore(Map<String, double> sizeScaling) {
    double score = 1.0;
    
    // Reward well-fitted clothing
    for (final value in sizeScaling.values) {
      if (value < 0.9 || value > 1.25) score -= 0.2;
      else if (value < 0.95 || value > 1.15) score -= 0.1;
    }
    
    return score.clamp(0.0, 1.0);
  }
  
  double _calculateMobilityScore(Map<String, double> sizeScaling, MaterialProperties materialProps) {
    double score = materialProps.stretchFactor / 1.5; // Base stretch score
    
    // Consider sizing impact on mobility
    for (final value in sizeScaling.values) {
      if (value > 1.2) score -= 0.15;
      else if (value < 0.95) score -= 0.1;
    }
    
    return score.clamp(0.0, 1.0);
  }
  
  double _calculateRealismScore(Map<String, double> sizeScaling, MaterialProperties materialProps) {
    double score = 0.8; // Base realism
    
    // Check for unrealistic combinations
    final avgScaling = sizeScaling.values.reduce((a, b) => a + b) / sizeScaling.length;
    if (avgScaling > 1.3 || avgScaling < 0.85) score -= 0.3;
    
    // Consider material realism
    if (materialProps.stretchFactor > 1.5 && avgScaling < 1.1) score += 0.1;
    
    return score.clamp(0.0, 1.0);
  }
  
  List<String> _generateFitRecommendations(
    Map<String, double> sizeScaling,
    MaterialProperties materialProps,
  ) {
    final recommendations = <String>[];
    
    for (final entry in sizeScaling.entries) {
      if (entry.value > 1.25) {
        recommendations.add('Consider a larger size for ${entry.key}');
      } else if (entry.value < 0.9) {
        recommendations.add('Consider a smaller size for ${entry.key}');
      }
    }
    
    if (materialProps.breathability < 0.6 && materialProps.name != 'Silk') {
      recommendations.add('This material may not be ideal for hot weather');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Great fit! This should be comfortable and look good.');
    }
    
    return recommendations;
  }
  
  @override
  void dispose() {
    _fittingAlgorithms.clear();
    _materialProperties.clear();
    _physicsConfig.clear();
    _fitQualityCache.clear();
    super.dispose();
  }
}

/// Main try-on configuration class
class TryOnConfiguration {
  final String productId;
  final String avatarId;
  final AvatarType avatarType;
  final ProductCategory category;
  final String size;
  final FittingParameters fittingParameters;
  final PhysicsSimulation physicsSimulation;
  final CollisionConfiguration collisionDetection;
  final MaterialProperties materialProperties;
  final FitQualityMetrics fitQuality;
  final Map<String, dynamic> customSettings;
  
  const TryOnConfiguration({
    required this.productId,
    required this.avatarId,
    required this.avatarType,
    required this.category,
    required this.size,
    required this.fittingParameters,
    required this.physicsSimulation,
    required this.collisionDetection,
    required this.materialProperties,
    required this.fitQuality,
    required this.customSettings,
  });
}

/// Fitting algorithm definition
class FittingAlgorithm {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;
  final double accuracy;
  
  const FittingAlgorithm({
    required this.name,
    required this.description,
    required this.parameters,
    required this.accuracy,
  });
}

/// Fitting parameters
class FittingParameters {
  final Map<String, double> scalingFactors;
  final FittingAlgorithm fittingAlgorithm;
  final List<AdjustmentPoint> adjustPoints;
  final Map<String, double> constraints;
  final Map<String, double> optimizationWeights;
  
  const FittingParameters({
    required this.scalingFactors,
    required this.fittingAlgorithm,
    required this.adjustPoints,
    required this.constraints,
    required this.optimizationWeights,
  });
}

/// Adjustment point for fitting
class AdjustmentPoint {
  final String name;
  final double weight;
  
  const AdjustmentPoint({required this.name, required this.weight});
}

/// Material properties
class MaterialProperties {
  final String name;
  final double stiffness;
  final double damping;
  final double stretchFactor;
  final double wrinkleResistance;
  final String texture;
  final double colorRetention;
  final double breathability;
  final CareLevel careLevel;
  
  // Common materials
  static MaterialProperties get cotton => MaterialProperties(
    name: 'Cotton',
    stiffness: 0.6,
    damping: 0.4,
    stretchFactor: 1.1,
    wrinkleResistance: 0.7,
    texture: 'cotton_weave',
    colorRetention: 0.8,
    breathability: 0.9,
    careLevel: CareLevel.medium,
  );
  
  static MaterialProperties get silk => MaterialProperties(
    name: 'Silk',
    stiffness: 0.2,
    damping: 0.8,
    stretchFactor: 1.05,
    wrinkleResistance: 0.3,
    texture: 'smooth_satin',
    colorRetention: 0.9,
    breathability: 0.6,
    careLevel: CareLevel.high,
  );
  
  static MaterialProperties get wool => MaterialProperties(
    name: 'Wool',
    stiffness: 0.8,
    damping: 0.6,
    stretchFactor: 1.15,
    wrinkleResistance: 0.9,
    texture: 'fiber_knit',
    colorRetention: 0.7,
    breathability: 0.5,
    careLevel: CareLevel.medium,
  );
  
  static MaterialProperties get spandex => MaterialProperties(
    name: 'Spandex',
    stiffness: 0.1,
    damping: 0.1,
    stretchFactor: 1.5,
    wrinkleResistance: 1.0,
    texture: 'elastic_knit',
    colorRetention: 0.8,
    breathability: 0.7,
    careLevel: CareLevel.low,
  );
  
  const MaterialProperties({
    required this.name,
    required this.stiffness,
    required this.damping,
    required this.stretchFactor,
    required this.wrinkleResistance,
    required this.texture,
    required this.colorRetention,
    required this.breathability,
    required this.careLevel,
  });
}

/// Care level enum
enum CareLevel {
  low,    // Easy care
  medium, // Moderate care
  high,   // High maintenance
}

/// Physics simulation configuration
class PhysicsSimulation {
  final double gravityInfluence;
  final double windResistance;
  final double stretchLimit;
  final double compressionResistance;
  final double surfaceFriction;
  final double collisionThreshold;
  
  const PhysicsSimulation({
    required this.gravityInfluence,
    required this.windResistance,
    required this.stretchLimit,
    required this.compressionResistance,
    required this.surfaceFriction,
    required this.collisionThreshold,
  });
}

/// Collision detection configuration
class CollisionConfiguration {
  final bool enabled;
  final double sensitivity;
  final int priority;
  final List<String> excludedAreas;
  final CollisionResolutionStrategy resolutionStrategy;
  
  const CollisionConfiguration({
    required this.enabled,
    required this.sensitivity,
    required this.priority,
    required this.excludedAreas,
    required this.resolutionStrategy,
  });
}

/// Collision resolution strategies
enum CollisionResolutionStrategy {
  blend,              // Blend both items
  reposition,         // Reposition items to avoid collision
  elastic_deformation, // Allow elastic deformation
}

/// Fabric behavior simulation
class FabricBehavior {
  final Map<String, MovementResponse> movementResponses = {};
  WrinklePattern? wrinklePattern;
  StretchSimulation? stretchSimulation;
}

/// Response to specific movements
class MovementResponse {
  double fabricMovement = 0.0;
  double wrinkleIntensity = 0.0;
  double returnToShape = 0.0;
  double dampingEffect = 0.0;
}

/// Wrinkle pattern simulation
class WrinklePattern {
  final double intensity;
  final double frequency;
  final String direction;
  final List<String> affectedAreas;
  
  const WrinklePattern({
    required this.intensity,
    required this.frequency,
    required this.direction,
    required this.affectedAreas,
  });
}

/// Stretch simulation
class StretchSimulation {
  final double maxStretch;
  final Duration recoveryTime;
  final double permanentDeformation;
  final double elasticity;
  
  const StretchSimulation({
    required this.maxStretch,
    required this.recoveryTime,
    required this.permanentDeformation,
    required this.elasticity,
  });
}

/// Fit quality metrics
class FitQualityMetrics {
  final double overallScore;
  final double comfortScore;
  final double appearanceScore;
  final double mobilityScore;
  final double realismScore;
  final List<String> recommendations;
  
  const FitQualityMetrics({
    required this.overallScore,
    required this.comfortScore,
    required this.appearanceScore,
    required this.mobilityScore,
    required this.realismScore,
    required this.recommendations,
  });
}

/// Collision detection system
class CollisionDetector {
  CollisionResult detectCollisions({
    required String primaryProductId,
    required List<String> secondaryProductIds,
    required Map<String, dynamic> bodyStructure,
  }) {
    // Simulate collision detection
    final detectedCollisions = <String>[];
    
    for (final secondaryId in secondaryProductIds) {
      if (_shouldCollide(primaryProductId, secondaryId)) {
        detectedCollisions.add(secondaryId);
      }
    }
    
    return CollisionResult(
      hasCollisions: detectedCollisions.isNotEmpty,
      collisions: detectedCollisions,
      resolutionSuggestions: _getResolutionSuggestions(detectedCollisions),
    );
  }
  
  bool _shouldCollide(String primaryId, String secondaryId) {
    // Simulate collision detection logic
    final primaryType = primaryId.split('_')[0];
    final secondaryType = secondaryId.split('_')[0];
    
    // Layering rules
    if ((primaryType == 'jacket' && secondaryType == 'shirt') ||
        (primaryType == 'coat' && (secondaryType == 'jacket' || secondaryType == 'shirt')) ||
        (primaryType == 'vest' && secondaryType == 'shirt')) {
      return true; // These should not "collide" - they're meant to layer
    }
    
    return false; // Default: no collision
  }
  
  List<String> _getResolutionSuggestions(List<String> collisions) {
    if (collisions.isEmpty) return ['No collision detected'];
    
    return [
      'Adjust layering order',
      'Modify fit parameters',
      'Consider alternative sizing',
      'Apply collision resolution algorithm',
    ];
  }
}

/// Collision detection result
class CollisionResult {
  final bool hasCollisions;
  final List<String> collisions;
  final List<String> resolutionSuggestions;
  
  const CollisionResult({
    required this.hasCollisions,
    required this.collisions,
    required this.resolutionSuggestions,
  });
}