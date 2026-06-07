import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFFF8F8FF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F2FF);

  static const Color primary = Color(0xFF6657F0);
  static const Color primaryLight = Color(0xFF8D80FF);
  static const Color primaryDark = Color(0xFF3E35C8);
  static const Color accent = Color(0xFFFF9F43);
  static const Color ink = Color(0xFF101247);

  static const Color textPrimary = Color(0xFF111344);
  static const Color textSecondary = Color(0xFF747895);
  static const Color textTertiary = Color(0xFFA7ABC2);
  static const Color textHint = Color(0xFFC4C7D6);

  static const Color border = Color(0xFFE7E8F3);
  static const Color divider = Color(0xFFEEEFF7);

  static const Color study = Color(0xFF5D68F2);
  static const Color fitness = Color(0xFFFF8A3D);
  static const Color diet = Color(0xFFFFA33D);
  static const Color sleep = Color(0xFF7058F5);
  static const Color journal = Color(0xFFFF7EAA);

  static const Color success = Color(0xFF35C976);
  static const Color warning = Color(0xFFFFB13D);
  static const Color danger = Color(0xFFFF5A66);

  static const Color softPurple = Color(0xFFEDEBFF);
  static const Color softBlue = Color(0xFFEAF0FF);
  static const Color softGreen = Color(0xFFEAF8F0);
  static const Color softOrange = Color(0xFFFFF1DF);
  static const Color softPink = Color(0xFFFFEDF5);
  static const Color softGold = Color(0xFFFFF4D9);
  static const Color softLavender = Color(0xFFF0EDFF);
  static const Color lavender = Color(0xFF9B8FE8);
  static const Color lavenderDark = Color(0xFF7B6FD6);
  static const Color sleepPink = Color(0xFFFFB8C6);

  static const Color ratingActive = Color(0xFFFFB13D);
  static const Color ratingInactive = Color(0xFFDADDEB);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFFBD66), Color(0xFFFF873D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x10101344), blurRadius: 22, offset: Offset(0, 10)),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(color: Color(0x22101344), blurRadius: 30, offset: Offset(0, 16)),
  ];
}
