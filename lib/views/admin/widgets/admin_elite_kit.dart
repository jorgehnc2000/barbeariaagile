import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/operate/operate_kit.dart';

/// Visual AgendaElite — tokens e componentes do painel admin.
abstract final class AdminEliteVisuals {
  AdminEliteVisuals._();

  static const Color surfaceDeep = Color(0xFF121414);
  static const Color goldContainer = Color(0xFFAF8D11);
  static const Color onGoldContainer = Color(0xFF342800);

  static BoxDecoration glass({double radius = 12, Color? borderColor}) {
    return BoxDecoration(
      color: surfaceDeep.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.1),
        width: 0.5,
      ),
    );
  }

  static BoxDecoration surface({Color? background, double radius = 16}) {
    if (background != null) {
      return BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
      );
    }
    return glass(radius: radius);
  }

  static BoxDecoration insetSurface({double radius = 14}) {
    return BoxDecoration(
      color: surfaceDeep.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
    );
  }

  static BoxDecoration navItem({required bool selected}) {
    if (!selected) return const BoxDecoration();
    return BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
    );
  }

  static Widget navAccent({required bool selected}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 3,
      height: 20,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(2),
        boxShadow: selected ? goldGlow(alpha: 0.35) : null,
      ),
    );
  }

  static List<BoxShadow> goldGlow({double alpha = 0.16}) => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: alpha),
          blurRadius: 14,
        ),
      ];

  static TextStyle sectionLabel({double opacity = 0.8}) => TextStyle(
        color: AppColors.textMuted.withValues(alpha: opacity),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
      );

  static TextStyle panelTitle({bool desktop = false}) => TextStyle(
        color: AppColors.textPrimary,
        fontSize: desktop ? 20 : 18,
        fontWeight: FontWeight.w600,
        height: 1.15,
      );
}

class ElitePageHeader extends StatelessWidget {
  const ElitePageHeader({
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
    final desktop = OperateBreakpoints.isDesktop(context);
    final brand = BrandScope.maybeOf(context);
    final greetingTarget = greetingName ??
        (showBrandGreeting ? BrandScope.shopName(context) : null);
    final resolvedKicker = kicker ??
        (greetingTarget != null
            ? '${operateGreeting()}, $greetingTarget'.toUpperCase()
            : null);

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resolvedKicker != null) ...[
          Text(
            resolvedKicker,
            style: AdminEliteVisuals.sectionLabel(opacity: 0.75),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: desktop ? 32 : 26,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
        if (brand != null && showBrandMark) ...[
          const SizedBox(height: 10),
          BrandMark(
            brand: brand,
            compact: true,
            subtitle: brand.address.trim().isNotEmpty
                ? brand.address.trim()
                : null,
          ),
        ],
      ],
    );

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackTrailing = trailing != null && constraints.maxWidth < 560;

          if (stackTrailing) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showBack) ...[
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(child: titleBlock),
                  ],
                ),
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerLeft, child: trailing),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBack) ...[
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(child: titleBlock),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                // Largura intrínseca — o título cede espaço, o CTA não esmaga.
                trailing!,
              ],
            ],
          );
        },
      ),
    );
  }
}

/// CTA admin Ink Edge (opção B): outline ouro, Operate, Soft Forge 14.
class EliteInkEdgeButton extends StatelessWidget {
  const EliteInkEdgeButton({
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
    final enabled = onPressed != null && !isLoading;
    final ink = enabled
        ? AppColors.primary
        : AppColors.primary.withValues(alpha: 0.45);

    final labelStyle = TextStyle(
      color: ink,
      fontWeight: FontWeight.w700,
      fontSize: 14,
      height: 1.2,
    );

    final inner = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: ink),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: ink),
                const SizedBox(width: 10),
              ],
              if (expand)
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: labelStyle,
                  ),
                )
              else
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: labelStyle,
                ),
            ],
          );

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: enabled ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: enabled ? 0.7 : 0.35),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 128),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 48,
                child: Center(child: inner),
              ),
            ),
          ),
        ),
      ),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// Outline secundário Soft Forge — Voltar / Cancelar / Editar em row.
class EliteOutlineButton extends StatelessWidget {
  const EliteOutlineButton({
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
    final enabled = onPressed != null && !isLoading;
    final fg = destructive
        ? (enabled ? AppColors.error : AppColors.error.withValues(alpha: 0.45))
        : (enabled
            ? AppColors.textPrimary
            : AppColors.textMuted.withValues(alpha: 0.5));
    final border = destructive
        ? AppColors.error.withValues(alpha: enabled ? 0.45 : 0.2)
        : Colors.white.withValues(alpha: enabled ? 0.14 : 0.08);

    final labelStyle = TextStyle(
      color: fg,
      fontWeight: FontWeight.w700,
      fontSize: 14,
      height: 1.2,
    );

    final inner = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 10),
              ],
              if (expand)
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: labelStyle,
                  ),
                )
              else
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: labelStyle,
                ),
            ],
          );

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 96),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SizedBox(height: 48, child: Center(child: inner)),
            ),
          ),
        ),
      ),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// Confirmação destrutiva Soft Forge (cancelar / excluir).
class EliteDangerButton extends StatelessWidget {
  const EliteDangerButton({
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
    final enabled = onPressed != null && !isLoading;

    final labelStyle = TextStyle(
      color: Colors.white.withValues(alpha: enabled ? 1 : 0.7),
      fontWeight: FontWeight.w700,
      fontSize: 14,
      height: 1.2,
    );

    final inner = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 10),
              ],
              if (expand)
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: labelStyle,
                  ),
                )
              else
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: labelStyle,
                ),
            ],
          );

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: enabled ? 1 : 0.45),
            borderRadius: BorderRadius.circular(14),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 128),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(height: 48, child: Center(child: inner)),
            ),
          ),
        ),
      ),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

class ElitePanel extends StatelessWidget {
  const ElitePanel({
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
    final desktop = OperateBreakpoints.isDesktop(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: AdminEliteVisuals.glass(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (kicker != null) ...[
                      Text(kicker!, style: AdminEliteVisuals.sectionLabel()),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      title,
                      style: AdminEliteVisuals.panelTitle(desktop: desktop),
                    ),
                  ],
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class EliteStatCard extends StatelessWidget {
  const EliteStatCard({
    super.key,
    required this.label,
    required this.value,
    this.hint,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final String? hint;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: AdminEliteVisuals.glass(radius: 12).copyWith(
        boxShadow: emphasize ? AdminEliteVisuals.goldGlow(alpha: 0.1) : null,
        border: Border.all(
          color: emphasize
              ? AppColors.primary.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AdminEliteVisuals.sectionLabel(opacity: 0.7),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: emphasize ? AppColors.primary : AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              height: 1.1,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EliteStatsRail extends StatelessWidget {
  const EliteStatsRail({super.key, required this.items});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = width >= 900
            ? math.min(4, items.length)
            : width >= 560
            ? 2
            : 1;
        final gap = 12.0;
        final cardWidth = cols == 0
            ? width
            : (width - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < items.length; i++)
              SizedBox(
                width: cardWidth,
                child: EliteStatCard(
                  label: items[i].label,
                  value: items[i].value,
                  hint: items[i].hint,
                  emphasize: i == 0,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Badge de status (Ativo / Inativo) — Soft Forge.
class EliteStatusBadge extends StatelessWidget {
  const EliteStatusBadge({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.success : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: active ? 0.25 : 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Ativo' : 'Inativo',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Toggle custom (sem Switch Material em caixinha).
class EliteStatusToggle extends StatelessWidget {
  const EliteStatusToggle({
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
    return Semantics(
      label: semanticLabel,
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 44,
          height: 26,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: value
                ? AppColors.primary.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: value
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.12),
              width: 0.5,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? AppColors.primary : const Color(0xFF999999),
                shape: BoxShape.circle,
                boxShadow: value
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ação quieta (Editar / Remover) — texto + ícone, sem outlined.
class EliteGhostAction extends StatelessWidget {
  const EliteGhostAction({
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
    final idle = destructive
        ? AppColors.textMuted.withValues(alpha: 0.7)
        : AppColors.textMuted;
    final hover = destructive ? AppColors.error : AppColors.primary;

    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: idle,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ).copyWith(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return hover;
          }
          return idle;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return destructive
                ? AppColors.error.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05);
          }
          return Colors.transparent;
        }),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Ícone ghost 36×36 — ações densas em lista.
class EliteIconGhostAction extends StatelessWidget {
  const EliteIconGhostAction({
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
    final idle = destructive
        ? AppColors.textMuted.withValues(alpha: 0.6)
        : AppColors.textMuted;
    final hover = destructive ? AppColors.error : AppColors.primary;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(
          foregroundColor: idle,
          minimumSize: const Size(36, 36),
          maximumSize: const Size(36, 36),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ).copyWith(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return hover;
            }
            return idle;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return destructive
                  ? AppColors.error.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.05);
            }
            return Colors.transparent;
          }),
        ),
      ),
    );
  }
}
