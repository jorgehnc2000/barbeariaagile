import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'v0_motion.dart';

/// Três cards de métricas no estilo v0 (Serviços / Barbeiros / Próximo horário).
class V0StatCards extends StatelessWidget {
  const V0StatCards({
    super.key,
    required this.serviceCount,
    required this.barberCount,
    this.nextTime,
    this.nextServiceName,
    this.compact = false,
  });

  final int serviceCount;
  final int barberCount;
  final String? nextTime;
  final String? nextServiceName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final hasNext = nextTime != null && nextTime!.trim().isNotEmpty;

    final cards = [
      _StatCard(
        icon: Icons.content_cut_rounded,
        label: 'Serviços',
        value: '$serviceCount',
        hint: 'disponíveis',
        compact: compact,
      ),
      _StatCard(
        icon: Icons.groups_rounded,
        label: 'Barbeiros',
        value: '$barberCount',
        hint: 'na equipe',
        compact: compact,
      ),
      _NextStatCard(
        time: hasNext ? nextTime! : '—',
        serviceName: hasNext ? nextServiceName : null,
        highlighted: hasNext,
        compact: compact,
      ),
    ];

    if (wide) {
      return Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 14),
            Expanded(child: cards[i]),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 12),
        cards[2],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final reduce = V0Motion.reduced(context);

    return V0HoverShell(
      borderRadius: 16,
      builder: (context, hovered) {
        return AnimatedContainer(
          duration: reduce ? Duration.zero : V0Motion.fast,
          curve: V0Motion.easeOut,
          padding: EdgeInsets.all(compact ? 14 : 20),
          decoration: BoxDecoration(
            color: hovered
                ? AppColors.surfaceLight.withValues(alpha: 0.22)
                : AppColors.card,
            borderRadius: BorderRadius.circular(compact ? 14 : 16),
            border: Border.all(
              color: hovered
                  ? AppColors.border.withValues(alpha: 0.55)
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: reduce ? Duration.zero : V0Motion.fast,
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: hovered
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: hovered
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: compact ? 24 : 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hint,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NextStatCard extends StatelessWidget {
  const _NextStatCard({
    required this.time,
    required this.highlighted,
    this.serviceName,
    this.compact = false,
  });

  final String time;
  final String? serviceName;
  final bool highlighted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final reduce = V0Motion.reduced(context);

    return V0HoverShell(
      borderRadius: 16,
      builder: (context, hovered) {
        return AnimatedContainer(
          duration: reduce ? Duration.zero : V0Motion.fast,
          curve: V0Motion.easeOut,
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 14 : 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 14 : 16),
            border: Border.all(
              color: hovered || highlighted
                  ? AppColors.primary.withValues(alpha: hovered ? 0.45 : 0.35)
                  : AppColors.border,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(
                  alpha: hovered ? 0.18 : (highlighted ? 0.14 : 0.06),
                ),
                AppColors.primary.withValues(
                  alpha: hovered ? 0.05 : (highlighted ? 0.03 : 0.01),
                ),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  _GoldIconBox(),
                  SizedBox(width: 8),
                  Text(
                    'PRÓXIMO HORÁRIO',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: compact ? 24 : 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (serviceName != null &&
                      serviceName!.trim().isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        serviceName!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GoldIconBox extends StatelessWidget {
  const _GoldIconBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.schedule_rounded,
        size: 16,
        color: AppColors.primary,
      ),
    );
  }
}
