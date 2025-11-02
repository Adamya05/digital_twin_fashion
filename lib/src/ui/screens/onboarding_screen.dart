/// Onboarding Screen
/// 
/// Initial welcome screen that introduces users to the virtual try-on app,
/// explains key features, and guides users through the initial setup process.
/// Handles first-time user experience with animated 3D avatar preview and privacy consent.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../themes/app_theme.dart';
import '../../widgets/consent_modal.dart';
import '../../services/privacy_service.dart';
import 'scan_method_choose.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _floatController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _floatAnimation;

  bool _showConsentModal = true;
  bool _consentAcknowledged = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkFirstLaunch();
  }

  void _setupAnimations() {
    // Rotation animation for 3D avatar placeholder
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(); // Loop animation
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159, // Full rotation (360 degrees)
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Floating animation for subtle movement
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _floatAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));
  }

  void _checkFirstLaunch() async {
    try {
      final service = PrivacyService.instance;
      await service.initialize();
      final isCompleted = await service.isOnboardingCompleted();
      
      setState(() {
        _showConsentModal = !isCompleted;
        _consentAcknowledged = isCompleted;
      });
    } catch (e) {
      // If privacy service fails, show modal by default
      setState(() {
        _showConsentModal = true;
      });
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            children: [
              // App Logo and Header
              _buildHeader(context),
              
              const SizedBox(height: AppTheme.spacingXl),
              
              // 3D Avatar Animation Placeholder
              Expanded(
                flex: 3,
                child: _buildAvatarPreview(context),
              ),
              
              const SizedBox(height: AppTheme.spacingL),
              
              // Tagline
              _buildTagline(context),
              
              const SizedBox(height: AppTheme.spacingM),
              
              // Privacy Note
              _buildPrivacyNote(context),
              
              const SizedBox(height: AppTheme.spacingXl),
              
              // CTA Button
              _buildCTAButton(context),
              
              const SizedBox(height: AppTheme.spacingL),
            ],
          ),
        ),
      ),
      
      // Consent Modal Overlay
      if (_showConsentModal)
        _buildConsentModalOverlay(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // App Logo Placeholder
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen,
                AppTheme.primaryGreen.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.largeRadius),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_search_outlined,
            color: AppTheme.onPrimary,
            size: 40,
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingM),
        
        // App Name
        Text(
          'FitTwin',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppTheme.primaryGreen,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingS),
        
        Text(
          'Fashion Meets Innovation',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textDarkGray.withOpacity(0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPreview(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationAnimation, _floatAnimation]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                width: 200,
                height: 280,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppTheme.canvasContainerRadius),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Avatar silhouette placeholder
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.canvasContainerRadius),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.surfaceWhite,
                              AppTheme.surfaceVariant,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 120,
                          color: AppTheme.outline,
                        ),
                      ),
                    ),
                    
                    // Scanning overlay effect
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.canvasContainerRadius),
                        child: AnimatedBuilder(
                          animation: _rotationController,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppTheme.canvasContainerRadius),
                                border: Border.all(
                                  color: AppTheme.primaryGreen.withOpacity(0.6),
                                  width: 2,
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.canvasContainerRadius - 8,
                                  ),
                                  border: Border.all(
                                    color: AppTheme.primaryGreen.withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    // "3D Avatar" text overlay
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingS,
                          vertical: AppTheme.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                        ),
                        child: const Text(
                          'Your 3D Avatar',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTagline(BuildContext context) {
    return Column(
      children: [
        Text(
          'Step into Fashion\'s Future',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textDarkGray,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.spacingS),
        
        Text(
          'Create your digital twin and try on thousands of styles\nwith revolutionary AR technology',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textDarkGray.withOpacity(0.7),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPrivacyNote(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPrivacyInfo(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Text(
            'Why we need video scans',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.primaryGreen,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButton(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _consentAcknowledged ? () => _navigateToScanWizard(context) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _consentAcknowledged 
                  ? AppTheme.primaryGreen 
                  : AppTheme.outline.withOpacity(0.5),
              foregroundColor: AppTheme.onPrimary,
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.spacingL,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.majorCardsRadius),
              ),
              elevation: _consentAcknowledged ? AppTheme.elevatedCardElevation : 0,
              shadowColor: _consentAcknowledged 
                  ? AppTheme.primaryGreen.withOpacity(0.3) 
                  : Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _consentAcknowledged 
                      ? Icons.play_circle_outline 
                      : Icons.lock_outline,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  _consentAcknowledged 
                      ? 'Create Your Avatar' 
                      : 'Consent Required',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        if (!_consentAcknowledged) ...[
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Please accept consent to continue',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConsentModalOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: ConsentModal(
          onAccept: () async {
            try {
              final service = PrivacyService.instance;
              await service.initialize();
              await service.setOnboardingCompleted(true);
            } catch (e) {
              // Silently handle preference save errors
            }
            
            setState(() {
              _showConsentModal = false;
              _consentAcknowledged = true;
            });
            HapticFeedback.lightImpact();
          },
          onDecline: () async {
            try {
              final service = PrivacyService.instance;
              await service.initialize();
              await service.setOnboardingCompleted(true); // Still mark as completed to avoid showing again
            } catch (e) {
              // Silently handle preference save errors
            }
            
            setState(() {
              _showConsentModal = false;
              _consentAcknowledged = false;
            });
            HapticFeedback.lightImpact();
          },
        ),
      ),
    );
  }

  void _showPrivacyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Why We Need Video Scans'),
        content: const SingleChildScrollView(
          child: Text(
            'High-quality 3D avatars require detailed video scans to accurately capture:\n\n'
            '• Body measurements and proportions\n'
            '• Skin tone and texture details\n'
            '• Facial features for realistic rendering\n'
            '• Movement patterns for natural fitting\n\n'
            'This data is processed securely using advanced AI to create your personalized avatar, '
            'ensuring perfect fit and natural-looking virtual try-ons.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _navigateToScanWizard(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/scan-method-choose',
      (route) => route.isFirst,
    );
  }
}
