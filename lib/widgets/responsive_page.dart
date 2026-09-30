import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Limites e paddings padrão Dark & Gold para desktop e mobile.
abstract final class AppLayout {
  static const double clientMaxWidth = 1120;
  static const double adminMaxWidth = 1280;
  static const double formMaxWidth = 560;
  static const double compactBreakpoint = 700;
  static const double clientDesktopBreakpoint = 900;

  static bool isClientDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= clientDesktopBreakpoint;

  static EdgeInsets pagePadding(BuildContext context, {bool admin = false}) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < compactBreakpoint;
    if (admin) {
      return EdgeInsets.fromLTRB(
        compact ? 16 : 28,
        compact ? 12 : 20,
        compact ? 16 : 28,
        compact ? 16 : 28,
      );
    }
    return EdgeInsets.fromLTRB(
      compact ? 20 : 32,
      compact ? 12 : 20,
      compact ? 20 : 32,
      compact ? 24 : 32,
    );
  }

  /// Espaço inferior para não ficar sob a bottom nav no mobile.
  static double clientBottomInset(BuildContext context) =>
      isClientDesktop(context) ? 32 : 110;

  /// Ritmo mais denso no desktop (Operate) — não usar no mobile.
  static double desktopSectionGap(BuildContext context, {double mobile = 20}) =>
      isClientDesktop(context) ? 14 : mobile;
}

/// Centraliza o conteúdo e limita a largura no desktop.
///
/// Sempre ancora primeiro em um [SizedBox] com a largura **disponível** do pai
/// e só depois alinha um filho com largura explícita. Isso evita o colapso
/// para width 0 no Flutter Web (Align/Center + scrollables sem host).
class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.clientMaxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
    this.expand = false,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaWidth = MediaQuery.sizeOf(context).width;
        final rawAvailable = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : mediaWidth;
        final hostWidth = rawAvailable > 0 ? rawAvailable : mediaWidth;
        final contentWidth = math
            .min(hostWidth, maxWidth)
            .clamp(1.0, double.infinity);

        final hostHeight = expand && constraints.hasBoundedHeight
            ? constraints.maxHeight
            : null;

        Widget content = child;
        if (padding != null) {
          content = Padding(padding: padding!, child: content);
        }

        return SizedBox(
          width: hostWidth,
          height: hostHeight,
          child: Align(
            alignment: alignment,
            child: SizedBox(
              width: contentWidth,
              height: hostHeight,
              child: content,
            ),
          ),
        );
      },
    );
  }
}
