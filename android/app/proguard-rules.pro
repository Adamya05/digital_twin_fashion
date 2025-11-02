# Digital Twin Fashion - ProGuard/R8 Rules
# Keep Flutter engine classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep main activity
-keep class com.example.digital_twin_fashion.MainActivity { *; }

# Camera plugin
-keep class com.example.digital_twin_fashion.** { *; }

# Riverpod/Provider
-keep class **\$Provider { *; }
-keep class **\$StateProvider { *; }
-keep class **\$StateNotifierProvider { *; }
-keep class **\$FutureProvider { *; }
-keep class **\$StreamProvider { *; }
-keep class **\$ChangeNotifier { *; }

# Model Viewer Plus
-keep class com.google.ar.sceneform.** { *; }
-keep class com.google.ar.core.** { *; }

# Razorpay Flutter
-keep class com.razorpay.** { *; }

# FFmpeg Kit Flutter
-keep class com.arthenica.mobile.ffmpeg.** { *; }

# HTTP/Shared Preferences
-keep class org.apache.http.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# General optimization rules
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify
-repackageclasses ''
-verbose

# Keep model classes for JSON serialization
-keep class * implements java.io.Serializable { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Keep model viewer assets
-keep class android.widget.VideoView { *; }
-keep class android.graphics.SurfaceTexture { *; }

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Optimize strings
-optimizations !code/simplification/StringValueOf

# Keep reflection classes
-keepattributes InnerClasses,EnclosingMethod

# Generic optimization
-optimizations !code/simplification/advanced,!code/simplification/cast,!field/*,!class/merging/*