/// Scan Method Choose Screen
/// 
/// Entry point for the scan flow where users select their preferred scanning method.
/// Provides three options: Video Twirl (recommended), Photos (3), and Manual measurements.
import 'package:flutter/material.dart';
import '../../../../themes/app_theme.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import 'scan_wizard.dart';

enum ScanMethod {
  videoTwirl,
  photos,
  manualMeasurements,
}

class ScanMethodChoose extends StatefulWidget {
  const ScanMethodChoose({super.key});

  @override
  State<ScanMethodChoose> createState() => _ScanMethodChooseState();
}

class _ScanMethodChooseState extends State<ScanMethodChoose> {
  ScanMethod? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Scan Method'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'How would you like to create your avatar?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Choose the method that works best for you. We recommend starting with Video Twirl for the most accurate results.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            
            // Video Twirl Option
            _buildMethodCard(
              method: ScanMethod.videoTwirl,
              title: 'Video Twirl',
              subtitle: 'Recommended',
              description: 'Record a 360° video while slowly turning around. Best for accurate body measurements.',
              icon: Icons.360,
              iconColor: AppTheme.primaryGreen,
              estimatedTime: '2-3 minutes',
              requirements: 'Good lighting, 6ft clear space',
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Photos Option
            _buildMethodCard(
              method: ScanMethod.photos,
              title: 'Photos (3)',
              subtitle: 'Quick',
              description: 'Take 3 photos: front, side, and back. Faster option with good accuracy.',
              icon: Icons.camera_alt,
              iconColor: AppTheme.accentOrange,
              estimatedTime: '1-2 minutes',
              requirements: 'Good lighting, tight clothing',
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Manual Measurements Option
            _buildMethodCard(
              method: ScanMethod.manualMeasurements,
              title: 'Manual measurements',
              subtitle: 'Alternative',
              description: 'Enter your measurements manually. Good option if you have precise measurements.',
              icon: Icons.straighten,
              iconColor: Colors.blue,
              estimatedTime: '3-5 minutes',
              requirements: 'Measuring tape, help from a friend',
            ),
            
            const Spacer(),
            
            // Start Twirl Button (primary CTA for recommended method)
            if (_selectedMethod == ScanMethod.videoTwirl)
              PrimaryButton(
                label: 'Start Twirl',
                icon: Icons.play_arrow,
                onPressed: () => _proceedToCamera(),
                fullWidth: true,
                isLoading: false,
              )
            else
              const SizedBox.shrink(),
              
            const SizedBox(height: AppTheme.spacingM),
            
            // Continue Button (enabled when any method is selected)
            if (_selectedMethod != null && _selectedMethod != ScanMethod.videoTwirl)
              PrimaryButton(
                label: 'Continue',
                onPressed: () => _proceedToCamera(),
                fullWidth: true,
                isLoading: false,
              )
            else
              const SizedBox.shrink(),
              
            if (_selectedMethod == null) ...[
              const SizedBox(height: AppTheme.spacingS),
              SecondaryButton(
                label: 'Skip for Now',
                onPressed: () => _skipMethodSelection(),
                fullWidth: true,
              ),
            ],
            
            const SizedBox(height: AppTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required ScanMethod method,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color iconColor,
    required String estimatedTime,
    required String requirements,
  }) {
    final isSelected = _selectedMethod == method;
    final borderColor = isSelected ? iconColor : Colors.transparent;
    final backgroundColor = isSelected 
        ? iconColor.withOpacity(0.1) 
        : AppTheme.surfaceWhite;
    final elevation = isSelected ? AppTheme.elevatedCardElevation : AppTheme.cardElevation;

    return AppCard(
      onTap: () => _selectMethod(method),
      elevation: elevation,
      backgroundColor: backgroundColor,
      borderRadius: AppTheme.majorCardsRadius,
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    if (subtitle == 'Recommended') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingS,
                          vertical: AppTheme.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                        ),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    _buildInfoChip(Icons.timer, estimatedTime),
                    const SizedBox(width: AppTheme.spacingS),
                    _buildInfoChip(Icons.check_circle, requirements),
                  ],
                ),
              ],
            ),
          ),
          
          // Selection indicator
          if (isSelected)
            Icon(
              Icons.check_circle,
              color: iconColor,
              size: 24,
            )
          else
            Icon(
              Icons.circle_outlined,
              color: Colors.grey.shade400,
              size: 24,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: AppTheme.spacingXs),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _selectMethod(ScanMethod method) {
    setState(() {
      _selectedMethod = method;
    });
  }

  void _proceedToCamera() {
    if (_selectedMethod == null) return;
    
    // Navigate to the camera capture screen (ScanWizard) using named route
    Navigator.of(context).pushNamed('/scan-wizard');
  }

  void _skipMethodSelection() {
    // Default to video twirl as recommended method
    setState(() {
      _selectedMethod = ScanMethod.videoTwirl;
    });
  }
}