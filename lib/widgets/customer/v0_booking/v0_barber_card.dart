import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/barber.dart';
import '../v0_dashboard/v0_motion.dart';

/// Card de barbeiro estilo v0 — seleção com destaque ouro.
class V0BarberCard extends StatelessWidget {
  const V0BarberCard({
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

    return Opacity(
      opacity: barber.isAvailable ? 1 : 0.55,
      child: V0HoverShell(
        borderRadius: 16,
        onTap: enabled ? onSelect : null,
        builder: (context, hovered) {
          final active = selected || (hovered && enabled);
          return AnimatedContainer(
            duration: V0Motion.fast,
            curve: V0Motion.easeOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.10)
                  : hovered && enabled
                      ? AppColors.surfaceLight.withValues(alpha: 0.25)
                      : AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.70)
                    : active
                        ? AppColors.primary.withValues(alpha: 0.40)
                        : AppColors.border,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.50)
                          : AppColors.border,
                    ),
                    color: AppColors.surfaceLight,
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
                            barber.name.isEmpty
                                ? '?'
                                : barber.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barber.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        barber.isAvailable
                            ? (barber.specialty.trim().isEmpty
                                ? 'Barbeiro'
                                : barber.specialty)
                            : 'Indisponível',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: barber.isAvailable
                              ? AppColors.textMuted
                              : AppColors.error.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _SelectionDot(selected: selected),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: V0Motion.fast,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: selected
          ? const Icon(
              Icons.check_rounded,
              size: 14,
              color: AppColors.background,
            )
          : null,
    );
  }
}
