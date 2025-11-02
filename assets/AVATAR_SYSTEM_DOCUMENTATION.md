# Mock Avatar System Documentation

## Overview

The Mock Avatar System provides a comprehensive 3D avatar management solution with robust fallback mechanisms, offline support, and extensive customization options. This system is designed for mobile applications with limited bandwidth and storage constraints.

## Features

### 🎯 Core Features
- **3D Avatar Management**: Complete CRUD operations for 3D avatars
- **Comprehensive Fallback System**: Multiple layers of fallbacks for failed loads
- **Offline Mode**: Full functionality without internet connection
- **Asset Optimization**: Mobile-optimized models with compression
- **Cache Management**: Intelligent caching with size limits and expiration
- **User Preferences**: Persistent settings and customization

### 🔧 Technical Features
- **Mock API**: Realistic API simulation with loading delays
- **SharedPreferences Integration**: Local storage for persistence
- **Stream-based Updates**: Reactive UI updates
- **Error Recovery**: Automatic retry mechanisms
- **Asset Validation**: File integrity checking
- **Performance Monitoring**: Cache statistics and error logging

## Architecture

```
├── lib/src/
│   ├── models/
│   │   └── avatar_model.dart         # Enhanced avatar data models
│   ├── services/
│   │   ├── api_service.dart          # Mock API endpoints
│   │   ├── avatar_service.dart       # Avatar persistence & management
│   │   └── avatar_fallback_service.dart # Fallback & error handling
│   ├── providers/
│   │   └── avatar_provider.dart      # State management (Riverpod)
│   └── ...
└── digital_twin_fashion/assets/avatars/
    ├── models/        # 14 diverse avatar GLB files
    ├── thumbnails/    # Preview images
    ├── fallbacks/     # Placeholder models
    ├── compressed/    # Compressed versions
    └── avatar_catalog.json # Asset index
```

## Quick Start

### 1. Basic Avatar Loading

```dart
// Using Riverpod (recommended)
final avatarNotifier = ref.read(avatarProvider.notifier);
await avatarNotifier.loadAvatar('slim_male_160');

// Using service directly
final fallbackService = AvatarFallbackService();
final result = await fallbackService.loadAvatarWithFallback('slim_male_160');

if (result.isSuccess) {
  print('Avatar loaded: ${result.avatar?.name}');
  print('Source: ${result.source}');
  if (result.fallbackModel != null) {
    print('Used fallback: ${result.fallbackModel?.name}');
  }
}
```

### 2. Avatar Management

```dart
// Set current avatar
await avatarNotifier.setCurrentAvatar('regular_female_168');

// Toggle favorite
await avatarNotifier.toggleFavorite('athletic_male_180');

// Create new avatar
final newAvatar = await avatarNotifier.createAvatar(
  name: 'My Custom Avatar',
  measurements: AvatarMeasurements(
    height: 175,
    weight: 70,
    chest: 95,
    waist: 80,
    hips: 95,
    shoulders: 45,
    arms: 70,
    legs: 85,
  ),
  attributes: AvatarAttributes(
    bodyType: 'Regular',
    ethnicity: 'Mixed',
    skinTone: 'Medium',
    hairColor: 'Brown',
    hairStyle: 'Short',
    eyeColor: 'Brown',
    gender: 'Non-binary',
    age: 25,
  ),
);
```

### 3. Fallback System Usage

```dart
// Load with comprehensive fallback
final result = await fallbackService.loadAvatarWithFallback(
  'some_avatar_id',
  options: AvatarLoadOptions(
    useCache: true,
    checkFileSize: true,
    enableRetry: true,
  ),
);

// Retry failed load
final retryResult = await fallbackService.retryLoadAvatar(
  'failed_avatar_id',
  maxRetries: 3,
);

// Check offline availability
bool isAvailable = fallbackService.isAvatarAvailableOffline('avatar_id');

// Preload avatars for smooth transitions
final loaded = await fallbackService.preloadAvatars([
  'slim_male_160',
  'regular_female_168',
  'athletic_male_180',
]);
```

### 4. Cache Management

```dart
// Get cache statistics
final stats = fallbackService.getCacheStats();
print('Cache entries: ${stats.totalEntries}');
print('Cache size: ${stats.totalSizeFormatted}');
print('Valid entries: ${stats.validEntries}');

// Clear expired cache
fallbackService.clearExpiredCache();

// Monitor cache during development
final errorHistory = fallbackService.getErrorHistory();
errorHistory.forEach((log) {
  print('${log.timestamp}: ${log.avatarId} - ${log.error}');
});
```

## Avatar Types & Specifications

### Sample Avatars Generated

| Avatar ID | Name | Height | Body Type | Gender | Category |
|-----------|------|--------|-----------|---------|----------|
| slim_male_160 | Slim Male 160cm | 160cm | Slim | Male | Body-focused |
| slim_female_162 | Slim Female 162cm | 162cm | Slim | Female | Body-focused |
| regular_male_175 | Regular Male 175cm | 175cm | Regular | Male | Standard |
| regular_female_168 | Regular Female 168cm | 168cm | Regular | Female | Standard |
| athletic_male_180 | Athletic Male 180cm | 180cm | Athletic | Male | Fitness |
| athletic_female_170 | Athletic Female 170cm | 170cm | Athletic | Female | Fitness |
| plussize_male_172 | Plus Size Male 172cm | 172cm | PlusSize | Male | Inclusive |
| plussize_female_165 | Plus Size Female 165cm | 165cm | PlusSize | Female | Inclusive |
| tall_male_185 | Tall Male 185cm | 185cm | Regular | Male | Height variation |
| tall_female_178 | Tall Female 178cm | 178cm | Regular | Female | Height variation |
| petite_male_155 | Petite Male 155cm | 155cm | Slim | Male | Height variation |
| petite_female_152 | Petite Female 152cm | 152cm | Slim | Female | Height variation |
| muscular_male_178 | Muscular Male 178cm | 178cm | Athletic | Male | Fitness |
| muscular_female_172 | Muscular Female 172cm | 172cm | Athletic | Female | Fitness |

### Fallback Models

| Model ID | Body Type | Purpose |
|----------|-----------|---------|
| placeholder_slim | Slim | Generic slim body placeholder |
| placeholder_regular | Regular | Generic regular body placeholder |
| placeholder_athletic | Athletic | Generic athletic body placeholder |
| placeholder_plussize | PlusSize | Generic plus size placeholder |

## API Endpoints

### Mock API Service

The `ApiService` provides comprehensive mock endpoints:

```dart
// Get avatar by ID
final response = await apiService.getAvatar('slim_male_160');

// Get paginated avatars
final listResponse = await apiService.getAvatars(
  page: 1,
  perPage: 20,
  search: 'slim',
  bodyType: 'Slim',
);

// Create new avatar
final newAvatar = await apiService.createAvatar({
  'name': 'Custom Avatar',
  'measurements': measurements.toJson(),
  'attributes': attributes.toJson(),
});

// Update avatar
final updated = await apiService.updateAvatar('avatar_id', updates);

// Delete avatar
final deleted = await apiService.deleteAvatar('avatar_id');

// Get recommendations
final recommendations = await apiService.getRecommendedAvatars(
  bodyType: 'Athletic',
  limit: 5,
);
```

### Loading States

The system provides detailed loading states:

```dart
enum LoadingState {
  idle,        // No operation in progress
  loading,     // Loading avatar data
  saving,      // Saving/updating avatar
  deleting,    // Deleting avatar
  error,       // Error state
}
```

### Fallback Reasons

When avatars fail to load, the system provides detailed fallback reasons:

```dart
enum FallbackReason {
  fileNotFound,      // GLB file not found
  fileTooLarge,      // File exceeds size limits
  invalidModel,      // Invalid GLB structure
  loadError,         // General loading error
  fallbackFailed,    // Fallback model failed
  placeholderFailed, // 2D placeholder failed
  maxRetriesExceeded // Retry limit exceeded
}
```

## Performance & Optimization

### Cache Management

- **Automatic Expiration**: Cached avatars expire after 24 hours
- **Size Limits**: Maximum cache size of 50MB
- **LRU Eviction**: Least recently used avatars are removed first
- **Preloading**: Proactive loading for smooth UI transitions

### Asset Optimization

- **Mobile-First**: All models optimized for mobile devices
- **Compression**: Available compressed versions (75% size reduction)
- **Multiple Formats**: Support for GLB and GLTF
- **Texture Optimization**: Efficient texture formats

### Error Handling

- **Graceful Degradation**: 3D → Fallback 3D → 2D → Error
- **Retry Logic**: Exponential backoff for failed requests
- **Offline Support**: Full functionality without internet
- **Error Logging**: Comprehensive error tracking for debugging

## Configuration

### Settings

```dart
final settings = AvatarSettings(
  autoSave: true,                    // Auto-save avatar changes
  enableNotifications: true,         // Show loading notifications
  offlineModePreferred: false,       // Prefer offline when possible
  cacheSizeLimit: 500,              // Cache size limit in MB
  qualityPreference: 'Medium',       // Quality: Low, Medium, High
  enableAnalytics: false,            // Track usage analytics
  cacheExpiry: Duration(hours: 24),  // Cache expiration time
);
```

### Provider Configuration

```dart
// Initialize with SharedPreferences
final prefs = await SharedPreferences.getInstance();
final avatarNotifier = AvatarNotifier(prefs: prefs);

// Access streams for reactive UI
avatarNotifier.avatarUpdatedStream.listen((avatar) {
  // Handle avatar updates
});

avatarNotifier.loadingStream.listen((state) {
  // Handle loading state changes
});

avatarNotifier.errorStream.listen((error) {
  // Handle errors
});
```

## File Structure

```
assets/avatars/
├── models/                    # Primary avatar GLB files
│   ├── slim_male_160_model.glb
│   ├── regular_female_168_model.glb
│   └── ... (14 total avatars)
│   └── *_metadata.json       # Individual avatar metadata
├── thumbnails/               # Preview images
│   ├── slim_male_160_thumb.png
│   └── ... (14 thumbnails)
├── fallbacks/                # Fallback 3D models
│   ├── placeholder_slim.glb
│   ├── placeholder_regular.glb
│   ├── placeholder_athletic.glb
│   ├── placeholder_plussize.glb
│   └── placeholder_2d.png    # 2D fallback image
├── compressed/               # Compressed versions
│   ├── *_model_compressed.glb
│   └── *_model_compressed_info.json
└── avatar_catalog.json       # Complete asset index
```

## Best Practices

### 1. Avatar Loading
- Always use `loadAvatarWithFallback()` for production
- Preload frequently used avatars
- Monitor cache statistics in development
- Use offline mode for better performance

### 2. Error Handling
- Implement proper error UI states
- Provide user feedback for loading failures
- Log errors for debugging
- Offer retry options to users

### 3. Performance
- Clear expired cache regularly
- Monitor memory usage
- Use appropriate quality settings
- Implement pagination for large avatar lists

### 4. User Experience
- Provide loading indicators
- Show fallback usage to users
- Implement smooth transitions
- Handle offline scenarios gracefully

## Troubleshooting

### Common Issues

1. **Avatar won't load**
   - Check file paths and permissions
   - Verify GLB file integrity
   - Review fallback service logs

2. **High memory usage**
   - Clear expired cache entries
   - Reduce cache size limits
   - Use compressed models

3. **Slow loading**
   - Preload avatars in background
   - Use appropriate quality settings
   - Check network connectivity

4. **Missing fallback models**
   - Verify fallback assets exist
   - Check file permissions
   - Review error logs

### Debug Mode

Enable debug logging:

```dart
// Enable detailed logging
AvatarService.enableDebugLogging();
AvatarFallbackService.enableDebugLogging();

// Check error history
final errors = avatarProvider.getErrorHistory();
for (final error in errors) {
  print('${error.timestamp}: ${error.avatarId} - ${error.operation}: ${error.error}');
}
```

## Future Enhancements

### Planned Features
- **Advanced Caching**: Redis-style caching with clustering
- **Model Validation**: AI-powered GLB validation
- **Dynamic Compression**: Real-time model optimization
- **Social Features**: Avatar sharing and collaboration
- **Analytics**: Usage patterns and optimization insights

### API Improvements
- **GraphQL Support**: Flexible querying
- **WebSocket Updates**: Real-time avatar synchronization
- **CDN Integration**: Global content delivery
- **Batch Operations**: Efficient bulk operations

---

*This documentation covers the comprehensive Mock Avatar System v1.0. For additional support or feature requests, please refer to the project repository or contact the development team.*
