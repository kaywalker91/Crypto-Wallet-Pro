import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Single onboarding slide with icon, title, and description
class OnboardingSlide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;

  const OnboardingSlide({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with glow effect
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconColor.withOpacity(0.2),
                  AppColors.secondary.withOpacity(0.1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 64,
              color: iconColor,
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            title,
            style: AppTypography.onboardingTitle,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            description,
            style: AppTypography.onboardingDescription,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Data model for onboarding slides
class OnboardingSlideData {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;

  const OnboardingSlideData({
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor = AppColors.primary,
  });
}

/// Predefined onboarding slides
class OnboardingSlides {
  OnboardingSlides._();

  static const List<OnboardingSlideData> slides = [
    OnboardingSlideData(
      icon: Icons.lock_outline,
      title: 'Secure Wallet',
      description:
          'Your private keys are encrypted and stored locally. Only you have access to your crypto assets.',
      iconColor: AppColors.primary,
    ),
    OnboardingSlideData(
      icon: Icons.language,
      title: 'Connect to dApps',
      description:
          'Use WalletConnect to securely connect to thousands of decentralized applications from anywhere.',
      iconColor: AppColors.secondary,
    ),
    OnboardingSlideData(
      icon: Icons.collections_outlined,
      title: 'NFT Gallery',
      description:
          'View and manage your NFT collection in a beautiful gallery. Support for ERC-721 and ERC-1155.',
      iconColor: AppColors.success,
    ),
  ];
}
