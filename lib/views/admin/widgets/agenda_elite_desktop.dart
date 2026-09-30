import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/admin_agenda_booking.dart';
import '../../../models/booking_status.dart';
import 'admin_visuals.dart';

/// Visual Estate Barber — Agenda Online.
/// Desktop: Elite glass. Mobile: Midnight Atelier / Operate flat.
abstract final class AgendaEliteDesktop {
  AgendaEliteDesktop._();

  static BoxDecoration glass(
    BuildContext context, {
    double radius = 12,
    Color? borderColor,
  }) =>
      AdminVisuals.glass(context, radius: radius, borderColor: borderColor);

  static List<BoxShadow>? goldGlow(BuildContext context, {double alpha = 0.2}) =>
      AdminVisuals.goldGlow(context, alpha: alpha);

  static Color deepFill(BuildContext context) => AdminVisuals.deepFill(context);

  static Color goldContainer(BuildContext context) =>
      AdminVisuals.goldContainer(context);

  static Color onGoldContainer(BuildContext context) =>
      AdminVisuals.onGoldContainer(context);
}

class AgendaEliteWeekStrip extends StatelessWidget {
  const AgendaEliteWeekStrip({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final start = selectedDay.subtract(Duration(days: selectedDay.weekday % 7));
    final days = List.generate(7, (index) => start.add(Duration(days: index)));
    const labels = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];

    return SizedBox(
      height: 58,
      child: Row(
        children: [
          for (var index = 0; index < days.length; index++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _EliteDayCard(
                  weekday: labels[index],
                  day: days[index].day,
                  selected: _sameDay(days[index], selectedDay),
                  onTap: () => onDaySelected(days[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EliteDayCard extends StatelessWidget {
  const _EliteDayCard({
    required this.weekday,
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final String weekday;
  final int day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected
              ? AgendaEliteDesktop.goldContainer(context)
              : AgendaEliteDesktop.deepFill(context).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow:
              selected ? AgendaEliteDesktop.goldGlow(context, alpha: 0.12) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weekday,
              style: TextStyle(
                color: selected
                    ? AgendaEliteDesktop.onGoldContainer(context)
                    : AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$day',
              style: TextStyle(
                color: selected
                    ? AgendaEliteDesktop.onGoldContainer(context)
                    : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AgendaEliteBarberFilterRow extends StatelessWidget {
  const AgendaEliteBarberFilterRow({
    super.key,
    required this.chips,
    required this.selectedKey,
    required this.onSelected,
  });

  final List<(String, String)> chips;
  final String selectedKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BARBEIROS',
          style: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.85),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (key, label) in chips)
              _EliteBarberChip(
                label: label.toUpperCase(),
                selected: key == selectedKey,
                onTap: () => onSelected(key),
              ),
          ],
        ),
      ],
    );
  }
}

class _EliteBarberChip extends StatelessWidget {
  const _EliteBarberChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AgendaEliteDesktop.deepFill(context).withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.background : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class AgendaElitePeriodListView extends StatelessWidget {
  const AgendaElitePeriodListView({
    super.key,
    required this.bookings,
    required this.showBarberName,
    required this.onBookingTap,
  });

  final List<AdminAgendaBooking> bookings;
  final bool showBarberName;
  final ValueChanged<AdminAgendaBooking> onBookingTap;

  @override
  Widget build(BuildContext context) {
    final sorted = [...bookings]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final morning = sorted.where((b) => b.dateTime.hour < 12).toList();
    final afternoon = sorted
        .where((b) => b.dateTime.hour >= 12 && b.dateTime.hour < 18)
        .toList();
    final evening = sorted.where((b) => b.dateTime.hour >= 18).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (morning.isNotEmpty) ..._period('MANHÃ', morning),
        if (afternoon.isNotEmpty) ..._period('TARDE', afternoon),
        if (evening.isNotEmpty) ..._period('NOITE', evening),
      ],
    );
  }

  List<Widget> _period(String label, List<AdminAgendaBooking> items) {
    return [
      _ElitePeriodLabel(label),
      const SizedBox(height: 8),
      for (final booking in items) ...[
        AgendaEliteBookingCard(
          booking: booking,
          showBarber: showBarberName,
          onTap: () => onBookingTap(booking),
        ),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 4),
    ];
  }
}

class _ElitePeriodLabel extends StatelessWidget {
  const _ElitePeriodLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.textMuted.withValues(alpha: 0.75),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
  }
}

class AgendaEliteBookingCard extends StatelessWidget {
  const AgendaEliteBookingCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.showBarber = true,
    this.compact = false,
  });

  final AdminAgendaBooking booking;
  final VoidCallback onTap;
  final bool showBarber;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _EliteCompactTile(booking: booking, onTap: onTap);
    }

    final clientLine = booking.clientEmail.isNotEmpty
        ? _truncate(booking.clientEmail, 28)
        : booking.clientName;
    final subline = booking.clientEmail.isNotEmpty
        ? (booking.clientPhone.isNotEmpty
            ? 'Tel. ${booking.clientPhone}'
            : 'Agendado via App')
        : booking.clientName;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: AgendaEliteDesktop.glass(context, radius: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showBarber)
                          Text(
                            booking.barberName.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                            ),
                          ),
                        if (showBarber) const SizedBox(height: 4),
                        Text(
                          booking.serviceName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1.15,
                          ),
                        ),
                        if (booking.price > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatCurrency(booking.price),
                            style: TextStyle(
                              color: AppColors.textMuted.withValues(
                                alpha: 0.65,
                              ),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(booking.dateTime),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${booking.durationMinutes > 0 ? booking.durationMinutes : 45} MIN',
                        style: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.65),
                          fontSize: 10,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.surface,
                      backgroundImage: booking.clientPhotoUrl.isEmpty
                          ? null
                          : NetworkImage(booking.clientPhotoUrl),
                      child: booking.clientPhotoUrl.isEmpty
                          ? const Icon(
                              Icons.person_rounded,
                              size: 16,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clientLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            subline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMuted.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _EliteStatusBadge(status: booking.status),
                  const Spacer(),
                  Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.textMuted.withValues(alpha: 0.45),
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EliteCompactTile extends StatelessWidget {
  const _EliteCompactTile({required this.booking, required this.onTap});

  final AdminAgendaBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final minutes = booking.durationMinutes > 0 ? booking.durationMinutes : 45;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AgendaEliteDesktop.deepFill(context).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: booking.status == BookingStatus.pending
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatTime(booking.dateTime),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                booking.clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                booking.serviceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _EliteStatusBadge(status: booking.status, compact: true),
                  const Spacer(),
                  Text(
                    '$minutes min',
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EliteStatusBadge extends StatelessWidget {
  const _EliteStatusBadge({required this.status, this.compact = false});

  final BookingStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      BookingStatus.confirmed => (
          const Color(0x4D14532D),
          const Color(0xFF4ADE80),
        ),
      BookingStatus.pending => (
          AppColors.primary.withValues(alpha: 0.12),
          AppColors.primary,
        ),
      BookingStatus.cancelled => (
          const Color(0x4D7F1D1D),
          const Color(0xFFF87171),
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label.toUpperCase(),
            style: TextStyle(
              color: fg,
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class AgendaEliteColumnData {
  AgendaEliteColumnData({
    required this.key,
    required this.name,
    required this.photoUrl,
    required this.bookings,
  });

  final String key;
  final String name;
  final String photoUrl;
  final List<AdminAgendaBooking> bookings;
}

class AgendaEliteBarberColumnsBoard extends StatelessWidget {
  const AgendaEliteBarberColumnsBoard({
    super.key,
    required this.columns,
    required this.onBookingTap,
  });

  final List<AgendaEliteColumnData> columns;
  final ValueChanged<AdminAgendaBooking> onBookingTap;

  static const double columnWidth = 272;

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum barbeiro para exibir.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (columns.length > 3)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Arraste para o lado para ver mais barbeiros →',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.85),
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
          ),
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: columns.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final column = columns[index];
              return SizedBox(
                width: columnWidth,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: AgendaEliteDesktop.glass(context, radius: 14),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.surface,
                                  backgroundImage: column.photoUrl.isEmpty
                                      ? null
                                      : NetworkImage(column.photoUrl),
                                  child: column.photoUrl.isEmpty
                                      ? Text(
                                          column.name.isEmpty
                                              ? '?'
                                              : column.name[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: AppColors.primaryBright,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    column.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.background.withValues(
                                      alpha: 0.6,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    '${column.bookings.length}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                          Expanded(
                            child: column.bookings.isEmpty
                                ? Center(
                                    child: Text(
                                      'Livre',
                                      style: TextStyle(
                                        color: AppColors.textMuted.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(10),
                                    itemCount: column.bookings.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, i) {
                                      final booking = column.bookings[i];
                                      return AgendaEliteBookingCard(
                                        booking: booking,
                                        showBarber: false,
                                        compact: true,
                                        onTap: () => onBookingTap(booking),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

String _formatTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _formatCurrency(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

String _truncate(String value, int max) {
  if (value.length <= max) return value;
  return '${value.substring(0, max - 1)}…';
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
