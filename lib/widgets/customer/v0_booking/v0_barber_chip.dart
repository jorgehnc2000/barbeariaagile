import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/barber.dart';
import '../v0_dashboard/v0_motion.dart';

/// Chip circular de barbeiro para a faixa “Com quem?”.
class V0BarberChip extends StatelessWidget {
  const V0BarberChip({
    super.key,
    required this.barber,
    required this.selected,
    required this.onSelect,
  });

  final Barber barber;
  final bool selected;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final enabled = onSelect != null && barber.isAvailable;
    final label = barber.name.trim().isEmpty
        ? 'Barbeiro'
        : barber.name.trim().split(RegExp(r'\s+')).first;

    return Opacity(
      opacity: barber.isAvailable ? 1 : 0.45,
      child: V0HoverShell(
        borderRadius: 14,
        onTap: enabled ? onSelect : null,
        builder: (context, hovered) {
          final active = selected || (hovered && enabled);
          return AnimatedContainer(
            duration: V0Motion.fast,
            curve: V0Motion.easeOut,
            width: 76,
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.70)
                    : active
                        ? AppColors.primary.withValues(alpha: 0.35)
                        : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: V0Motion.fast,
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceLight,
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                        image: barber.photoUrl.trim().isEmpty
                            ? null
                            : DecorationImage(
                                image: NetworkImage(barber.photoUrl),
                                fit: BoxFit.cover,
                              ),
                      ),
                      child: barber.photoUrl.trim().isEmpty
                          ? Center(
                              child: Text(
                                label[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : null,
                    ),
                    if (selected)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            border: Border.all(
                              color: AppColors.background,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: AppColors.background,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Chip “Qualquer disponível”.
class V0AnyBarberChip extends StatelessWidget {
  const V0AnyBarberChip({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return V0HoverShell(
      borderRadius: 14,
      onTap: onSelect,
      builder: (context, hovered) {
        final active = selected || hovered;
        return AnimatedContainer(
          duration: V0Motion.fast,
          curve: V0Motion.easeOut,
          width: 76,
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.70)
                  : active
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: V0Motion.fast,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surfaceLight.withValues(alpha: 0.45),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  Icons.groups_rounded,
                  size: 22,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Qualquer',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
