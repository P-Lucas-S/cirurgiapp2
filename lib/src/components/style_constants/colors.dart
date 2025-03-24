// colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Cores principais
  static const Color primary = Color(0xFF124477);
  static const Color background = Color(0xFFF9F9F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFF64848);

  // Cores de texto
  static const Color onPrimary = Color(0xFFF9F9F9);
  static const Color onBackground = Color(0xFF050505);
  static const Color onSurface = Color(0xFF050505);

  // Cores de ação
  static const Color pressedBlue = Color(0xFF0E2A47);
  static const Color pressedWhite = Color(0xFFD1D1D1);

  // Campos de texto
  static const Color textFieldDark = Color(0xFF25578B);
  static const Color textFieldLight = Color(0xFFBFDEFF);

  // Status
  static const Color success = Color(0xFF60F648);
  static const Color warning = Color(0xFFFFE663);

  // Chat
  static const Color chatSender = Color(0xFF97CAFF);
  static const Color chatReceiver = Color(0xFFEEF6FF);
  static const Color chatDate = Color(0xCC124477);
}

// Para manter compatibilidade com código existente (remover gradualmente)
const Color MY_WHITE = AppColors.background;
const Color MY_BLACK = AppColors.onBackground;
const Color MY_BLUE = AppColors.primary;
const Color MY_RED = AppColors.error;
const Color MY_GREEN = AppColors.success;
const Color MY_YELLOW = AppColors.warning;
const Color TEXT_FIELD_COLOR_LIGHT = AppColors.textFieldLight;
const Color TEXT_FIELD_COLOR_DARK = AppColors.textFieldDark;
