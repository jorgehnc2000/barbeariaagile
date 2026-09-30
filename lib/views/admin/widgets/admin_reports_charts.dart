import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/admin_reports.dart';
import 'admin_chart_kit.dart';
import 'admin_ui.dart';

class AdminWeekdayVolumeChart extends StatelessWidget {
  const AdminWeekdayVolumeChart({super.key, required this.points});

  final List<WeekdayVolumePoint> points;

  int get _todayIndex => DateTime.now().weekday % 7;

  int get _monthTotal => points.fold<int>(0, (sum, point) => sum + point.total);

  double get _avgPerDay {
    final withData = points.where((p) => p.average > 0).toList();
    if (withData.isEmpty) return 0;
    return withData.fold<double>(0, (sum, p) => sum + p.average) /
        withData.length;
  }

  @override
  Widget build(BuildContext context) {
    final hasData = points.any((point) => point.average > 0);

    return AdminVerticalBarChart(
      headline: hasData ? '$_monthTotal agendamentos' : '0 agendamentos',
      subtitle: hasData
          ? 'média de ${_avgPerDay.toStringAsFixed(1)} por dia no mês'
          : 'sem volume neste período',
      todayIndex: _todayIndex,
      items: [
        for (final point in points)
          AdminBarChartItem(
            label: point.label,
            value: point.average,
            displayValue: point.average > 0
                ? point.average.toStringAsFixed(1)
                : null,
          ),
      ],
    );
  }
}

class AdminPeakHoursChart extends StatelessWidget {
  const AdminPeakHoursChart({super.key, required this.points});

  final List<PeakHourPoint> points;

  @override
  Widget build(BuildContext context) {
    final top = points.take(5).toList();
    final total = top.fold<int>(0, (sum, point) => sum + point.count);
    final hasData = total > 0;
    final busiest = top.isEmpty ? null : top.first;

    return AdminHorizontalBarChart(
      headline: hasData && busiest != null
          ? '${busiest.count} no horário ${busiest.hourLabel}'
          : 'Sem picos registrados',
      subtitle: hasData
          ? '$total agendamentos nos horários mais movimentados'
          : 'aguardando dados do mês',
      valueSuffix: ' ag.',
      items: [
        for (final point in top)
          AdminBarChartItem(
            label: point.hourLabel,
            value: point.count.toDouble(),
            displayValue: '${point.count}',
          ),
      ],
    );
  }
}

class AdminBarberPerformanceChart extends StatelessWidget {
  const AdminBarberPerformanceChart({super.key, required this.rows});

  final List<BarberPerformanceRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Text(
        'Nenhum atendimento concluído neste mês.',
        style: TextStyle(color: AppColors.textMuted),
      );
    }

    final topRevenue = rows.first.revenue;

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BarberPerformanceTile(
              rank: i + 1,
              row: rows[i],
              share: topRevenue <= 0 ? 0 : rows[i].revenue / topRevenue,
              isLeader: i == 0,
            ),
          ),
      ],
    );
  }
}

class _BarberPerformanceTile extends StatelessWidget {
  const _BarberPerformanceTile({
    required this.rank,
    required this.row,
    required this.share,
    required this.isLeader,
  });

  final int rank;
  final BarberPerformanceRow row;
  final double share;
  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLeader
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: isLeader ? AppColors.primary : AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage: row.photoUrl.isNotEmpty
                    ? NetworkImage(row.photoUrl)
                    : null,
                child: row.photoUrl.isEmpty
                    ? Text(
                        row.barberName.isNotEmpty ? row.barberName[0] : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.barberName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${row.attendances} atendimentos',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatAdminCurrency(row.revenue),
                    style: TextStyle(
                      color: isLeader
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ticket ${formatAdminCurrency(row.averageTicket)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                isLeader
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
