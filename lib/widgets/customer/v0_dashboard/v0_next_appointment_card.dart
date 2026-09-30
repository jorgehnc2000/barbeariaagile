import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/booking.dart';
import '../../screen_background.dart';
import 'v0_motion.dart';

/// Card do próximo agendamento no estilo v0.
class V0NextAppointmentCard extends StatelessWidget {
  const V0NextAppointmentCard({
    super.key,
    required this.booking,
    required this.onOpenAgenda,
    required this.onAgendar,
  });

  final Booking? booking;
  final VoidCallback onOpenAgenda;
  final VoidCallback onAgendar;

  @override
  Widget build(BuildContext context) {
    if (booking == null) {
      return _EmptyCard(onAgendar: onAgendar);
    }
    return _FilledCard(booking: booking!, onOpenAgenda: onOpenAgenda);
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onAgendar});

  final VoidCallback onAgendar;

  @override
  Widget build(BuildContext context) {
    final reduce = V0Motion.reduced(context);

    return V0HoverShell(
      borderRadius: 24,
      builder: (context, hovered) {
        return AnimatedContainer(
          duration: reduce ? Duration.zero : V0Motion.fast,
          curve: V0Motion.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hovered
                  ? AppColors.border.withValues(alpha: 0.55)
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel(),
              const SizedBox(height: 16),
              const Text(
                'Nenhum horário marcado',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Reserve seu próximo visual quando quiser.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              _DetailLink(label: 'Agendar agora', onTap: onAgendar),
            ],
          ),
        );
      },
    );
  }
}

class _FilledCard extends StatelessWidget {
  const _FilledCard({required this.booking, required this.onOpenAgenda});

  final Booking booking;
  final VoidCallback onOpenAgenda;

  @override
  Widget build(BuildContext context) {
    final priceLabel = booking.coveredByPlan
        ? 'R\$ 0,00'
        : formatCurrency(booking.price);
    final priceHint = booking.coveredByPlan
        ? 'coberto pelo VIP'
        : booking.status.label.toLowerCase();
    final reduce = V0Motion.reduced(context);

    return V0HoverShell(
      borderRadius: 24,
      builder: (context, hovered) {
        return AnimatedContainer(
          duration: reduce ? Duration.zero : V0Motion.fast,
          curve: V0Motion.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hovered
                  ? AppColors.border.withValues(alpha: 0.55)
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel(),
              const SizedBox(height: 18),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: booking.barberPhotoUrl.isEmpty
                          ? ColoredBox(
                              color: AppColors.surfaceLight,
                              child: Center(
                                child: Text(
                                  booking.barberName.isEmpty
                                      ? '?'
                                      : booking.barberName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            )
                          : Image.network(
                              booking.barberPhotoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => ColoredBox(
                                color: AppColors.surfaceLight,
                                child: Center(
                                  child: Text(
                                    booking.barberName.isEmpty
                                        ? '?'
                                        : booking.barberName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'com ${booking.barberName} · ${formatDate(booking.dateTime)} · ${formatTime(booking.dateTime)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        priceLabel,
                        style: TextStyle(
                          color: booking.coveredByPlan
                              ? AppColors.success
                              : AppColors.primary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        priceHint,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _DetailLink(
                label: 'Ver detalhes do agendamento',
                onTap: onOpenAgenda,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(
          Icons.calendar_month_rounded,
          size: 16,
          color: AppColors.primary,
        ),
        SizedBox(width: 8),
        Text(
          'PRÓXIMO AGENDAMENTO',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _DetailLink extends StatelessWidget {
  const _DetailLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = V0Motion.reduced(context);

    return V0HoverShell(
      onTap: onTap,
      borderRadius: 12,
      builder: (context, hovered) {
        return AnimatedContainer(
          duration: reduce ? Duration.zero : V0Motion.fast,
          curve: V0Motion.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: hovered
                ? AppColors.surfaceLight.withValues(alpha: 0.4)
                : AppColors.surfaceLight.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hovered
                  ? AppColors.border.withValues(alpha: 0.55)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              AnimatedSlide(
                duration: reduce ? Duration.zero : V0Motion.fast,
                curve: V0Motion.easeOut,
                offset: hovered ? const Offset(0.12, 0) : Offset.zero,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: hovered
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
