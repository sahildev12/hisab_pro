import 'package:flutter/material.dart';

import '../constants/brand_assets.dart';

enum HisabLogoVariant {
  horizontal,
  horizontalTagline,
  stacked,
  stackedTagline,
  iconMark,
  appIcon,
}

class HisabLogo extends StatelessWidget {
  const HisabLogo({
    super.key,
    this.variant = HisabLogoVariant.horizontal,
    this.height = 32,
    this.width,
    this.fit = BoxFit.contain,
  });

  final HisabLogoVariant variant;
  final double height;
  final double? width;
  final BoxFit fit;

  String get _assetPath {
    switch (variant) {
      case HisabLogoVariant.horizontal:
        return BrandAssets.logoHorizontal;
      case HisabLogoVariant.horizontalTagline:
        return BrandAssets.logoHorizontalTagline;
      case HisabLogoVariant.stacked:
        return BrandAssets.logoStacked;
      case HisabLogoVariant.stackedTagline:
        return BrandAssets.logoStackedTagline;
      case HisabLogoVariant.iconMark:
        return BrandAssets.iconMark;
      case HisabLogoVariant.appIcon:
        return BrandAssets.appIcon;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      height: height,
      width: width,
      fit: fit,
      filterQuality: FilterQuality.high,
    );
  }
}
