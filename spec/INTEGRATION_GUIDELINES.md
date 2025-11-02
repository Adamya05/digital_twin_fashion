# API Integration Guidelines

This document provides comprehensive guidelines for integrating the Virtual Try-On API into Flutter applications, including client libraries, error handling, offline support, and performance optimization.

## Table of Contents

- [Flutter Integration Overview](#flutter-integration-overview)
- [API Client Library](#api-client-library)
- [Authentication Integration](#authentication-integration)
- [Error Handling Patterns](#error-handling-patterns)
- [Offline Mode & Caching](#offline-mode--caching)
- [Performance Optimization](#performance-optimization)
- [State Management](#state-management)
- [Monitoring & Analytics](#monitoring--analytics)
- [Testing Strategies](#testing-strategies)

## Flutter Integration Overview

### Project Setup

#### Dependencies

Add required dependencies to `pubspec.yaml`:

```yaml
dependencies:
  # HTTP client
  dio: ^5.4.0
  dio_interceptor: ^1.0.0
  
  # State management
  provider: ^6.1.1
  bloc: ^8.1.2
  flutter_bloc: ^8.1.3
  
  # Local storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Network connectivity
  connectivity_plus: ^5.0.2
  
  # Image handling
  cached_network_image: ^3.3.0
  flutter_cache_manager: ^3.3.1
  
  # Authentication
  local_auth: ^2.1.7
  biometric_storage: ^4.0.0
  
  # Utils
  uuid: ^4.2.1
  intl: ^0.18.1

dev_dependencies:
  flutter_test:
  mockito: ^5.4.3
  build_runner: ^2.4.7
  hive_generator: ^2.0.1
```

#### Project Structure

```
lib/
├── core/
│   ├── api/
│   │   ├── client.dart
│   │   ├── endpoints/
│   │   ├── interceptors/
│   │   └── models/
│   ├── config/
│   │   ├── app_config.dart
│   │   └── api_config.dart
│   ├── constants/
│   │   ├── api_endpoints.dart
│   │   └── app_constants.dart
│   ├── utils/
│   │   ├── network_utils.dart
│   │   ├── cache_manager.dart
│   │   └── error_handler.dart
│   └── services/
│       ├── auth_service.dart
│       ├── storage_service.dart
│       └── notification_service.dart
├── features/
│   ├── auth/
│   ├── avatar/
│   ├── products/
│   ├── cart/
│   ├── orders/
│   ├── profile/
│   └── closet/
└── main.dart
```

### Environment Configuration

#### API Configuration

```dart
// lib/core/config/api_config.dart
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.tryon.com/v1',
  );
  
  static const String stagingUrl = 'https://staging-api.tryon.com/v1';
  static const String devUrl = 'https://dev-api.tryon.com/v1';
  
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 60);
  
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
}

// lib/core/config/app_config.dart
class AppConfig {
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  static const bool enableDebugLogs = bool.fromEnvironment('DEBUG_LOGS', defaultValue: false);
  static const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'staging');
}
```

#### Build Configuration

```dart
// dart define API_BASE_URL=https://api.tryon.com/v1
// dart define PRODUCTION=true
// dart define DEBUG_LOGS=false

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider<ApiClient>(create: (_) => ApiClient()),
        Provider<CacheManager>(create: (_) => CacheManager()),
      ],
      child: MaterialApp(
        title: 'Virtual Try-On',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: AuthWrapper(),
      ),
    );
  }
}
```

## API Client Library

### HTTP Client Setup

#### Dio Configuration

```dart
// lib/core/api/client.dart
class ApiClient {
  late final Dio _dio;
  late final TokenManager _tokenManager;
  late final CacheManager _cacheManager;
  late final NetworkUtils _networkUtils;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'VirtualTryOn/1.0.0',
      },
    ));

    _setupInterceptors();
    _setupErrorHandlers();
  }

  void _setupInterceptors() {
    // Authentication interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenManager.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          // Add request ID for tracing
          options.headers['X-Request-ID'] = const Uuid().v4();
          
          // Add API version
          options.headers['X-API-Version'] = '1.0.0';
          
          handler.next(options);
        },
        onResponse: (response, handler) {
          // Cache response if applicable
          if (_shouldCacheResponse(response.requestOptions)) {
            _cacheManager.cacheResponse(response);
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          // Handle token refresh
          if (error.response?.statusCode == 401) {
            final refreshed = await _tokenManager.refreshToken();
            if (refreshed) {
              // Retry the request with new token
              final token = await _tokenManager.getAccessToken();
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              
              try {
                final response = await _dio.fetch(error.requestOptions);
                handler.resolve(response);
                return;
              } catch (e) {
                // Refresh failed, continue with error
              }
            }
          }
          
          handler.next(error);
        },
      ),
    );

    // Logging interceptor (only in debug)
    if (AppConfig.enableDebugLogs) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => print('[API] $obj'),
      ));
    }

    // Cache interceptor
    _dio.interceptors.add(
      DioCacheInterceptor(options: CacheOptions(
        store: _cacheManager.getHiveStore(),
        maxStale: const Duration(days: 7),
        hitCacheOnErrorExcept: [401, 403],
      )),
    );
  }

  void _setupErrorHandlers() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          final errorHandler = ErrorHandler();
          final appException = errorHandler.handleError(error);
          
          // Log error for monitoring
          _logError(appException, error.requestOptions);
          
          // Notify error state if needed
          _notifyError(appException);
          
          handler.next(error);
        },
      ),
    );
  }

  // Generic GET request
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
    bool forceRefresh = false,
  }) async {
    try {
      if (!await _networkUtils.isConnected()) {
        throw AppException.noInternet();
      }

      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(
          extra: {'force_refresh': forceRefresh},
        ),
      );

      if (fromJson != null) {
        return fromJson(response.data['data']);
      }
      
      return response.data;
    } on DioException catch (e) {
      throw ErrorHandler().handleError(e);
    }
  }

  // Generic POST request
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      if (!await _networkUtils.isConnected()) {
        throw AppException.noInternet();
      }

      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      if (fromJson != null) {
        return fromJson(response.data['data']);
      }
      
      return response.data;
    } on DioException catch (e) {
      throw ErrorHandler().handleError(e);
    }
  }

  // File upload
  Future<T> uploadFile<T>(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      if (!await _networkUtils.isConnected()) {
        throw AppException.noInternet();
      }

      final file = File(filePath);
      final fileName = path.basename(filePath);
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath, filename: fileName),
        ...?data,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );

      if (fromJson != null) {
        return fromJson(response.data['data']);
      }
      
      return response.data;
    } on DioException catch (e) {
      throw ErrorHandler().handleError(e);
    }
  }

  bool _shouldCacheResponse(RequestOptions options) {
    // Cache GET requests for certain endpoints
    return options.method == 'GET' && (
      options.path.contains('/products') ||
      options.path.contains('/avatar') ||
      options.path.contains('/profile')
    );
  }

  void _logError(AppException exception, RequestOptions request) {
    // Implement error logging to monitoring service
    print('[ERROR] ${exception.code}: ${exception.message}');
    print('[REQUEST] ${request.method} ${request.path}');
  }

  void _notifyError(AppException exception) {
    // Implement global error notification
    // This could show a snackbar, dialog, or update error state
  }

  void dispose() {
    _dio.close();
  }
}
```

### Data Models

#### Model Serialization

```dart
// lib/core/api/models/user.dart
part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? avatar;
  final bool emailVerified;
  final bool phoneVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.avatar,
    required this.emailVerified,
    required this.phoneVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? avatar,
    bool? emailVerified,
    bool? phoneVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatar: avatar ?? this.avatar,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Run: flutter packages pub run build_runner build
```

### Endpoint Classes

#### Authentication Endpoints

```dart
// lib/core/api/endpoints/auth_endpoints.dart
class AuthEndpoints {
  final ApiClient _client;

  AuthEndpoints(this._client);

  Future<LoginResponse> login(LoginRequest request) {
    return _client.post(
      '/api/auth/login',
      data: request.toJson(),
      fromJson: (json) => LoginResponse.fromJson(json),
    );
  }

  Future<RegisterResponse> register(RegisterRequest request) {
    return _client.post(
      '/api/auth/register',
      data: request.toJson(),
      fromJson: (json) => RegisterResponse.fromJson(json),
    );
  }

  Future<RefreshTokenResponse> refreshToken(RefreshTokenRequest request) {
    return _client.post(
      '/api/auth/refresh',
      data: request.toJson(),
      fromJson: (json) => RefreshTokenResponse.fromJson(json),
    );
  }

  Future<void> logout() {
    return _client.post('/api/auth/logout');
  }
}

// Request/Response models
@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;
  final bool? rememberMe;

  const LoginRequest({
    required this.email,
    required this.password,
    this.rememberMe,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class LoginResponse {
  final bool success;
  final LoginData data;

  const LoginResponse({
    required this.success,
    required this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => _$LoginResponseFromJson(json);
}

@JsonSerializable()
class LoginData {
  final User user;
  final AuthTokens tokens;

  const LoginData({
    required this.user,
    required this.tokens,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) => _$LoginDataFromJson(json);
}
```

#### Product Endpoints

```dart
// lib/core/api/endpoints/product_endpoints.dart
class ProductEndpoints {
  final ApiClient _client;

  ProductEndpoints(this._client);

  Future<ProductListResponse> getProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? brand,
    double? priceMin,
    double? priceMax,
    List<String>? sizes,
    List<String>? colors,
    String? sortBy,
  }) {
    return _client.get(
      '/api/products',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (category != null) 'category': category,
        if (brand != null) 'brand': brand,
        if (priceMin != null) 'priceMin': priceMin,
        if (priceMax != null) 'priceMax': priceMax,
        if (sizes != null) 'size': sizes,
        if (colors != null) 'color': colors,
        if (sortBy != null) 'sortBy': sortBy,
      },
      fromJson: (json) => ProductListResponse.fromJson(json),
    );
  }

  Future<ProductDetail> getProductDetail(String productId) {
    return _client.get(
      '/api/products/$productId',
      fromJson: (json) => ProductDetail.fromJson(json),
    );
  }

  Future<ProductSearchResponse> searchProducts(
    String query, {
    bool suggest = false,
    int limit = 20,
  }) {
    return _client.get(
      '/api/products/search',
      queryParameters: {
        'q': query,
        'suggest': suggest,
        'limit': limit,
      },
      fromJson: (json) => ProductSearchResponse.fromJson(json),
    );
  }
}
```

## Authentication Integration

### Authentication Provider

```dart
// lib/features/auth/auth_provider.dart
class AuthProvider extends ChangeNotifier {
  final AuthEndpoints _authEndpoints;
  final TokenManager _tokenManager;
  final StorageService _storageService;
  final BiometricService _biometricService;

  User? _user;
  AuthTokens? _tokens;
  bool _isLoading = false;
  AuthState _state = AuthState.initial;

  User? get user => _user;
  AuthTokens? get tokens => _tokens;
  bool get isLoading => _isLoading;
  AuthState get state => _state;
  bool get isAuthenticated => _user != null && _tokens != null;

  AuthProvider(
    this._authEndpoints,
    this._tokenManager,
    this._storageService,
    this._biometricService,
  ) {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check for stored tokens
      final tokens = await _tokenManager.getStoredTokens();
      if (tokens != null) {
        _tokens = tokens;
        
        // Validate token and get user profile
        await _loadUserProfile();
        
        if (_user != null) {
          _state = AuthState.authenticated;
        } else {
          _state = AuthState.unauthenticated;
        }
      } else {
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      _state = AuthState.error;
      _handleAuthError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      _state = AuthState.loading;
      notifyListeners();

      final response = await _authEndpoints.login(
        LoginRequest(email: email, password: password),
      );

      _user = response.data.user;
      _tokens = response.data.tokens;

      // Store tokens securely
      await _tokenManager.storeTokens(_tokens!);
      await _storageService.storeUser(_user!);

      // Check if biometric login is available and enabled
      if (await _biometricService.isAvailable() && 
          await _storageService.isBiometricEnabled()) {
        await _biometricService.storeCredentials(email, password);
      }

      _state = AuthState.authenticated;
    } catch (e) {
      _state = AuthState.error;
      _handleAuthError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(RegisterRequest request) async {
    try {
      _isLoading = true;
      _state = AuthState.loading;
      notifyListeners();

      final response = await _authEndpoints.register(request);

      _user = response.data.user;

      if (response.data.emailVerificationRequired) {
        _state = AuthState.emailVerificationRequired;
      } else {
        _state = AuthState.authenticated;
      }
    } catch (e) {
      _state = AuthState.error;
      _handleAuthError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> biometricLogin() async {
    try {
      final credentials = await _biometricService.getStoredCredentials();
      if (credentials != null) {
        await login(credentials.email, credentials.password);
      }
    } catch (e) {
      _state = AuthState.error;
      _handleAuthError(e);
    }
  }

  Future<void> refreshToken() async {
    try {
      final refreshToken = _tokens?.refreshToken;
      if (refreshToken != null) {
        final response = await _authEndpoints.refreshToken(
          RefreshTokenRequest(refreshToken: refreshToken),
        );

        _tokens = response.data.tokens;
        await _tokenManager.storeTokens(_tokens!);
      }
    } catch (e) {
      await logout();
      _handleAuthError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _authEndpoints.logout();
    } catch (e) {
      // Log error but continue with logout
      print('Logout API call failed: $e');
    }

    // Clear all stored data
    await _tokenManager.clearTokens();
    await _storageService.clearUser();
    await _biometricService.clearStoredCredentials();

    _user = null;
    _tokens = null;
    _state = AuthState.unauthenticated;
    
    notifyListeners();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _getUserProfile();
      _user = profile;
      await _storageService.storeUser(_user!);
    } catch (e) {
      // Token might be invalid
      await logout();
    }
  }

  void _handleAuthError(dynamic error) {
    if (error is AppException) {
      switch (error.code) {
        case 'INVALID_CREDENTIALS':
          _state = AuthState.invalidCredentials;
          break;
        case 'ACCOUNT_LOCKED':
          _state = AuthState.accountLocked;
          break;
        case 'EMAIL_NOT_VERIFIED':
          _state = AuthState.emailVerificationRequired;
          break;
        default:
          _state = AuthState.error;
      }
    } else {
      _state = AuthState.error;
    }
  }
}

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  emailVerificationRequired,
  invalidCredentials,
  accountLocked,
  error,
}
```

### Token Management

```dart
// lib/core/services/token_manager.dart
class TokenManager {
  final StorageService _storageService;
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessTokenExpiryKey = 'access_token_expiry';
  static const String _refreshTokenExpiryKey = 'refresh_token_expiry';

  TokenManager(this._storageService);

  Future<AuthTokens?> getStoredTokens() async {
    final accessToken = await _storageService.getString(_accessTokenKey);
    final refreshToken = await _storageService.getString(_refreshTokenKey);
    final accessTokenExpiry = await _storageService.getString(_accessTokenExpiryKey);
    final refreshTokenExpiry = await _storageService.getString(_refreshTokenExpiryKey);

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    // Check if tokens are expired
    if (accessTokenExpiry != null) {
      final expiry = DateTime.parse(accessTokenExpiry);
      if (DateTime.now().isAfter(expiry)) {
        return null;
      }
    }

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiry: accessTokenExpiry != null ? DateTime.parse(accessTokenExpiry) : null,
      refreshTokenExpiry: refreshTokenExpiry != null ? DateTime.parse(refreshTokenExpiry) : null,
    );
  }

  Future<void> storeTokens(AuthTokens tokens) async {
    await _storageService.setString(_accessTokenKey, tokens.accessToken);
    await _storageService.setString(_refreshTokenKey, tokens.refreshToken);
    
    if (tokens.accessTokenExpiry != null) {
      await _storageService.setString(_accessTokenExpiryKey, tokens.accessTokenExpiry!.toIso8601String());
    }
    
    if (tokens.refreshTokenExpiry != null) {
      await _storageService.setString(_refreshTokenExpiryKey, tokens.refreshTokenExpiry!.toIso8601String());
    }
  }

  Future<String?> getAccessToken() async {
    final tokens = await getStoredTokens();
    return tokens?.accessToken;
  }

  Future<String?> getRefreshToken() async {
    final tokens = await getStoredTokens();
    return tokens?.refreshToken;
  }

  Future<bool> isTokenExpired() async {
    final tokens = await getStoredTokens();
    if (tokens?.accessTokenExpiry == null) return true;
    
    return DateTime.now().isAfter(tokens!.accessTokenExpiry!);
  }

  Future<bool> isTokenNearExpiry() async {
    final tokens = await getStoredTokens();
    if (tokens?.accessTokenExpiry == null) return true;
    
    final expiryTime = tokens!.accessTokenExpiry!;
    final warningTime = expiryTime.subtract(const Duration(minutes: 5));
    
    return DateTime.now().isAfter(warningTime);
  }

  Future<void> clearTokens() async {
    await _storageService.removeKey(_accessTokenKey);
    await _storageService.removeKey(_refreshTokenKey);
    await _storageService.removeKey(_accessTokenExpiryKey);
    await _storageService.removeKey(_refreshTokenExpiryKey);
  }

  Future<bool> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _authEndpoints.refreshToken(
        RefreshTokenRequest(refreshToken: refreshToken),
      );

      await storeTokens(response.data.tokens);
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

## Error Handling Patterns

### Error Handler

```dart
// lib/core/utils/error_handler.dart
class ErrorHandler {
  AppException handleError(dynamic error) {
    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return AppException.timeout('Connection timeout');
        case DioExceptionType.sendTimeout:
          return AppException.timeout('Send timeout');
        case DioExceptionType.receiveTimeout:
          return AppException.timeout('Receive timeout');
        case DioExceptionType.badResponse:
          return _handleBadResponse(error);
        case DioExceptionType.cancel:
          return AppException.cancelled('Request cancelled');
        case DioExceptionType.connectionError:
          return AppException.noInternet('No internet connection');
        default:
          return AppException.unknown('Unknown error occurred');
      }
    }

    return AppException.unknown('Unexpected error: $error');
  }

  AppException _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    switch (statusCode) {
      case 400:
        final message = data?['error']['message'] ?? 'Bad request';
        return AppException.validation(message);
      case 401:
        return AppException.unauthorized('Unauthorized');
      case 403:
        return AppException.forbidden('Forbidden');
      case 404:
        return AppException.notFound('Resource not found');
      case 409:
        return AppException.conflict(data?['error']['message'] ?? 'Conflict');
      case 422:
        final errors = data?['error']['details']['fields'] as List?;
        return AppException.validation('Validation failed', details: errors);
      case 429:
        return AppException.rateLimit('Rate limit exceeded');
      case 500:
        return AppException.serverError('Internal server error');
      case 502:
        return AppException.serverError('Bad gateway');
      case 503:
        return AppException.serverError('Service unavailable');
      default:
        final message = data?['error']['message'] ?? 'Server error';
        return AppException.serverError(message);
    }
  }
}

class AppException implements Exception {
  final String code;
  final String message;
  final dynamic details;

  const AppException._(this.code, this.message, this.details);

  factory AppException.validation(String message, {dynamic details}) =>
      AppException._('VALIDATION_ERROR', message, details);

  factory AppException.unauthorized(String message) =>
      AppException._('UNAUTHORIZED', message, null);

  factory AppException.forbidden(String message) =>
      AppException._('FORBIDDEN', message, null);

  factory AppException.notFound(String message) =>
      AppException._('NOT_FOUND', message, null);

  factory AppException.conflict(String message) =>
      AppException._('CONFLICT', message, null);

  factory AppException.rateLimit(String message) =>
      AppException._('RATE_LIMIT_EXCEEDED', message, null);

  factory AppException.serverError(String message) =>
      AppException._('SERVER_ERROR', message, null);

  factory AppException.timeout(String message) =>
      AppException._('TIMEOUT', message, null);

  factory AppException.cancelled(String message) =>
      AppException._('CANCELLED', message, null);

  factory AppException.noInternet(String message) =>
      AppException._('NO_INTERNET', message, null);

  factory AppException.unknown(String message) =>
      AppException._('UNKNOWN', message, null);

  @override
  String toString() => 'AppException($code): $message';
}
```

### Error UI Components

```dart
// lib/shared/widgets/error_widget.dart
class AppErrorWidget extends StatelessWidget {
  final AppException error;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    Key? key,
    required this.error,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getErrorIcon(),
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _getErrorTitle(),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (onRetry != null) ...[
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
              const SizedBox(height: 8),
            ],
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (error.code) {
      case 'NO_INTERNET':
        return Icons.wifi_off;
      case 'UNAUTHORIZED':
        return Icons.lock;
      case 'NOT_FOUND':
        return Icons.search_off;
      case 'RATE_LIMIT_EXCEEDED':
        return Icons.speed;
      case 'TIMEOUT':
        return Icons.timer_off;
      default:
        return Icons.error_outline;
    }
  }

  String _getErrorTitle() {
    switch (error.code) {
      case 'NO_INTERNET':
        return 'No Internet Connection';
      case 'UNAUTHORIZED':
        return 'Authentication Required';
      case 'NOT_FOUND':
        return 'Not Found';
      case 'RATE_LIMIT_EXCEEDED':
        return 'Too Many Requests';
      case 'TIMEOUT':
        return 'Request Timeout';
      case 'VALIDATION_ERROR':
        return 'Invalid Input';
      default:
        return 'Something Went Wrong';
    }
  }
}
```

### Error Boundary

```dart
// lib/shared/widgets/error_boundary.dart
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Function(dynamic, StackTrace)? onError;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.onError,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  dynamic _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      setState(() {
        _hasError = true;
        _error = details.exception;
        _stackTrace = details.stack;
      });
      
      widget.onError?.call(details.exception, details.stack!);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error?.toString() ?? 'Unknown error',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _error = null;
                    _stackTrace = null;
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
```

## Offline Mode & Caching

### Cache Manager

```dart
// lib/core/utils/cache_manager.dart
class CacheManager {
  static const Duration _defaultCacheDuration = Duration(hours: 24);
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  
  final Map<String, CacheEntry> _cache = {};
  final HiveInterface _hive;
  final NetworkUtils _networkUtils;

  CacheManager(this._hive, this._networkUtils);

  Future<T?> get<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    final entry = _cache[key];
    
    if (entry == null) {
      // Try to load from persistent storage
      return _loadFromStorage(key, fromJson);
    }
    
    if (entry.isExpired) {
      _remove(key);
      return null;
    }
    
    return entry.data as T?;
  }

  Future<void> put<T>(String key, T data, {Duration? duration}) async {
    final expiry = duration ?? _defaultCacheDuration;
    final expiresAt = DateTime.now().add(expiry);
    
    _cache[key] = CacheEntry(
      data: data,
      expiresAt: expiresAt,
      size: _calculateSize(data),
    );
    
    // Check cache size limits
    await _enforceCacheLimits();
    
    // Store to persistent storage
    await _saveToStorage(key, data, expiresAt);
  }

  Future<void> remove(String key) async {
    _cache.remove(key);
    await _hive.delete(key);
  }

  Future<void> clear() async {
    _cache.clear();
    await _hive.clear();
  }

  Future<T?> _loadFromStorage<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final box = await _hive.openBox('cache');
      final data = box.get(key);
      
      if (data != null) {
        final entry = CacheEntry.fromJson(data);
        if (!entry.isExpired) {
          _cache[key] = entry;
          return entry.data as T?;
        } else {
          await box.delete(key);
        }
      }
    } catch (e) {
      print('Error loading from cache: $e');
    }
    
    return null;
  }

  Future<void> _saveToStorage(String key, dynamic data, DateTime expiresAt) async {
    try {
      final box = await _hive.openBox('cache');
      final entry = CacheEntry(
        data: data,
        expiresAt: expiresAt,
        size: _calculateSize(data),
      );
      
      await box.put(key, entry.toJson());
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  Future<void> _enforceCacheLimits() async {
    var totalSize = _cache.values.fold<int>(0, (sum, entry) => sum + entry.size);
    
    // Remove expired entries first
    _cache.removeWhere((key, entry) => entry.isExpired);
    
    // Remove oldest entries if still over limit
    if (totalSize > _maxCacheSize) {
      final sortedEntries = _cache.entries.toList()
        ..sort((a, b) => a.value.accessedAt.compareTo(b.value.accessedAt));
      
      for (final entry in sortedEntries) {
        if (totalSize <= _maxCacheSize) break;
        
        totalSize -= entry.value.size;
        await remove(entry.key);
      }
    }
  }

  int _calculateSize(dynamic data) {
    try {
      final json = jsonEncode(data);
      return utf8.encode(json).length;
    } catch (e) {
      return 1024; // Default size estimate
    }
  }

  Store getHiveStore() {
    return HiveStore(_hive);
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime expiresAt;
  final int size;
  final DateTime accessedAt;

  CacheEntry({
    required this.data,
    required this.expiresAt,
    required this.size,
    DateTime? accessedAt,
  }) : accessedAt = accessedAt ?? DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
    'data': data,
    'expiresAt': expiresAt.toIso8601String(),
    'size': size,
    'accessedAt': accessedAt.toIso8601String(),
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
    data: json['data'],
    expiresAt: DateTime.parse(json['expiresAt']),
    size: json['size'],
    accessedAt: DateTime.parse(json['accessedAt']),
  );
}
```

### Network Utilities

```dart
// lib/core/utils/network_utils.dart
class NetworkUtils {
  final Connectivity _connectivity;

  NetworkUtils(this._connectivity);

  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Stream<bool> get connectionStream => _connectivity.onConnectivityChanged.map(
    (result) => result != ConnectivityResult.none,
  );

  Future<NetworkType> getNetworkType() async {
    final result = await _connectivity.checkConnectivity();
    switch (result) {
      case ConnectivityResult.wifi:
        return NetworkType.wifi;
      case ConnectivityResult.mobile:
        return NetworkType.mobile;
      case ConnectivityResult.ethernet:
        return NetworkType.ethernet;
      default:
        return NetworkType.none;
    }
  }
}

enum NetworkType { wifi, mobile, ethernet, none }
```

### Offline Data Manager

```dart
// lib/core/services/offline_data_manager.dart
class OfflineDataManager {
  final CacheManager _cacheManager;
  final ApiClient _apiClient;
  final NetworkUtils _networkUtils;

  OfflineDataManager(
    this._cacheManager,
    this._apiClient,
    this._networkUtils,
  );

  Future<ProductListResponse> getCachedProducts({
    int page = 1,
    int limit = 20,
  }) async {
    final cacheKey = 'products_${page}_${limit}';
    final cached = await _cacheManager.get(cacheKey, ProductListResponse.fromJson);
    
    if (cached != null) {
      return cached;
    }
    
    if (await _networkUtils.isConnected()) {
      try {
        final response = await _apiClient.get<ProductListResponse>(
          '/api/products',
          queryParameters: {'page': page, 'limit': limit},
          fromJson: ProductListResponse.fromJson,
        );
        
        await _cacheManager.put(cacheKey, response);
        return response;
      } catch (e) {
        throw AppException.noInternet('No cached data available');
      }
    }
    
    throw AppException.noInternet('No internet connection and no cached data');
  }

  Future<void> cacheUserProfile(User user) async {
    final cacheKey = 'user_profile';
    await _cacheManager.put(cacheKey, user, duration: const Duration(hours: 6));
  }

  Future<User?> getCachedUserProfile() async {
    final cacheKey = 'user_profile';
    return await _cacheManager.get(cacheKey, User.fromJson);
  }

  Future<void> cacheCart(Cart cart) async {
    final cacheKey = 'cart';
    await _cacheManager.put(cacheKey, cart);
  }

  Future<Cart?> getCachedCart() async {
    final cacheKey = 'cart';
    return await _cacheManager.get(cacheKey, Cart.fromJson);
  }

  Future<void> queueOfflineAction(OfflineAction action) async {
    // Store action in local database for later execution
    final queueKey = 'offline_queue';
    final existingQueue = await _cacheManager.get<List>(queueKey, List.from) ?? [];
    existingQueue.add(action.toJson());
    await _cacheManager.put(queueKey, existingQueue);
  }

  Future<List<OfflineAction>> getOfflineActions() async {
    final queueKey = 'offline_queue';
    final queue = await _cacheManager.get<List>(queueKey, List.from);
    return queue?.map((json) => OfflineAction.fromJson(json)).toList() ?? [];
  }

  Future<void> processOfflineActions() async {
    if (!await _networkUtils.isConnected()) return;
    
    final actions = await getOfflineActions();
    
    for (final action in actions) {
      try {
        await _executeOfflineAction(action);
        await _removeOfflineAction(action.id);
      } catch (e) {
        print('Failed to execute offline action: ${action.id}');
      }
    }
  }

  Future<void> _executeOfflineAction(OfflineAction action) async {
    switch (action.type) {
      case OfflineActionType.addToCart:
        await _apiClient.post('/api/cart/add', data: action.data);
        break;
      case OfflineActionType.updateQuantity:
        await _apiClient.put('/api/cart/item/${action.id}/quantity', data: action.data);
        break;
      case OfflineActionType.removeFromCart:
        await _apiClient.delete('/api/cart/item/${action.id}');
        break;
      case OfflineActionType.createOrder:
        await _apiClient.post('/api/order/create', data: action.data);
        break;
    }
  }

  Future<void> _removeOfflineAction(String id) async {
    final queueKey = 'offline_queue';
    final queue = await _cacheManager.get<List>(queueKey, List.from) ?? [];
    final updatedQueue = queue.where((json) => json['id'] != id).toList();
    await _cacheManager.put(queueKey, updatedQueue);
  }
}

class OfflineAction {
  final String id;
  final OfflineActionType type;
  final Map<String, dynamic> data;

  OfflineAction({
    required this.id,
    required this.type,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'data': data,
  };

  factory OfflineAction.fromJson(Map<String, dynamic> json) => OfflineAction(
    id: json['id'],
    type: OfflineActionType.values.firstWhere((e) => e.toString() == json['type']),
    data: json['data'],
  );
}

enum OfflineActionType {
  addToCart,
  updateQuantity,
  removeFromCart,
  createOrder,
}
```

## Performance Optimization

### Image Caching and Optimization

```dart
// lib/shared/widgets/cached_image.dart
class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool useCacheManager;

  const CachedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.useCacheManager = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (useCacheManager) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ?? const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) =>
            errorWidget ?? const Icon(Icons.error),
        cacheManager: DefaultCacheManager(),
        memCacheWidth: width != null ? (width! * MediaQuery.of(context).devicePixelRatio).round() : null,
        memCacheHeight: height != null ? (height! * MediaQuery.of(context).devicePixelRatio).round() : null,
      );
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? const Icon(Icons.error);
      },
      cacheWidth: width != null ? (width! * MediaQuery.of(context).devicePixelRatio).round() : null,
      cacheHeight: height != null ? (height! * MediaQuery.of(context).devicePixelRatio).round() : null,
    );
  }
}
```

### List Performance Optimization

```dart
// lib/features/products/widgets/product_list.dart
class ProductList extends StatefulWidget {
  final String category;

  const ProductList({Key? key, required this.category}) : super(key: key);

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final ScrollController _scrollController = ScrollController();
  final ProductEndpoints _productEndpoints = ProductEndpoints(ApiClient());
  
  List<Product> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _productEndpoints.getProducts(
        page: _currentPage,
        limit: _pageSize,
        category: widget.category,
      );

      setState(() {
        if (_currentPage == 1) {
          _products = response.data.products;
        } else {
          _products.addAll(response.data.products);
        }
        _hasMore = response.data.pagination.hasNext;
        _currentPage++;
      });
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load products: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadProducts();
    }
  }

  Future<void> _refresh() async {
    _currentPage = 1;
    _hasMore = true;
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _products.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _products.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final product = _products[index];
          return ProductCard(product: product);
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: product.id),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'product_${product.id}',
              child: CachedImage(
                imageUrl: product.images.first.url,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    product.brand,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (product.originalPrice > product.price) ...[
                        const SizedBox(width: 8),
                        Text(
                          '\$${product.originalPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      Text('${product.rating.average.toStringAsFixed(1)}'),
                      Text('(${product.rating.count})'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Memory Management

```dart
// lib/core/utils/memory_manager.dart
class MemoryManager {
  static Timer? _cleanupTimer;
  static final Map<String, Timer> _imageLoadingTimers = {};

  static void startMemoryMonitoring() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupUnusedResources();
    });
  }

  static void stopMemoryMonitoring() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  static void _cleanupUnusedResources() {
    // Clear image caches periodically
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    
    // Clear expired cached data
    final cacheManager = CacheManager(Hive(), NetworkUtils(Connectivity()));
    cacheManager.clear();
  }

  static void preloadImages(List<String> imageUrls) {
    for (final url in imageUrls) {
      // Cancel existing timer for this URL
      _imageLoadingTimers[url]?.cancel();
      
      // Start new timer
      _imageLoadingTimers[url] = Timer(Duration(milliseconds: 100), () {
        precacheImage(NetworkImage(url), context);
      });
    }
  }

  static void disposeImageLoading(String url) {
    _imageLoadingTimers[url]?.cancel();
    _imageLoadingTimers.remove(url);
  }

  static void optimizeForLowEndDevices() {
    // Reduce image cache size for low-end devices
    final deviceMemory = DeviceInfoPlugin().androidInfo;
    
    deviceMemory.then((info) {
      if (info.totalMemory! < 2000000000) { // Less than 2GB
        PaintingBinding.instance.imageCache.maximumSize = 50;
        PaintingBinding.instance.imageCache.maximumMemoryBytes = 50 * 1024 * 1024; // 50MB
      }
    });
  }
}
```

## State Management

### Provider Pattern Implementation

```dart
// lib/features/products/providers/product_provider.dart
class ProductProvider extends ChangeNotifier {
  final ProductEndpoints _productEndpoints;
  final CacheManager _cacheManager;
  final OfflineDataManager _offlineManager;

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedBrand;
  RangeValues _priceRange = const RangeValues(0, 1000);
  String _sortBy = 'popularity';
  bool _isLoading = false;
  bool _isSearching = false;

  // Getters
  List<Product> get products => _filteredProducts.isEmpty ? _products : _filteredProducts;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  String? get selectedBrand => _selectedBrand;
  RangeValues get priceRange => _priceRange;
  String get sortBy => _sortBy;

  ProductProvider(
    this._productEndpoints,
    this._cacheManager,
    this._offlineManager,
  );

  Future<void> loadProducts({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cacheKey = 'products_all';
      if (!forceRefresh) {
        final cached = await _cacheManager.get(cacheKey, ProductListResponse.fromJson);
        if (cached != null) {
          _products = cached.data.products;
          _applyFilters();
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      final response = await _productEndpoints.getProducts();
      _products = response.data.products;
      
      await _cacheManager.put(cacheKey, response);
      _applyFilters();
    } catch (e) {
      // Handle error - maybe show cached data
      final cached = await _cacheManager.get('products_all', ProductListResponse.fromJson);
      if (cached != null) {
        _products = cached.data.products;
        _applyFilters();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      _searchQuery = '';
      _filteredProducts.clear();
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchQuery = query;
    notifyListeners();

    try {
      final response = await _productEndpoints.searchProducts(query);
      _filteredProducts = response.data.products;
    } catch (e) {
      // Fallback to local search
      _filteredProducts = _products.where((product) =>
        product.name.toLowerCase().contains(query.toLowerCase()) ||
        product.description.toLowerCase().contains(query.toLowerCase()) ||
        product.brand.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void applyFilters({
    String? category,
    String? brand,
    RangeValues? priceRange,
    String? sortBy,
  }) {
    if (category != null) _selectedCategory = category;
    if (brand != null) _selectedBrand = brand;
    if (priceRange != null) _priceRange = priceRange;
    if (sortBy != null) _sortBy = sortBy;
    
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedBrand = null;
    _priceRange = const RangeValues(0, 1000);
    _sortBy = 'popularity';
    
    _filteredProducts.clear();
    notifyListeners();
  }

  void _applyFilters() {
    var filtered = List<Product>.from(_products);

    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((product) =>
          product.category == _selectedCategory).toList();
    }

    // Apply brand filter
    if (_selectedBrand != null) {
      filtered = filtered.where((product) =>
          product.brand == _selectedBrand).toList();
    }

    // Apply price range filter
    filtered = filtered.where((product) =>
        product.price >= _priceRange.start &&
        product.price <= _priceRange.end).toList();

    // Apply sorting
    switch (_sortBy) {
      case 'price_asc':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        filtered.sort((a, b) => b.rating.average.compareTo(a.rating.average));
        break;
      case 'newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      default:
        // Popularity - already sorted by API
        break;
    }

    _filteredProducts = filtered;
  }

  void resetSearch() {
    _searchQuery = '';
    _filteredProducts.clear();
    _isSearching = false;
    notifyListeners();
  }
}
```

This comprehensive integration guide provides a complete foundation for integrating the Virtual Try-On API with Flutter applications. It covers all aspects from basic setup to advanced features like offline support, caching, performance optimization, and error handling.