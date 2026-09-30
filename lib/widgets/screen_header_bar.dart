import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../views/admin/widgets/admin_ui.dart';
import '../views/admin/widgets/admin_visuals.dart';

/// Cabeçalho padrão de tela — delega ao kit Operate do admin.
class ScreenHeaderBar extends StatelessWidget {
  const ScreenHeaderBar({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.showBackButton = false,
    this.trailing,
    this.padding,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final bool showBackButton;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final resolvedSubtitle = subtitle ?? eyebrow;

    return AdminPageHeader(
      title: title,
      subtitle: resolvedSubtitle,
      showBack: showBackButton,
      trailing: trailing,
      padding: padding ?? EdgeInsets.zero,
    );
  }
}

/// Botão de ação para trailing do cabeçalho admin.
class HeaderActionButton extends StatelessWidget {
  const HeaderActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: AdminVisuals.insetSurface(context, radius: 12),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, size: 18, color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
