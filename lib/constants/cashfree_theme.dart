import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cashfree_pg_sdk/api/cftheme/cftheme.dart';
import 'package:shareperks/constants/fonts.dart';
import 'package:shareperks/constants/theme_data.dart';
import 'package:soui/theme.dart';

/// Cashfree PG checkout styling aligned with SharePerks brand tokens.
abstract final class SharePerksCashfreeTheme {
  SharePerksCashfreeTheme._();

  static const Color brand = AppColors.brand;

  /// System status bar while Cashfree checkout is open (brand purple, light icons).
  static const SystemUiOverlayStyle statusBarOverlay = SystemUiOverlayStyle(
    statusBarColor: brand,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: brand,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static CFTheme get checkout => CFThemeBuilder()
      .setBackgroundColor(_hex(SharePerksColors.backgroundLight))
      .setPrimaryTextColor(_hex(SharePerksColors.textPrimaryLight))
      .setSecondaryTextColor(_hex(SharePerksColors.textSecondaryLight))
      .setNavigationBarBackgroundColorColor(_hex(brand))
      .setNavigationBarTextColor(_hex(Colors.white))
      .setButtonBackgroundColor(_hex(SharePerksColors.accent))
      .setButtonTextColor(_hex(Colors.white))
      .setPrimaryFont(SharePerksFonts.inter)
      .setSecondaryFont(SharePerksFonts.albertSans)
      .build();

  static String _hex(Color color) {
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
