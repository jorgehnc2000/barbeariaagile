import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/barber.dart';
import '../../../models/service.dart';

/// Resumo do agendamento estilo v0.
class V0SummaryPanel extends StatelessWidget {
  const V0SummaryPanel({
    super.key,
    required this.userName,
    required this.service,
    required this.barber,
    required this.dateLabel,
    required this.time,
    this.anyBarber = false,
    this.compact = false,
  });

  final String userName;
  final Service? service;
  final Barber? barber;
  final String dateLabel;
  final String? time;
  final bool anyBarber;
  final bool compact;

  String get _firstName {
    final parts = userName.trim().split(RegExp(r'\s+'));
    final first = parts.isEmpty ? 'Cliente' : parts.first;
    return first.isEmpty ? 'Cliente' : first;
  }

  @override
  Widget build(BuildContext context) {
    final barberName = anyBarber
        ? 'Qualquer disponível'
        : (barber?.name.trim().isNotEmpty == true
            ? barber!.name
            : 'Selecione um barbeiro');
    final role = anyBarber
        ? 'Primeiro com horário livre'
        : (barber == null
            ? '—'
            : (barber!.specialty.trim().isEmpty
                ? 'Barbeiro'
                : barber!.specialty));

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESUMO DO AGENDAMENTO',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            '$_firstName, pronto para o seu corte?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: compact ? 16 : 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 8),
            const Text(
              'Confira os detalhes e confirme quando estiver tudo certo.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
          SizedBox(height: compact ? 10 : 16),
          Container(
            padding: EdgeInsets.all(compact ? 10 : 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 40 : 48,
                  height: compact ? 40 : 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                    color: AppColors.surfaceLight,
                    image: !anyBarber &&
                            barber?.photoUrl.trim().isNotEmpty == true
                        ? DecorationImage(
                            image: NetworkImage(barber!.photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: anyBarber
                      ? const Icon(
                          Icons.groups_rounded,
                          color: AppColors.primary,
                          size: 22,
                        )
                      : (barber?.photoUrl.trim().isNotEmpty == true
                          ? null
                          : Center(
                              child: Text(
                                barberName.isEmpty
                                    ? '?'
                                    : barberName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barberName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _Row(
            icon: Icons.content_cut_rounded,
            label: 'Serviço',
            value: service?.name ?? 'Selecione um serviço',
            compact: compact,
          ),
          _Row(
            icon: Icons.calendar_today_rounded,
            label: 'Data',
            value: dateLabel,
            compact: compact,
          ),
          _Row(
            icon: Icons.schedule_rounded,
            label: 'Horário',
            value: time ?? 'A escolher',
            showDivider: false,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10),
          child: Row(
            children: [
              Container(
                width: compact ? 30 : 36,
                height: compact ? 30 : 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, size: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}
