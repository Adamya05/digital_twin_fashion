import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette
  static const Color primaryGreen = Color(0xFF2EB86C);
  static const Color accentOrange = Color(0xFFFFB86C);
  static const Color backgroundGray = Color(0xFFF7F8FB);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textDarkGray = Color(0xFF333333);
  
  // Additional Material Design 3 Colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF000000);
  static const Color onBackground = Color(0xFF000000);
  static const Color onSurface = Color(0xFF000000);
  static const Color error = Color(0xFFB3261E);
  
  // Elevation/Shadow Colors
  static const Color shadowColor = Color(0x1A000000);
  static const Color surfaceVariant = Color(0xFFF1F3F4);
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);
  
  // Typography
  static const String fontFamily = 'Inter'; // Using Inter as primary, fallback to Poppins
  
  static const TextTheme textTheme = TextTheme(
    // Headlines
    displayLarge: TextStyle(
      fontSize: 22.0,
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily,
      color: textDarkGray,
      letterSpacing: 0.0,
    ),
    displayMedium: TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily,
      color: textDarkGray,
      letterSpacing: 0.0,
    ),
    displaySmall: TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily,
      color: textDarkGray,
      letterSpacing: 0.0,
    ),
    
    // Headlines - following spec
    headlineLarge: TextStyle(
      fontSize: 22.0,
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily,
      color: textDarkGray,
      letterSpacing: 0.0,
    ),
    headlineMedium: TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily,
      color: textDarkGray,
      letterSpacing: 0.0,
    ),
    headlineSmall: TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily,
      color: textDarkGray,
      letterSpacing: 0.0,
    ),
    
    // Body text
    bodyLarge: TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.normal,
      fontFamily: fontFamily,
      color: textDarkGray,
      letterSpacing: 0.15,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.normal,
      fontFamily: fontFamily,
      color: textDarkGray,
      letterSpacing: 0.15,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.normal,
      fontFamily: fontFamily,
      color: textDarkGray,
      letterSpacing: 0.1,
      height: 1.4,
    ),
    
    // Labels
    labelLarge: TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.w500,
      fontFamily: fontFamily,
      color: textDarkGray,
      letterSpacing: 0.1,
      height: 1.4,
    ),
    labelMedium: TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.w500,
      fontFamily: fontFamily,
      color: textDarkGray,
      letterSpacing: 0.1,
      height: 1.4,
    ),
    labelSmall: TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
      fontFamily: fontFamily,
      color: textDarkGray,
      letterSpacing: 0.1,
      height: 1.3,
    ),
  );

  // Corner Radius
  static const double majorCardsRadius = 16.0;
  static const double canvasContainerRadius = 24.0;
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 20.0;
  
  // Animation Timings
  static const Duration microInteractionDuration = Duration(milliseconds: 160);
  static const Duration cardAnimationDuration = Duration(milliseconds: 200);
  static const Duration buttonPressDuration = Duration(milliseconds: 150);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  
  // Elevation/Shadow Values
  static const double cardElevation = 2.0;
  static const double elevatedCardElevation = 4.0;
  static const double canvasContainerElevation = 6.0;
  static const double buttonElevation = 2.0;
  static const double pressedButtonElevation = 0.0;

  // Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: accentOrange,
        background: backgroundGray,
        surface: surfaceWhite,
        onPrimary: onPrimary,
        onSecondary: onSecondary,
        onBackground: onBackground,
        onSurface: onSurface,
        error: error,
        surfaceVariant: surfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      textTheme: textTheme,
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: textDarkGray,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: textDarkGray,
          fontFamily: fontFamily,
        ),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        color: surfaceWhite,
        elevation: cardElevation,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(majorCardsRadius),
        ),
        margin: const EdgeInsets.all(8.0),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: onPrimary,
          elevation: buttonElevation,
          shadowColor: shadowColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(majorCardsRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 12.0,
          ),
          textStyle: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            fontFamily: fontFamily,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(majorCardsRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 12.0,
          ),
          textStyle: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            fontFamily: fontFamily,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          textStyle: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            fontFamily: fontFamily,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumRadius),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumRadius),
          borderSide: const BorderSide(color: primaryGreen, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumRadius),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        hintStyle: const TextStyle(
          color: outline,
          fontFamily: fontFamily,
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primaryGreen.withOpacity(0.2),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(smallRadius),
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreen;
          }
          return Colors.grey.shade300;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreen.withOpacity(0.4);
          }
          return Colors.grey.shade300;
        }),
      ),
      
      // Scaffold Background
      scaffoldBackgroundColor: backgroundGray,
      
      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceWhite,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryGreen.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
              fontFamily: fontFamily,
            );
          }
          return const TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w400,
            fontFamily: fontFamily,
          );
        }),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(largeRadius),
          ),
        ),
      ),
    );
  }
  
  // Common spacing values
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;
  
  // Common padding values
  static const EdgeInsets paddingS = EdgeInsets.all(spacingS);
  static const EdgeInsets paddingM = EdgeInsets.all(spacingM);
  static const EdgeInsets paddingL = EdgeInsets.all(spacingL);
  static const EdgeInsets paddingXl = EdgeInsets.all(spacingXl);
  
  // Button padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: spacingL,
    vertical: spacingS,
  );
  
  // Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(spacingM);
  
  // Container padding
  static const EdgeInsets containerPadding = EdgeInsets.all(spacingM);
}