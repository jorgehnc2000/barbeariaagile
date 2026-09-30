import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/config/barbershop_runtime_config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/admin_service.dart';
import '../../models/admin_dashboard.dart';
import '../../models/admin_agenda_booking.dart';
import '../../widgets/responsive_page.dart';
import 'widgets/admin_revenue_chart.dart';
import 'widgets/admin_ui.dart';

/// Dashboard com visual AgendaElite (piloto antes de espalhar no admin).
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<AdminDashboardData> _metricsFuture =
      AdminService.fetchDashboardMetrics();

  void _reload() {
    setState(() {
      _metricsFuture = AdminService.fetchDashboardMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AdminBreakpoints.isDesktop(context);

    return ResponsivePage(
      maxWidth: AppLayout.adminMaxWidth,
      padding: AppLayout.pagePadding(context, admin: true),
      expand: true,
      child: RefreshIndicator(
        onRefresh: () async => _reload(),
        color: AppColors.primary,
        child: FutureBuilder<AdminDashboardData>(
          future: _metricsFuture,
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
                  const Center(
                    child: Text(
                      'Não foi possível carregar o dashboard. Tente novamente.',
                    ),
                  ),
                  TextButton(
                    onPressed: _reload,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              );
            }

            final data = snapshot.data!;
            final todayCount = data.todayBookings.length;
            final next = data.todayBookings.isNotEmpty
                ? data.todayBookings.first
                : null;
            final vipEnabled =
                BarbershopRuntimeConfig.current?.vipEnabled ?? false;
            final shop = BrandScope.shopName(context);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _EliteDashboardHeader(
                  shopName: shop,
                  todayCount: todayCount,
                  next: next,
                  desktop: desktop,
                ),
                const SizedBox(height: 18),
                _EliteTodayTimeline(bookings: data.todayBookings),
                const SizedBox(height: 20),
                _EliteStatsGrid(
                  items: [
                    (
                      'Faturamento do mês',
                      formatAdminCurrency(data.monthRevenue),
                      true,
                    ),
                    ('Agendamentos', '${data.totalBookings}', false),
                    if (vipEnabled)
                      ('Assinantes VIP', '${data.vipSubscribers}', false),
                    (
                      'Ticket médio',
                      formatAdminCurrency(data.averageTicket),
                      false,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AdminPanel(
                  kicker: 'DESEMPENHO',
                  title: 'Faturamento da semana',
                  child: AdminWeeklyRevenueChart(points: data.weeklyRevenue),
                ),
                const SizedBox(height: 16),
                AdminSplitRow(
                  gap: 16,
                  left: AdminPanel(
                    kicker: 'EQUIPE',
                    title: 'Quem mais atendeu',
                    child: data.topBarbers.isEmpty
                        ? Text(
                            'Sem atendimentos neste período.',
                            style: TextStyle(
                              color: AppColors.textMuted.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (
                                var i = 0;
                                i < data.topBarbers.length && i < 5;
                                i++
                              )
                                _EliteTopBarberTile(
                                  rank: i + 1,
                                  entry: data.topBarbers[i],
                                ),
                            ],
                          ),
                  ),
                  right: AdminPanel(
                    kicker: 'CATÁLOGO',
                    title: 'Serviços em alta',
                    child: data.topServices.isEmpty
                        ? Text(
                            'Nenhum serviço confirmado ainda.',
                            style: TextStyle(
                              color: AppColors.textMuted.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (final service in data.topServices.take(5))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          service.name,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${service.count}x',
                                        style: TextStyle(
                                          color: AppColors.textMuted
                                              .withValues(alpha: 0.75),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        formatAdminCurrency(service.revenue),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EliteDashboardHeader extends StatelessWidget {
  const _EliteDashboardHeader({
    required this.shopName,
    required this.todayCount,
    required this.next,
    required this.desktop,
  });

  final String shopName;
  final int todayCount;
  final AdminAgendaBooking? next;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${operateGreeting()}, $shopName'.toUpperCase(),
                style: AdminVisuals.sectionLabel(context, opacity: 0.75),
              ),
              const SizedBox(height: 8),
              Text(
                'Hoje na casa',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AdminVisuals.isElite(context)
                      ? (desktop ? 32 : 26)
                      : (desktop ? 24 : 20),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                todayCount == 0
                    ? 'Nenhum cliente na agenda ainda.'
                    : '$todayCount ${todayCount == 1 ? 'cliente' : 'clientes'} na agenda',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.85),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (next != null) ...[
          const SizedBox(width: 12),
          _EliteNextSlotChip(
            time:
                '${next!.dateTime.hour.toString().padLeft(2, '0')}:${next!.dateTime.minute.toString().padLeft(2, '0')}',
            label: next!.clientName,
          ),
        ],
      ],
    );
  }
}

class _EliteNextSlotChip extends StatelessWidget {
  const _EliteNextSlotChip({required this.time, required this.label});

  final String time;
  final String label;

  @override
  Widget build(BuildContext context) {
    final goldBg = AdminVisuals.goldContainer(context);
    final onGold = AdminVisuals.onGoldContainer(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: goldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        boxShadow: AdminVisuals.goldGlow(context, alpha: 0.14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'PRÓXIMO',
            style: TextStyle(
              color: onGold.withValues(alpha: 0.75),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: TextStyle(
              color: onGold,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: onGold.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EliteStatsGrid extends StatelessWidget {
  const _EliteStatsGrid({required this.items});

  final List<(String, String, bool)> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = width >= 900
            ? math.min(4, items.length)
            : width >= 560
            ? 2
            : 1;
        final gap = 12.0;
        final cardWidth = (width - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  decoration: AdminVisuals.glass(context, radius: 12).copyWith(
                    boxShadow: item.$3
                        ? AdminVisuals.goldGlow(context, alpha: 0.1)
                        : null,
                    border: Border.all(
                      color: item.$3
                          ? AppColors.primary.withValues(alpha: 0.35)
                          : AppColors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1.toUpperCase(),
                        style: AdminVisuals.sectionLabel(context, opacity: 0.7),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.$2,
                        style: TextStyle(
                          color: item.$3
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EliteTodayTimeline extends StatelessWidget {
  const _EliteTodayTimeline({required this.bookings});

  final List<AdminAgendaBooking> bookings;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: AdminVisuals.glass(context, radius: 14),
        child: Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 32,
              color: AppColors.textMuted.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 12),
            const Text(
              'Agenda livre por enquanto',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Quando chegarem agendamentos, eles aparecem aqui em ordem.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: AdminVisuals.glass(context, radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FILA DE HOJE', style: AdminVisuals.sectionLabel(context)),
          const SizedBox(height: 14),
          for (var i = 0; i < bookings.length && i < 8; i++) ...[
            _EliteTodayBookingTile(
              time:
                  '${bookings[i].dateTime.hour.toString().padLeft(2, '0')}:${bookings[i].dateTime.minute.toString().padLeft(2, '0')}',
              client: bookings[i].clientName,
              service: bookings[i].serviceName,
              barber: bookings[i].barberName,
              isLast: i == math.min(bookings.length, 8) - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _EliteTodayBookingTile extends StatelessWidget {
  const _EliteTodayBookingTile({
    required this.time,
    required this.client,
    required this.service,
    required this.barber,
    required this.isLast,
  });

  final String time;
  final String client;
  final String service;
  final String barber;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: AdminVisuals.goldGlow(context, alpha: 0.25),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$service · $barber',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EliteTopBarberTile extends StatelessWidget {
  const _EliteTopBarberTile({required this.rank, required this.entry});

  final int rank;
  final TopBarberEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank == 1
                    ? AppColors.primary
                    : AppColors.textMuted.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: AdminVisuals.deepFill(context),
            backgroundImage: entry.photoUrl.isNotEmpty
                ? NetworkImage(entry.photoUrl)
                : null,
            child: entry.photoUrl.isEmpty
                ? Text(
                    entry.name.isNotEmpty ? entry.name[0] : '?',
                    style: const TextStyle(
                      color: AppColors.primaryBright,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${entry.attendances} atendimentos',
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatAdminCurrency(entry.revenue),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
