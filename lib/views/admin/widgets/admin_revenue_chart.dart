import 'package:flutter/material.dart';

import '../../../models/admin_dashboard.dart';
import 'admin_chart_kit.dart';
import 'admin_ui.dart';

/// Gráfico de faturamento semanal (dashboard).
class AdminWeeklyRevenueChart extends StatelessWidget {
  const AdminWeeklyRevenueChart({super.key, required this.points});

  final List<WeeklyRevenuePoint> points;

  int get _todayIndex => DateTime.now().weekday % 7;

  double get _weekTotal =>
      points.fold<double>(0, (sum, point) => sum + point.amount);

  @override
  Widget build(BuildContext context) {
    final hasData = points.any((point) => point.amount > 0);

    return AdminVerticalBarChart(
      headline: hasData ? formatAdminCurrency(_weekTotal) : 'R\$ 0,00',
      subtitle: hasData
          ? 'total nos últimos 7 dias'
          : 'nenhuma receita confirmada ainda',
      todayIndex: _todayIndex,
      items: [
        for (final point in points)
          AdminBarChartItem(
            label: point.label,
            value: point.amount,
            displayValue: point.amount > 0
                ? _compactCurrency(point.amount)
                : null,
          ),
      ],
    );
  }

  String _compactCurrency(double value) {
    if (value >= 1000) {
      final k = value / 1000;
      return 'R\$ ${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
    }
    return formatAdminCurrency(value).replaceAll('R\$ ', '');
  }
}
