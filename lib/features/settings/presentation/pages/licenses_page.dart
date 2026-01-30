import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glassmorphic_card.dart';
import '../../../../core/widgets/app_logo.dart';

/// Custom licenses page with Glassmorphism design
/// Replaces the default Flutter showLicensePage
class LicensesPage extends StatefulWidget {
  const LicensesPage({super.key});

  @override
  State<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends State<LicensesPage> {
  final _searchController = TextEditingController();
  Map<String, List<LicenseEntry>> _groupedLicenses = {};
  List<String> _sortedPackageNames = [];
  List<String> _filteredPackageNames = [];
  bool _isLoading = true;
  String? _expandedPackage;

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLicenses() async {
    final licenses = <LicenseEntry>[];
    await for (final license in LicenseRegistry.licenses) {
      licenses.add(license);
    }

    final grouped = <String, List<LicenseEntry>>{};
    for (final license in licenses) {
      for (final package in license.packages) {
        grouped.putIfAbsent(package, () => []).add(license);
      }
    }

    final sortedNames = grouped.keys.toList()..sort();

    if (mounted) {
      setState(() {
        _groupedLicenses = grouped;
        _sortedPackageNames = sortedNames;
        _filteredPackageNames = sortedNames;
        _isLoading = false;
      });
    }
  }

  void _filterPackages(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPackageNames = _sortedPackageNames;
      } else {
        _filteredPackageNames = _sortedPackageNames
            .where((name) => name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader()),
                        SliverToBoxAdapter(child: _buildSearchBar()),
                        SliverToBoxAdapter(child: _buildPackageCount()),
                        _buildLicensesList(),
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
            ),
          ],
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
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
          Text(
            'Open Source Licenses',
            style: AppTypography.textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Loading licenses...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: GlassmorphicAccentCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const AppLogo(size: 48),
            const SizedBox(height: 12),
            Text(
              'Crypto Wallet Pro',
              style: AppTypography.textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '© 2025 Development Team',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _filterPackages,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search packages...',
            hintStyle: TextStyle(color: AppColors.textTertiary),
            prefixIcon: Icon(Icons.search, color: AppColors.textTertiary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: AppColors.textTertiary),
                    onPressed: () {
                      _searchController.clear();
                      _filterPackages('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCount() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Icon(Icons.folder_open, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          Text(
            '${_filteredPackageNames.length} packages',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicensesList() {
    if (_filteredPackageNames.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.search_off, size: 48, color: AppColors.textTertiary),
                const SizedBox(height: 12),
                Text(
                  'No packages found',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final packageName = _filteredPackageNames[index];
          final isExpanded = _expandedPackage == packageName;
          final licenses = _groupedLicenses[packageName] ?? [];

          return _buildLicenseCard(packageName, licenses, isExpanded);
        },
        childCount: _filteredPackageNames.length,
      ),
    );
  }

  Widget _buildLicenseCard(String packageName, List<LicenseEntry> licenses, bool isExpanded) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GlassmorphicCard(
        padding: EdgeInsets.zero,
        onTap: () {
          setState(() {
            _expandedPackage = isExpanded ? null : packageName;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.extension,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          packageName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${licenses.length} license${licenses.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildLicenseContent(licenses),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseContent(List<LicenseEntry> licenses) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < licenses.length; i++) ...[
              if (i > 0) const Divider(color: AppColors.cardBorder, height: 24),
              ...licenses[i].paragraphs.map((paragraph) {
                if (paragraph.indent == LicenseParagraph.centeredIndent) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Center(
                      child: Text(
                        paragraph.text,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: EdgeInsets.only(
                    left: paragraph.indent * 16.0,
                    top: 4,
                    bottom: 4,
                  ),
                  child: Text(
                    paragraph.text,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      height: 1.5,
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
