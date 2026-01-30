import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glassmorphic_card.dart';
import '../../../../core/widgets/app_logo.dart';

/// About page showing app information, team, and links
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverToBoxAdapter(
                child: _buildAppBar(context),
              ),
              // Header with logo
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              // App Info Section
              SliverToBoxAdapter(
                child: _buildAppInfoSection(),
              ),
              // Links Section
              SliverToBoxAdapter(
                child: _buildLinksSection(context),
              ),
              // Team Section
              SliverToBoxAdapter(
                child: _buildTeamSection(),
              ),
              // Footer
              SliverToBoxAdapter(
                child: _buildFooter(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'About',
            style: AppTypography.textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: GlassmorphicAccentCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // App logo with glow effect
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const AppLogo(size: 72),
            ),
            const SizedBox(height: 16),
            Text(
              'Crypto Wallet Pro',
              style: AppTypography.textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Version 1.0.0',
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Secure Ethereum Wallet',
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('App Information'),
          const SizedBox(height: 12),
          GlassmorphicCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.verified_rounded,
                  'Features',
                  'ETH, ERC-20 Tokens, NFTs',
                  AppColors.success,
                ),
                const Divider(color: AppColors.cardBorder, height: 24),
                _buildInfoRow(
                  Icons.security_rounded,
                  'Security',
                  'Biometric & PIN Protection',
                  AppColors.primary,
                ),
                const Divider(color: AppColors.cardBorder, height: 24),
                _buildInfoRow(
                  Icons.link_rounded,
                  'Connectivity',
                  'WalletConnect v2 Support',
                  AppColors.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Links'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LinkCard(
                  icon: Icons.code,
                  title: 'GitHub',
                  color: const Color(0xFF6E5494),
                  onTap: () => _launchUrl('https://github.com'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LinkCard(
                  icon: Icons.language,
                  title: 'Website',
                  color: AppColors.primary,
                  onTap: () => _launchUrl('https://example.com'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LinkCard(
                  icon: Icons.alternate_email,
                  title: 'Twitter',
                  color: const Color(0xFF1DA1F2),
                  onTap: () => _launchUrl('https://twitter.com'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LinkCard(
                  icon: Icons.star_rounded,
                  title: 'Rate App',
                  color: AppColors.warning,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Rating feature coming soon!'),
                        backgroundColor: AppColors.surface,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Development Team'),
          const SizedBox(height: 12),
          GlassmorphicCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Made with ❤️',
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'For learning and building awesome crypto experiences',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Center(
        child: Column(
          children: [
            Text(
              '© 2025 Crypto Wallet Pro',
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All rights reserved',
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textTertiary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _LinkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _LinkCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
