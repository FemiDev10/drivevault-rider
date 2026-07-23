import 'package:flutter/material.dart';

/// DriveVault design-system colours, taken directly from the Figma variables.
/// Keep this file as the single source of truth for brand colours.
class AppColors {
  AppColors._();

  /// Primary brand blue — "Main Colour" in Figma.
  static const Color primary = Color(0xFF1A2A80);

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  /// Greys
  static const Color subTextGrey = Color(0xFF808080); // "sub text grey"
  static const Color grayPrimary = Color(0xFF7B7B7B); // "Gray-primary"
  static const Color textInsideCircle = Color(0xFF4D4D4D);
  static const Color stroke = Color(0xFFE6E6E6);

  /// Muted blue-grey used for supporting copy on outcome/empty screens.
  static const Color mutedText = Color(0xFF8A90A8);

  /// Semantic
  static const Color red = Color(0xFFFF3B30);
  static const Color redBg = Color(0x1AFF3B30); // 10% red
  static const Color green = Color(0xFF00853F);

  /// Neutral background for the web "device" backdrop.
  static const Color deviceBackdrop = Color(0xFFEDEDED);
}
