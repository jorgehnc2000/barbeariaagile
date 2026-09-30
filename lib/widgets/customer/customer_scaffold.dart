import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../responsive_page.dart';
import 'atelier_shell.dart';

/// Scaffold padrão das telas satélite do cliente (login, assinatura, etc.).
class CustomerScaffold extends StatelessWidget {
  const CustomerScaffold({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.clientMaxWidth,
    this.padding,
    this.center = false,
    this.showBack = false,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool center;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final resolvedPadding =
        padding ?? AppLayout.pagePadding(context).copyWith(top: 12);

    Widget content = ResponsivePage(
      maxWidth: maxWidth,
      padding: resolvedPadding,
      child: child,
    );

    if (center) {
      content = Center(
        child: SingleChildScrollView(
          child: content,
        ),
      );
    } else {
      content = SingleChildScrollView(child: content);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AtelierShellBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showBack)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }
}
