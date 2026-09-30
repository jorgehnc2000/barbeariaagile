import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/customer/atelier_shell.dart';
import '../../../widgets/operate/operate_kit.dart';
import 'admin_elite_kit.dart';

export '../../../widgets/operate/operate_kit.dart'
    show
        BrandScope,
        BrandMark,
        StatItem,
        OperateBreakpoints,
        operateGreeting;

export 'admin_elite_kit.dart'
    show
        AdminEliteVisuals,
        ElitePageHeader,
        ElitePanel,
        EliteStatCard,
        EliteStatsRail,
        EliteInkEdgeButton,
        EliteOutlineButton,
        EliteDangerButton,
        EliteGhostAction,
        EliteIconGhostAction,
        EliteStatusBadge,
        EliteStatusToggle;

typedef AdminBrandScope = BrandScope;
typedef AdminBrandMark = BrandMark;
typedef AdminStatItem = StatItem;
typedef AdminBreakpoints = OperateBreakpoints;

String adminGreeting() => operateGreeting();

/// Skin do painel admin: Elite no desktop (≥900), Midnight Atelier/Operate no mobile.
abstract final class AdminVisuals {
  AdminVisuals._();

  static bool isElite(BuildContext context) =>
      OperateBreakpoints.isDesktop(context);

  static BoxDecoration surface(
    BuildContext context, {
    Color? background,
    double radius = 16,
  }) {
    if (isElite(context)) {
      return AdminEliteVisuals.surface(background: background, radius: radius);
    }
    return OperateVisuals.surface(background: background, radius: radius);
  }

  /// Desktop: glass Elite. Mobile: superfície flat Atelier.
  static BoxDecoration glass(
    BuildContext context, {
    double radius = 12,
    Color? borderColor,
  }) {
    if (isElite(context)) {
      return AdminEliteVisuals.glass(radius: radius, borderColor: borderColor);
    }
    return OperateVisuals.surface(radius: radius);
  }

  static BoxDecoration insetSurface(
    BuildContext context, {
    double radius = 14,
  }) {
    if (isElite(context)) {
      return AdminEliteVisuals.insetSurface(radius: radius);
    }
    return OperateVisuals.insetSurface(radius: radius);
  }

  static BoxDecoration navItem(
    BuildContext context, {
    required bool selected,
  }) {
    if (isElite(context)) {
      return AdminEliteVisuals.navItem(selected: selected);
    }
    return OperateVisuals.navItem(selected: selected);
  }

  static Widget navAccent(
    BuildContext context, {
    required bool selected,
  }) {
    if (isElite(context)) {
      return AdminEliteVisuals.navAccent(selected: selected);
    }
    return OperateVisuals.navAccent(selected: selected);
  }

  static List<BoxShadow>? goldGlow(
    BuildContext context, {
    double alpha = 0.16,
  }) {
    if (!isElite(context)) return null;
    return AdminEliteVisuals.goldGlow(alpha: alpha);
  }

  static TextStyle sectionLabel(
    BuildContext context, {
    double opacity = 0.8,
  }) {
    if (isElite(context)) {
      return AdminEliteVisuals.sectionLabel(opacity: opacity);
    }
    return TextStyle(
      color: AppColors.textMuted.withValues(alpha: opacity),
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
  }

  static Color deepFill(BuildContext context) => isElite(context)
      ? AdminEliteVisuals.surfaceDeep
      : AppColors.background;

  static Color goldContainer(BuildContext context) => isElite(context)
      ? AdminEliteVisuals.goldContainer
      : AppColors.primary;

  static Color onGoldContainer(BuildContext context) => isElite(context)
      ? AdminEliteVisuals.onGoldContainer
      : AppColors.background;
}

/// Header: Elite no desktop, Operate no mobile.
class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showBack = false,
    this.padding = EdgeInsets.zero,
    this.showBrandGreeting = false,
    this.showBrandMark = false,
    this.greetingName,
    this.kicker,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showBack;
  final EdgeInsetsGeometry padding;
  final bool showBrandGreeting;
  final bool showBrandMark;
  final String? greetingName;
  final String? kicker;

  @override
  Widget build(BuildContext context) {
    if (AdminVisuals.isElite(context)) {
      return ElitePageHeader(
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        showBack: showBack,
        padding: padding,
        showBrandGreeting: showBrandGreeting,
        showBrandMark: showBrandMark,
        greetingName: greetingName,
        kicker: kicker,
      );
    }
    return OperatePageHeader(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      showBack: showBack,
      padding: padding,
      showBrandGreeting: showBrandGreeting,
      showBrandMark: showBrandMark,
      greetingName: greetingName,
    );
  }
}

/// Panel: Elite no desktop, Operate no mobile.
class AdminPanel extends StatelessWidget {
  const AdminPanel({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.kicker,
  });

  final String title;
  final Widget child;
  final Widget? action;
  final String? kicker;

  @override
  Widget build(BuildContext context) {
    if (AdminVisuals.isElite(context)) {
      return ElitePanel(
        title: title,
        action: action,
        kicker: kicker,
        child: child,
      );
    }
    return OperatePanel(title: title, action: action, child: child);
  }
}

/// Stats: Elite no desktop, Operate no mobile.
class AdminStatsRail extends StatelessWidget {
  const AdminStatsRail({super.key, required this.items});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    if (AdminVisuals.isElite(context)) {
      return EliteStatsRail(items: items);
    }
    return StatsRail(items: items);
  }
}

/// CTA admin: Ink Edge no desktop, ouro filled (Atelier) no mobile.
class AdminPrimaryButton extends StatelessWidget {
  const AdminPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    if (AdminVisuals.isElite(context)) {
      return EliteInkEdgeButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        isLoading: isLoading,
        expand: expand,
      );
    }
    return AtelierGoldButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      expand: expand,
      height: 48,
      fontSize: 13,
      weight: AtelierButtonWeight.compact,
      leading: icon == null
          ? null
          : Icon(icon, size: 18, color: AppColors.background),
    );
  }
}

/// Outline CTA: Elite no desktop, borda ouro flat no mobile.
class AdminOutlineButton extends StatelessWidget {
  const AdminOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.destructive = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool destructive;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (AdminVisuals.isElite(context)) {
      return EliteOutlineButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        expand: expand,
        destructive: destructive,
        isLoading: isLoading,
      );
    }
    final enabled = onPressed != null && !isLoading;
    final color = destructive ? AppColors.error : AppColors.primary;
    final style = OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: enabled ? 0.55 : 0.3)),
      minimumSize: Size(expand ? double.infinity : 0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    final labelWidget = Text(isLoading ? '…' : label);
    final child = icon == null
        ? OutlinedButton(
            onPressed: enabled ? onPressed : null,
            style: style,
            child: labelWidget,
          )
        : OutlinedButton.icon(
            onPressed: enabled ? onPressed : null,
            icon: Icon(icon, size: 18),
            label: labelWidget,
            style: style,
          );
    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

/// Danger CTA: Elite no desktop, filled erro no mobile.
class AdminDangerButton extends StatelessWidget {
  const AdminDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (AdminVisuals.isElite(context)) {
      return EliteDangerButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        expand: expand,
        isLoading: isLoading,
      );
    }
    final enabled = onPressed != null && !isLoading;
    final style = FilledButton.styleFrom(
      backgroundColor: AppColors.error,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.error.withValues(alpha: 0.4),
      minimumSize: Size(expand ? double.infinity : 0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    final labelWidget = Text(isLoading ? '…' : label);
    final child = icon == null
        ? FilledButton(
            onPressed: enabled ? onPressed : null,
            style: style,
            child: labelWidget,
          )
        : FilledButton.icon(
            onPressed: enabled ? onPressed : null,
            style: style,
            icon: Icon(icon, size: 18),
            label: labelWidget,
          );
    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    if (AdminVisuals.isElite(context)) {
      return EliteStatusBadge(active: active);
    }
    final color = active ? AppColors.success : AppColors.textMuted;
    return Text(
      active ? 'Ativo' : 'Inativo',
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class AdminStatusToggle extends StatelessWidget {
  const AdminStatusToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel = 'Disponibilidade',
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (AdminVisuals.isElite(context)) {
      return EliteStatusToggle(
        value: value,
        onChanged: onChanged,
        semanticLabel: semanticLabel,
      );
    }
    return Semantics(
      label: semanticLabel,
      toggled: value,
      child: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
      ),
    );
  }
}

class AdminGhostAction extends StatelessWidget {
  const AdminGhostAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    if (AdminVisuals.isElite(context)) {
      return EliteGhostAction(
        label: label,
        icon: icon,
        onPressed: onPressed,
        destructive: destructive,
      );
    }
    final color = destructive ? AppColors.error : AppColors.textSecondary;
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
    );
  }
}

class AdminIconGhostAction extends StatelessWidget {
  const AdminIconGhostAction({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.destructive = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    if (AdminVisuals.isElite(context)) {
      return EliteIconGhostAction(
        icon: icon,
        onPressed: onPressed,
        tooltip: tooltip,
        destructive: destructive,
      );
    }
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(
        icon,
        size: 20,
        color: destructive ? AppColors.error : AppColors.textMuted,
      ),
    );
  }
}
