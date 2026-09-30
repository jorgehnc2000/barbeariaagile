import 'package:flutter/material.dart';

import '../../core/config/barbershop_runtime_config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/admin_service.dart';
import '../../models/admin_reports.dart';
import '../../widgets/responsive_page.dart';
import 'widgets/admin_reports_charts.dart';
import 'widgets/admin_ui.dart';
import 'widgets/admin_visuals.dart';

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  late Future<AdminReportsData> _future = AdminService.fetchReportsMetrics();

  void _reload() {
    setState(() => _future = AdminService.fetchReportsMetrics());
  }

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      maxWidth: AppLayout.adminMaxWidth,
      padding: AppLayout.pagePadding(context, admin: true),
      expand: true,
      child: RefreshIndicator(
        onRefresh: () async => _reload(),
        color: AppColors.primary,
        child: FutureBuilder<AdminReportsData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  const Center(child: Text('Erro ao carregar relatórios.')),
                  TextButton(
                    onPressed: _reload,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              );
            }

            final data = snapshot.data!;
            final vipEnabled =
                BarbershopRuntimeConfig.current?.vipEnabled ?? false;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const AdminPageHeader(
                  title: 'Relatórios',
                  subtitle: 'Desempenho do mês atual.',
                ),
                const SizedBox(height: 18),
                if (!data.hasFinancialData)
                  _EmptyFinanceBanner()
                else
                  _MetricsRow(data: data),
                const SizedBox(height: 20),
                AdminPanel(
                  kicker: 'EQUIPE',
                  title: 'Desempenho por barbeiro',
                  child: AdminBarberPerformanceChart(
                    rows: data.barberPerformance,
                  ),
                ),
                const SizedBox(height: 16),
                AdminPanel(
                  kicker: 'VOLUME',
                  title: 'Volume por dia da semana',
                  child: AdminWeekdayVolumeChart(points: data.weekdayAverages),
                ),
                const SizedBox(height: 16),
                AdminPanel(
                  kicker: 'HORÁRIOS',
                  title: 'Horários de pico',
                  child: AdminPeakHoursChart(points: data.peakHours),
                ),
                if (vipEnabled) ...[
                  const SizedBox(height: 16),
                  AdminPanel(
                    kicker: 'VIP',
                    title: 'Clube VIP',
                    child: Column(
                      children: [
                        _VipStatRow(
                          label: 'Assinantes ativos',
                          value: '${data.vipActive}',
                        ),
                        _VipStatRow(
                          label: 'Cancelados',
                          value: '${data.vipCancelled}',
                        ),
                        _VipStatRow(
                          label: 'Receita recorrente (MRR)',
                          value: formatAdminCurrency(data.vipMrr),
                          highlight: true,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyFinanceBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.insights_outlined, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nenhum dado financeiro neste período',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.data});

  final AdminReportsData data;

  @override
  Widget build(BuildContext context) {
    final vipEnabled = BarbershopRuntimeConfig.current?.vipEnabled ?? false;
    return AdminStatsRail(
      items: [
        AdminStatItem(
          label: 'Faturamento total',
          value: formatAdminCurrency(data.monthRevenue),
        ),
        if (vipEnabled)
          AdminStatItem(
            label: 'MRR Clube VIP',
            value: formatAdminCurrency(data.vipMrr),
          ),
        AdminStatItem(
          label: 'Atendimentos no mês',
          value: '${data.monthBookings}',
        ),
        AdminStatItem(
          label: 'Barbeiro destaque',
          value: data.topBarberName,
        ),
      ],
    );
  }
}

class _VipStatRow extends StatelessWidget {
  const _VipStatRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
