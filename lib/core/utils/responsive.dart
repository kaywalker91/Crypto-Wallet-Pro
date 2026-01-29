import 'package:flutter/material.dart';

enum ScreenSize { compact, medium, expanded }

class Responsive {
  Responsive._();

  static const double _compactMax = 600;
  static const double _mediumMax = 1024;

  static ScreenSize screenSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < _compactMax) return ScreenSize.compact;
    if (width < _mediumMax) return ScreenSize.medium;
    return ScreenSize.expanded;
  }

  static double maxContentWidth(BuildContext context) {
    switch (screenSize(context)) {
      case ScreenSize.compact:
        return double.infinity;
      case ScreenSize.medium:
        return 720;
      case ScreenSize.expanded:
        return 840;
    }
  }

  static double sheetMaxWidth(BuildContext context) {
    switch (screenSize(context)) {
      case ScreenSize.compact:
        return double.infinity;
      case ScreenSize.medium:
      case ScreenSize.expanded:
        return 560;
    }
  }

  static double horizontalPadding(BuildContext context) {
    switch (screenSize(context)) {
      case ScreenSize.compact:
        return 16;
      case ScreenSize.medium:
        return 24;
      case ScreenSize.expanded:
        return 32;
    }
  }

  static double verticalPadding(BuildContext context) {
    switch (screenSize(context)) {
      case ScreenSize.compact:
        return 16;
      case ScreenSize.medium:
        return 20;
      case ScreenSize.expanded:
        return 24;
    }
  }

  static double sectionSpacing(BuildContext context) {
    switch (screenSize(context)) {
      case ScreenSize.compact:
        return 12;
      case ScreenSize.medium:
        return 16;
      case ScreenSize.expanded:
        return 20;
    }
  }
}

extension ResponsiveContext on BuildContext {
  ScreenSize get screenSize => Responsive.screenSize(this);
  bool get isCompact => screenSize == ScreenSize.compact;
  bool get isMedium => screenSize == ScreenSize.medium;
  bool get isExpanded => screenSize == ScreenSize.expanded;
  double get maxContentWidth => Responsive.maxContentWidth(this);
  double get sheetMaxWidth => Responsive.sheetMaxWidth(this);
  double get horizontalPadding => Responsive.horizontalPadding(this);
  double get verticalPadding => Responsive.verticalPadding(this);
  double get sectionSpacing => Responsive.sectionSpacing(this);
}
