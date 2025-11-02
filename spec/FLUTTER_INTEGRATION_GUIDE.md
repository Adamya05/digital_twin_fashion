# Flutter Integration Guide

Complete guide for integrating the Virtual Try-On API with Flutter applications, including authentication, avatar scanning, try-on rendering, and e-commerce features.

## Table of Contents

- [Overview](#overview)
- [Project Setup](#project-setup)
- [API Client Library](#api-client-library)
- [Authentication Implementation](#authentication-implementation)
- [Avatar Scanning Integration](#avatar-scanning-integration)
- [Product Catalog](#product-catalog)
- [3D Try-On Implementation](#3d-try-on-implementation)
- [Shopping Cart & Orders](#shopping-cart--orders)
- [User Profile & Closet](#user-profile--closet)
- [Error Handling & Retry Logic](#error-handling--retry-logic)
- [Offline Mode & Caching](#offline-mode--caching)
- [Performance Optimization](#performance-optimization)
- [Security Implementation](#security-implementation)
- [Testing & Validation](#testing--validation)
- [Complete App Example](#complete-app-example)

## Overview

This guide provides comprehensive Flutter integration for the Virtual Try-On API, enabling developers to build:

- **Avatar Scanning**: Camera-based 3D avatar generation
- **Virtual Try-On**: Real-time 3D clothing rendering
- **Product Catalog**: Search, filter, and browse fashion items
- **E-Commerce**: Shopping cart, orders, and payment processing
- **User Management**: Profiles, preferences, and virtual closet
- **Offline Support**: Cached data and offline functionality

### Flutter Version Requirements

- Flutter SDK: 3.10.0 or higher
- Dart: 3.0.0 or higher
- Android SDK: API level 21+ (Android 5.0)
- iOS: iOS 11.0+

## Project Setup

### Dependencies

Add to `pubspec.yaml`:

```yaml
name: virtual_tryon_app
description: Virtual Try-On Flutter Application
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter
  
  # HTTP and API
  http: ^1.1.0
  dio: ^5.3.0
  chopper: ^7.0.9
  
  # Authentication
  jwt_decoder: ^3.1.0
  shared_preferences: ^2.2.2
  local_auth: ^2.1.7
  
  # Camera and Image
  camera: ^0.10.5
  image_picker: ^1.0.4
  image: ^4.1.0
  gallery_saver: ^2.3.2
  
  # 3D Rendering
  model_viewer: ^4.0.1
  three_dart: ^0.0.5
  flutter_gl: ^0.0.7
  
  # State Management
  provider: ^6.0.5
  riverpod: ^2.4.9
  flutter_bloc: ^8.1.3
  
  # UI Components
  cupertino_icons: ^1.0.6
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  lottie: ^2.7.0
  
  # Utils
  equatable: ^2.0.5
  json_annotation: ^4.8.1
  freezed_annotation: ^2.4.1
  permission_handler: ^11.0.1
  path_provider: ^2.1.1
  intl: ^0.18.1
  
  # Storage and Database
  sqflite: ^2.3.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Background Processing
  workmanager: ^0.5.2
  flutter_local_notifications: ^16.1.0
  
  # Charts and Analytics
  fl_chart: ^0.64.0
  firebase_analytics: ^10.7.4
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  freezed: ^2.4.6
  hive_generator: ^2.0.1
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/avatars/
    - assets/models/
    - assets/animations/
    - assets/icons/
  
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

### Project Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── routes.dart
│   └── theme.dart
├── core/
│   ├── constants/
│   ├── utils/
│   ├── errors/
│   ├── network/
│   └── storage/
├── data/
│   ├── datasources/
│   ├── models/
│   ├── repositories/
│   └── services/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── pages/
│   ├── widgets/
│   ├── providers/
│   └── blocs/
└── assets/
```

## API Client Library

### HTTP Client Setup

```dart
// core/network/api_client.dart
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'https://api.tryon.com/v1';
  static const String stagingBaseUrl = 'https://staging-api.tryon.com/v1';
  static const String devBaseUrl = 'https://dev-api.tryon.com/v1';
  
  late final Dio _dio;
  final SharedPreferences _prefs;
  
  ApiClient(this._prefs) {
    _dio = Dio(BaseOptions(
      baseUrl: _getBaseUrl(),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _setupInterceptors();
  }
  
  String _getBaseUrl() {
    const String? environment = String.fromEnvironment('ENVIRONMENT');
    switch (environment) {
      case 'staging':
        return stagingBaseUrl;
      case 'development':
        return devBaseUrl;
      default:
        return baseUrl;
    }
  }
  
  void _setupInterceptors() {
    // Request interceptor for auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the original request
            final token = await getAccessToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            handler.resolve(response);
            return;
          }
        }
        handler.next(error);
      },
    ));
    
    // Logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }
  
  // Authentication methods
  Future<String?> getAccessToken() async {
    final token = _prefs.getString('access_token');
    if (token != null && !JwtDecoder.isExpired(token)) {
      return token;
    }
    return null;
  }
  
  Future<String?> getRefreshToken() async {
    return _prefs.getString('refresh_token');
  }
  
  Future<bool> _refreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;
    
    try {
      final response = await _dio.post(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        await saveTokens(
          data['tokens']['accessToken'],
          data['tokens']['refreshToken'],
        );
        return true;
      }
    } catch (e) {
      // Handle refresh token failure
      await clearTokens();
    }
    return false;
  }
  
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _prefs.setString('access_token', accessToken);
    await _prefs.setString('refresh_token', refreshToken);
  }
  
  Future<void> clearTokens() async {
    await _prefs.remove('access_token');
    await _prefs.remove('refresh_token');
  }
  
  // HTTP methods
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      
      return ApiResponse.success(
        data: fromJson != null ? fromJson(response.data) : null,
        rawData: response.data,
      );
    } on DioException catch (e) {
      return ApiResponse.error(
        message: e.response?.data['error']['message'] ?? 'Request failed',
        code: e.response?.data['error']['code'],
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      
      return ApiResponse.success(
        data: fromJson != null ? fromJson(response.data) : null,
        rawData: response.data,
      );
    } on DioException catch (e) {
      return ApiResponse.error(
        message: e.response?.data['error']['message'] ?? 'Request failed',
        code: e.response?.data['error']['code'],
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      
      return ApiResponse.success(
        data: fromJson != null ? fromJson(response.data) : null,
        rawData: response.data,
      );
    } on DioException catch (e) {
      return ApiResponse.error(
        message: e.response?.data['error']['message'] ?? 'Request failed',
        code: e.response?.data['error']['code'],
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      
      return ApiResponse.success(
        data: fromJson != null ? fromJson(response.data) : null,
        rawData: response.data,
      );
    } on DioException catch (e) {
      return ApiResponse.error(
        message: e.response?.data['error']['message'] ?? 'Request failed',
        code: e.response?.data['error']['code'],
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<T>> upload<T>(
    String path,
    List<UploadFile> files, {
    Map<String, dynamic>? fields,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...?fields,
        ...files.map((file) => MapEntry(
          'files',
          MultipartFile.fromBytes(
            file.bytes,
            filename: file.filename,
            contentType: file.contentType,
          ),
        )),
      });
      
      final response = await _dio.post(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: options,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
      
      return ApiResponse.success(
        data: fromJson != null ? fromJson(response.data) : null,
        rawData: response.data,
      );
    } on DioException catch (e) {
      return ApiResponse.error(
        message: e.response?.data['error']['message'] ?? 'Upload failed',
        code: e.response?.data['error']['code'],
        statusCode: e.response?.statusCode,
      );
    }
  }
}

// Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final Map<String, dynamic>? rawData;
  final String? message;
  final String? code;
  final int? statusCode;
  
  ApiResponse._({
    required this.success,
    this.data,
    this.rawData,
    this.message,
    this.code,
    this.statusCode,
  });
  
  factory ApiResponse.success({
    T? data,
    Map<String, dynamic>? rawData,
  }) {
    return ApiResponse._(
      success: true,
      data: data,
      rawData: rawData,
    );
  }
  
  factory ApiResponse.error({
    required String message,
    String? code,
    int? statusCode,
  }) {
    return ApiResponse._(
      success: false,
      message: message,
      code: code,
      statusCode: statusCode,
    );
  }
}

// Upload file model
class UploadFile {
  final List<int> bytes;
  final String filename;
  final String contentType;
  
  UploadFile({
    required this.bytes,
    required this.filename,
    this.contentType = 'application/octet-stream',
  });
}
```

### API Response Models

```dart
// data/models/api_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'api_models.g.dart';

// Generic API response
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;
  
  ApiResponse({
    required this.success,
    this.data,
    this.error,
  });
  
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);
      
  Map<String, dynamic> toJson(
    Object? Function(T value) toJsonT,
  ) =>
      _$ApiResponseToJson(this, toJsonT);
}

// Error model
@JsonSerializable()
class ApiError {
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  
  ApiError({
    required this.code,
    required this.message,
    this.details,
  });
  
  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);
      
  Map<String, dynamic> toJson() => _$ApiErrorToJson(this);
}

// User models
@JsonSerializable()
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? avatar;
  final bool emailVerified;
  final DateTime createdAt;
  
  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.avatar,
    required this.emailVerified,
    required this.createdAt,
  });
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;
  final String? provider;
  final String? providerToken;
  
  LoginRequest({
    required this.email,
    required this.password,
    this.provider,
    this.providerToken,
  });
  
  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class LoginResponse {
  final User user;
  final AuthTokens tokens;
  
  LoginResponse({
    required this.user,
    required this.tokens,
  });
  
  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}

@JsonSerializable()
class AuthTokens {
  final String accessToken;
  final DateTime accessTokenExpires;
  final String refreshToken;
  final DateTime refreshTokenExpires;
  
  AuthTokens({
    required this.accessToken,
    required this.accessTokenExpires,
    required this.refreshToken,
    required this.refreshTokenExpires,
  });
  
  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
  Map<String, dynamic> toJson() => _$AuthTokensToJson(this);
}

// Avatar models
@JsonSerializable()
class Avatar {
  final String id;
  final String name;
  final String status;
  final AvatarModel? model;
  final AvatarPreview? preview;
  final Map<String, double>? measurements;
  final double? qualityScore;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Avatar({
    required this.id,
    required this.name,
    required this.status,
    this.model,
    this.preview,
    this.measurements,
    this.qualityScore,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Avatar.fromJson(Map<String, dynamic> json) => _$AvatarFromJson(json);
  Map<String, dynamic> toJson() => _$AvatarToJson(this);
}

@JsonSerializable()
class AvatarModel {
  final String url;
  final String format;
  final String size;
  final int polycount;
  final List<String> textures;
  
  AvatarModel({
    required this.url,
    required this.format,
    required this.size,
    required this.polycount,
    required this.textures,
  });
  
  factory AvatarModel.fromJson(Map<String, dynamic> json) =>
      _$AvatarModelFromJson(json);
  Map<String, dynamic> toJson() => _$AvatarModelToJson(this);
}

@JsonSerializable()
class ScanRequest {
  final String scanType;
  final List<ScanImage> images;
  final UserPreferences? userPreferences;
  
  ScanRequest({
    required this.scanType,
    required this.images,
    this.userPreferences,
  });
  
  factory ScanRequest.fromJson(Map<String, dynamic> json) =>
      _$ScanRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ScanRequestToJson(this);
}

@JsonSerializable()
class ScanImage {
  final String url;
  final String pose;
  final double quality;
  
  ScanImage({
    required this.url,
    required this.pose,
    required this.quality,
  });
  
  factory ScanImage.fromJson(Map<String, dynamic> json) =>
      _$ScanImageFromJson(json);
  Map<String, dynamic> toJson() => _$ScanImageToJson(this);
}

// Product models
@JsonSerializable()
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String currency;
  final String brand;
  final String category;
  final String? subcategory;
  final List<ProductImage> images;
  final ProductModel3D? model3D;
  final List<ProductVariant> variants;
  final ProductRating? rating;
  final bool tryonAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.currency,
    required this.brand,
    required this.category,
    this.subcategory,
    required this.images,
    this.model3D,
    required this.variants,
    this.rating,
    required this.tryonAvailable,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}

// Continue with other models...
```

## Authentication Implementation

### Authentication Provider

```dart
// providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/api_models.dart';
import '../data/datasources/auth_datasource.dart';

class AuthProvider with ChangeNotifier {
  final AuthDataSource _authDataSource;
  final SharedPreferences _prefs;
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  
  AuthProvider(this._authDataSource, this._prefs) {
    _loadUserFromStorage();
  }
  
  Future<void> _loadUserFromStorage() async {
    final token = _prefs.getString('access_token');
    if (token != null) {
      // Verify token and load user
      final result = await _authDataSource.getProfile();
      if (result is ApiResponse && result.success && result.data != null) {
        _user = result.data;
        notifyListeners();
      }
    }
  }
  
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authDataSource.login(
        LoginRequest(email: email, password: password),
      );
      
      if (result.success && result.data != null) {
        _user = result.data!.user;
        await _saveTokens(result.data!.tokens);
        notifyListeners();
        return true;
      } else {
        _setError(result.message ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please check your connection.');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    bool agreeToTerms = false,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authDataSource.register(RegisterRequest(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        agreeToTerms: agreeToTerms,
      ));
      
      if (result.success) {
        // Auto-login after successful registration
        return await login(email, password);
      } else {
        _setError(result.message ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please check your connection.');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> logout() async {
    await _authDataSource.logout();
    await _clearTokens();
    _user = null;
    notifyListeners();
  }
  
  Future<bool> refreshToken() async {
    final refreshToken = _prefs.getString('refresh_token');
    if (refreshToken == null) return false;
    
    try {
      final result = await _authDataSource.refreshToken(
        RefreshTokenRequest(refreshToken: refreshToken),
      );
      
      if (result.success && result.data != null) {
        await _saveTokens(result.data!.tokens);
        return true;
      }
    } catch (e) {
      // Handle refresh failure
    }
    
    // If refresh fails, logout user
    await logout();
    return false;
  }
  
  Future<void> _saveTokens(AuthTokens tokens) async {
    await _prefs.setString('access_token', tokens.accessToken);
    await _prefs.setString('refresh_token', tokens.refreshToken);
  }
  
  Future<void> _clearTokens() async {
    await _prefs.remove('access_token');
    await _prefs.remove('refresh_token');
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
```

### Login Screen

```dart
// presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                  ),
                ),
                const SizedBox(height: 40),
                // Title
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to your account',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Email field
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Password field
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Error message
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.error != null) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          authProvider.error!,
                          style: TextStyle(color: Colors.red.shade700),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 24),
                // Login button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return CustomButton(
                      text: 'Sign In',
                      isLoading: authProvider.isLoading,
                      onPressed: _handleLogin,
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Social login buttons
                const _SocialLoginButtons(),
                const SizedBox(height: 24),
                // Register link
                _RegisterLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialLoginButtons extends StatelessWidget {
  const _SocialLoginButtons();
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider
        Row(
          children: const [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('OR'),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        // Google login
        OutlinedButton.icon(
          onPressed: () => _handleSocialLogin(context, 'google'),
          icon: Image.asset(
            'assets/icons/google.png',
            width: 20,
            height: 20,
          ),
          label: const Text('Continue with Google'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Apple login (iOS only)
        if (Theme.of(context).platform == TargetPlatform.iOS)
          OutlinedButton.icon(
            onPressed: () => _handleSocialLogin(context, 'apple'),
            icon: const Icon(Icons.apple, size: 20),
            label: const Text('Continue with Apple'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }
  
  void _handleSocialLogin(BuildContext context, String provider) {
    // Implement social login
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider login not implemented yet')),
    );
  }
}

class _RegisterLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: TextStyle(color: Colors.grey),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pushNamed('/register'),
          child: const Text('Sign Up'),
        ),
      ],
    );
  }
}
```

### Custom Widgets

```dart
// widgets/custom_text_field.dart
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final bool enabled;
  
  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0066CC)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

// widgets/custom_button.dart
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final bool outlined;
  
  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.outlined = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final buttonColor = backgroundColor ?? const Color(0xFF0066CC);
    final finalTextColor = textColor ?? Colors.white;
    
    return SizedBox(
      height: 50,
      child: outlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: buttonColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _buildChild(finalTextColor),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: finalTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _buildChild(finalTextColor),
            ),
    );
  }
  
  Widget _buildChild(Color textColor) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }
    
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}
```

This is just the beginning of the Flutter integration guide. I'll continue with the remaining sections including avatar scanning, 3D try-on implementation, product catalog, shopping cart, error handling, offline mode, performance optimization, security, testing, and a complete app example.
