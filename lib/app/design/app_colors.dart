import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFFF8FAF7);
  static const Color paper = Color(0xFFFFFCF7);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF2F5F0);
  static const Color surfaceTint = Color(0xFFF6F8F3);

  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF7C83FF);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color accent = Color(0xFFD97706);
  static const Color ink = Color(0xFF172033);

  static const Color textPrimary = Color(0xFF172033);
  static const Color textSecondary = Color(0xFF4F5B6D);
  static const Color textTertiary = Color(0xFF7B8494);
  static const Color textHint = Color(0xFFAAB2BE);
  static const Color textDisabled = Color(0xFFAAB2BE);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE4E8DF);
  static const Color divider = Color(0xFFEEF1EA);

  static const Color study = Color(0xFF3757D7);
  static const Color fitness = Color(0xFFC95F1E);
  static const Color diet = Color(0xFFB66A00);
  static const Color sleep = Color(0xFF5B4BC4);
  static const Color journal = Color(0xFFC84676);
  static const Color focus = Color(0xFF0F766E);

  static const Color success = Color(0xFF168458);
  static const Color warning = Color(0xFFB7791F);
  static const Color danger = Color(0xFFC2413A);

  // Knowledge card system colors
  static const Color knowledgeBg = Color(0xFFF7F8FC);
  static const Color knowledgePrimary = Color(0xFF5B7CFA);
  static const Color weakRed = Color(0xFFFF7A7A);
  static const Color dueOrange = Color(0xFFFFB45C);
  static const Color masteredGreen = Color(0xFF4CC9A7);

  static const Color softPurple = Color(0xFFF1EFFF);
  static const Color softBlue = Color(0xFFEEF3FF);
  static const Color softGreen = Color(0xFFEAF7F4);
  static const Color softOrange = Color(0xFFFFF1E7);
  static const Color softPink = Color(0xFFFFF0F5);
  static const Color softGold = Color(0xFFFFF6E8);
  static const Color softLavender = Color(0xFFF1EFFF);
  static const Color lavender = Color(0xFF6E64D9);
  static const Color lavenderDark = Color(0xFF4F46B8);
  static const Color sleepPink = Color(0xFFF7B8C6);
  static const Color info = Color(0xFF2563EB);

  static const Color ratingActive = Color(0xFFB7791F);
  static const Color ratingInactive = Color(0xFFD9DED4);

  static const Color settingsAccent = primary;
  static const Color settingsAccentSoft = softBlue;

  static const Color dashboardGradientTop = Color(0xFFFFFCF7);
  static const Color dashboardGradientMid = Color(0xFFF7FAF3);
  static const Color dashboardGradientBottom = Color(0xFFFFFFFF);
  static const Color dashboardChipBorder = Color(0xFFEAEDE5);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF5A04F), fitness],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient settingsGradient = LinearGradient(
    colors: [Color(0xFF5C7CFA), primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x14172033), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(color: Color(0x24172033), blurRadius: 28, offset: Offset(0, 14)),
  ];

  static const List<Color> chartPalette = [
    primary,
    study,
    fitness,
    diet,
    sleep,
    danger,
    success,
  ];
}
