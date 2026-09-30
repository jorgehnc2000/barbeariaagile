import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/service.dart';
import '../v0_dashboard/v0_motion.dart';

/// Card de serviço estilo v0 — seleção com destaque ouro.
class V0ServiceCard extends StatelessWidget {
  const V0ServiceCard({
    super.key,
    required this.service,
    required this.selected,
    required this.onSelect,
    this.compact = false,
  });

  final Service service;
  final bool selected;
  final VoidCallback onSelect;
  final bool compact;

  String get _priceLabel =>
      'R\$ ${service.price.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final pad = compact ? 12.0 : 16.0;
    final iconSize = compact ? 40.0 : 48.0;
    final radius = compact ? 14.0 : 16.0;

    return V0HoverShell(
      borderRadius: radius,
      onTap: onSelect,
      builder: (context, hovered) {
        final active = selected || hovered;
        return AnimatedContainer(
          duration: V0Motion.fast,
          curve: V0Motion.easeOut,
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.10)
                : hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.25)
                    : AppColors.card,
            borderRadius: BorderRadius.circular(radius),
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
              AnimatedContainer(
                duration: V0Motion.fast,
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surfaceLight.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(compact ? 10 : 12),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.40)
                        : AppColors.border,
                  ),
                ),
                child: Icon(
                  Icons.content_cut_rounded,
                  size: compact ? 18 : 20,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: compact
                    ? Row(
                        children: [
                          Expanded(
                            child: Text(
                              service.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            _priceLabel,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '· ${service.durationMinutes} min',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _priceLabel,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${service.durationMinutes} min',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        if (service.description.trim().isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              service.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
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
