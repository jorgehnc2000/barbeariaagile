import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color background = Color(0xFF121212);
  static const Color card = Color(0xFF1E1E1E);
  static const Color backgroundElevated = Color(0xFF1E1E1E);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color border = Color(0xFF2A2A2A);
  static const Color surfaceLight = Color(0xFF3A3A3A);

  static const Color primary = Color(0xFFD4AF37);
  static const Color primaryBright = Color(0xFFFFB300);
  static const Color primaryDark = Color(0xFFB8962E);

  /// Alias do ouro de marca — evita amarelo `#FFC107` desalinhado.
  static const Color accentGold = primary;

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF999999);
  static const Color textMuted = Color(0xFF777777);

  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);

  static const Color glassFill = Color(0xE61E1E1E);
  static const Color glassBorder = Color(0x33D4AF37);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBright, primaryDark],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, background],
  );

  static const LinearGradient vipShowcase = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF352A12), Color(0xFF1E1808), Color(0xFF141414)],
  );

  static const LinearGradient heroWarm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3D3210), Color(0xFF1A1408), Color(0xFF121212)],
  );

  static List<BoxShadow> spotlight({double dy = 8, double blur = 24}) => [
    BoxShadow(
      color: primary.withValues(alpha: 0.3),
      blurRadius: blur,
      offset: Offset(0, dy),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.38),
      blurRadius: blur * 0.65,
      offset: Offset(0, dy * 0.45),
    ),
  ];

  static BoxDecoration showcaseCard({
    double radius = 16,
    bool goldRim = false,
    bool elevated = false,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      gradient: gradient,
      color: gradient == null ? card : null,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: goldRim
            ? primary.withValues(alpha: 0.5)
            : border,
        width: goldRim ? 1.4 : 1,
      ),
      boxShadow: elevated ? spotlight(dy: 6, blur: 20) : null,
    );
  }
}
