import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../responsive_page.dart';

/// Responsive visual tiers for the customer shell.
///
/// - **operate** (mobile default): flat cards, no glow — task-first.
/// - **showcase** (desktop): gold rim + spotlight where earned.
/// - **peak** (Início hero/VIP): one vitrine moment; toned down on mobile.
class AtelierVisuals {
  AtelierVisuals._();

  static bool isShowcase(BuildContext context) =>
      AppLayout.isClientDesktop(context);

  static BoxDecoration card(
    BuildContext context, {
    bool goldRim = false,
    bool elevated = false,
    bool peak = false,
  }) {
    final desktop = isShowcase(context);

    if (peak) {
      if (desktop) {
        return AppColors.showcaseCard(
          goldRim: goldRim,
          elevated: elevated,
        );
      }
      return BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: goldRim
              ? AppColors.primary.withValues(alpha: 0.32)
              : AppColors.border,
        ),
      );
    }

    if (!desktop) {
      return BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      );
    }

    return AppColors.showcaseCard(
      goldRim: goldRim,
      elevated: elevated,
    );
  }

  static BoxDecoration vipCard(BuildContext context) {
    final desktop = isShowcase(context);
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: desktop ? AppColors.vipShowcase : null,
      color: desktop ? null : AppColors.card,
      border: Border.all(
        color: AppColors.primary.withValues(alpha: desktop ? 0.55 : 0.28),
        width: desktop ? 1.3 : 1,
      ),
      boxShadow: desktop ? AppColors.spotlight(dy: 10, blur: 26) : null,
    );
  }

  static BoxDecoration planCard(BuildContext context, {required bool featured}) {
    if (!featured) {
      return BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      );
    }
    final desktop = isShowcase(context);
    return BoxDecoration(
      gradient: desktop ? AppColors.vipShowcase : null,
      color: desktop ? null : AppColors.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: desktop
            ? AppColors.primary.withValues(alpha: 0.65)
            : AppColors.primary.withValues(alpha: 0.35),
        width: desktop ? 1.5 : 1,
      ),
      boxShadow: desktop ? AppColors.spotlight(dy: 10, blur: 28) : null,
    );
  }

  static BoxDecoration selectablePlanCard(
    BuildContext context, {
    required bool selected,
  }) {
    if (!selected) {
      return BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      );
    }

    final desktop = isShowcase(context);
    if (desktop) {
      return AppColors.showcaseCard(goldRim: true, elevated: true);
    }

    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.primaryBright,
        width: 1.5,
      ),
    );
  }
}

/// Ambient gold glow — desktop only.
class AtelierShellBackdrop extends StatelessWidget {
  const AtelierShellBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AtelierVisuals.isShowcase(context)) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: -80,
          right: -40,
          child: IgnorePointer(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.14),
                    AppColors.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -70,
          child: IgnorePointer(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryBright.withValues(alpha: 0.07),
                    AppColors.primaryBright.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

enum AtelierButtonWeight { peak, standard, compact }

/// Gold CTA — spotlight only on desktop; compact stays flat on mobile.
class AtelierGoldButton extends StatelessWidget {
  const AtelierGoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 52,
    this.fontSize = 14,
    this.expand = false,
    this.weight = AtelierButtonWeight.standard,
    this.isLoading = false,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;
  final bool expand;
  final AtelierButtonWeight weight;
  final bool isLoading;
  final Widget? leading;

  /// Soft Forge: padding horizontal proporcional — evita texto colado/clipado.
  EdgeInsets get _padding {
    final h = height >= 48 ? 22.0 : 16.0;
    return EdgeInsets.symmetric(horizontal: h);
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AtelierVisuals.isShowcase(context);
    final enabled = onPressed != null && !isLoading;
    final useSpotlight =
        enabled && desktop && weight != AtelierButtonWeight.compact;
    final useGradient = desktop || weight == AtelierButtonWeight.peak;

    final content = isLoading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.background,
            ),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
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
                    style: TextStyle(
                      color: AppColors.background,
                      fontWeight: FontWeight.w800,
                      fontSize: fontSize,
                      letterSpacing: 0.2,
                      height: 1.2,
                    ),
                  ),
                )
              else
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    color: AppColors.background,
                    fontWeight: FontWeight.w800,
                    fontSize: fontSize,
                    letterSpacing: 0.2,
                    height: 1.2,
                  ),
                ),
            ],
          );

    final button = DecoratedBox(
      decoration: BoxDecoration(
        gradient: useGradient ? AppColors.primaryGradient : null,
        color: useGradient
            ? null
            : AppColors.primary.withValues(alpha: enabled ? 1 : 0.45),
        borderRadius: BorderRadius.circular(14),
        boxShadow: useSpotlight
            ? AppColors.spotlight(
                dy: weight == AtelierButtonWeight.peak ? 8 : 5,
                blur: weight == AtelierButtonWeight.peak ? 22 : 14,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: height,
              minWidth: leading != null ? 128 : 96,
            ),
            child: Padding(
              padding: _padding,
              child: SizedBox(
                height: height,
                child: Center(child: content),
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

/// Gold ring — desktop showcase only; mobile shows child plain.
class AtelierGoldRing extends StatelessWidget {
  const AtelierGoldRing({
    super.key,
    required this.child,
    this.ringWidth = 3,
    this.glow = false,
  });

  final Widget child;
  final double ringWidth;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    if (!AtelierVisuals.isShowcase(context)) return child;

    return Container(
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: glow ? AppColors.spotlight(dy: 4, blur: 16) : null,
      ),
      child: child,
    );
  }
}

/// Segmento ouro filled (mesmo padrão do Agendar) — Agenda, listas, etc.
class AtelierSegmentTabs extends StatelessWidget {
  const AtelierSegmentTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onChanged(i),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          index == i ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: index == i
                          ? [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: index == i
                            ? AppColors.background
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Linha de menu / ação no estilo cards do Agendar.
class AtelierMenuTile extends StatelessWidget {
  const AtelierMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final accent = danger ? AppColors.error : AppColors.primary;
    final labelColor = danger ? AppColors.error : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: danger
                  ? AppColors.error.withValues(alpha: 0.40)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.28)),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: labelColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: danger ? AppColors.error : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
