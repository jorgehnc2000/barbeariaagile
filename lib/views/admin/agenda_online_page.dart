import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/admin_service.dart';
import '../../models/admin_agenda_booking.dart';
import '../../models/barber.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/screen_header_bar.dart';
import 'widgets/admin_ui.dart';
import 'widgets/agenda_elite_desktop.dart';

/// Sentinel: todos os barbeiros.
const String _kAllBarbers = '__all__';

class AgendaOnlinePage extends StatefulWidget {
  const AgendaOnlinePage({super.key});

  @override
  State<AgendaOnlinePage> createState() => _AgendaOnlinePageState();
}

class _AgendaOnlinePageState extends State<AgendaOnlinePage> {
  DateTime _selectedDay = DateTime.now();

  /// true = Colunas (desktop), false = Lista.
  bool _columnsView = true;
  String _selectedBarberKey = _kAllBarbers;

  late Future<List<AdminAgendaBooking>> _agendaFuture =
      AdminService.fetchAdminAgenda(day: _selectedDay);
  late Future<List<Barber>> _barbersFuture = AdminService.fetchAdminBarbers();

  void _reload() {
    setState(() {
      _agendaFuture = AdminService.fetchAdminAgenda(day: _selectedDay);
      _barbersFuture = AdminService.fetchAdminBarbers();
    });
  }

  Future<void> _selectDay() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.backgroundElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedDay = selected;
      _agendaFuture = AdminService.fetchAdminAgenda(day: selected);
    });
  }

  Future<void> _openNewBooking() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _NewCounterBookingDialog(initialDay: _selectedDay),
    );
    if (result == true && mounted) _reload();
  }

  Future<void> _showBookingDetails(AdminAgendaBooking booking) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.95,
        child: _BookingDetailsSheet(booking: booking),
      ),
    );
    if (changed == true && mounted) _reload();
  }

  List<AdminAgendaBooking> _filterBookings(List<AdminAgendaBooking> all) {
    if (_selectedBarberKey == _kAllBarbers) return all;
    return all
        .where((b) => _barberKey(b) == _selectedBarberKey)
        .toList(growable: false);
  }

  static String _barberKey(AdminAgendaBooking b) =>
      b.barberId.isNotEmpty ? b.barberId : 'name:${b.barberName}';

  List<_BarberColumnData> _buildColumns({
    required List<Barber> roster,
    required List<AdminAgendaBooking> bookings,
  }) {
    final map = <String, _BarberColumnData>{};

    for (final barber in roster) {
      map[barber.id] = _BarberColumnData(
        key: barber.id,
        name: barber.name,
        photoUrl: barber.photoUrl,
        bookings: [],
      );
    }

    for (final booking in bookings) {
      final key = _barberKey(booking);
      final existing = map[key];
      if (existing != null) {
        existing.bookings.add(booking);
      } else {
        map[key] = _BarberColumnData(
          key: key,
          name: booking.barberName,
          photoUrl: booking.barberPhotoUrl,
          bookings: [booking],
        );
      }
    }

    if (_selectedBarberKey != _kAllBarbers) {
      final only = map[_selectedBarberKey];
      if (only == null) return const [];
      only.bookings.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return [only];
    }

    final columns = map.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    for (final column in columns) {
      column.bookings.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    }
    return columns;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdminBreakpoints.isDesktop(context);
    final useColumns = isDesktop && _columnsView;

    return ResponsivePage(
      maxWidth: AppLayout.adminMaxWidth,
      padding: AppLayout.pagePadding(context, admin: true),
      expand: true,
      alignment: Alignment.topCenter,
      child: FutureBuilder<List<dynamic>>(
        future: Future.wait<dynamic>([_agendaFuture, _barbersFuture]),
        builder: (context, snapshot) {
          final loading =
              snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData;
          final bookings = snapshot.hasData
              ? (snapshot.data![0] as List<AdminAgendaBooking>)
              : <AdminAgendaBooking>[];
          final roster = snapshot.hasData
              ? (snapshot.data![1] as List<Barber>)
              : <Barber>[];

          if (snapshot.hasError && !snapshot.hasData) {
            return _AgendaMessage(
              icon: Icons.error_outline_rounded,
              message: 'Não foi possível carregar a agenda.',
              actionLabel: 'Tentar novamente',
              onAction: _reload,
            );
          }

          final filtered = _filterBookings(bookings);
          final columns = _buildColumns(roster: roster, bookings: filtered);
          final barberChipKeys = <(String, String)>[
            (_kAllBarbers, 'Todos'),
            ...roster.map((b) => (b.id, b.name)),
            for (final booking in bookings)
              if (roster.every((b) => b.id != booking.barberId) &&
                  booking.barberName.isNotEmpty)
                (_barberKey(booking), booking.barberName),
          ];
          // unique by key
          final seen = <String>{};
          final chips = <(String, String)>[];
          for (final chip in barberChipKeys) {
            if (seen.add(chip.$1)) chips.add(chip);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminPageHeader(
                title: 'Agenda',
                subtitle:
                    '${_weekdayLong(_selectedDay)} · ${filtered.length} na fila',
              ),
              const SizedBox(height: 10),
              _AgendaToolbar(
                selectedDay: _selectedDay,
                isDesktop: isDesktop,
                columnsView: _columnsView,
                onToggleColumns: (value) =>
                    setState(() => _columnsView = value),
                onPickMonth: _selectDay,
                onNewBooking: _openNewBooking,
              ),
              const SizedBox(height: 10),
              AgendaEliteWeekStrip(
                selectedDay: _selectedDay,
                onDaySelected: (day) {
                  setState(() {
                    _selectedDay = day;
                    _agendaFuture = AdminService.fetchAdminAgenda(day: day);
                  });
                },
              ),
              const SizedBox(height: 10),
              AgendaEliteBarberFilterRow(
                chips: chips,
                selectedKey: _selectedBarberKey,
                onSelected: (key) =>
                    setState(() => _selectedBarberKey = key),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : filtered.isEmpty
                    ? const _AgendaMessage(
                        icon: Icons.event_available_rounded,
                        message: 'Nenhum agendamento para esta data.',
                      )
                    : useColumns
                    ? AgendaEliteBarberColumnsBoard(
                        columns: columns
                            .map(
                              (c) => AgendaEliteColumnData(
                                key: c.key,
                                name: c.name,
                                photoUrl: c.photoUrl,
                                bookings: c.bookings,
                              ),
                            )
                            .toList(growable: false),
                        onBookingTap: _showBookingDetails,
                      )
                    : AgendaElitePeriodListView(
                        bookings: filtered,
                        showBarberName: _selectedBarberKey == _kAllBarbers,
                        onBookingTap: _showBookingDetails,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BarberColumnData {
  _BarberColumnData({
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

class _AgendaToolbar extends StatelessWidget {
  const _AgendaToolbar({
    required this.selectedDay,
    required this.isDesktop,
    required this.columnsView,
    required this.onToggleColumns,
    required this.onPickMonth,
    required this.onNewBooking,
  });

  final DateTime selectedDay;
  final bool isDesktop;
  final bool columnsView;
  final ValueChanged<bool> onToggleColumns;
  final VoidCallback onPickMonth;
  final VoidCallback onNewBooking;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        if (isDesktop) ...[
          _ViewToggle(columnsView: columnsView, onChanged: onToggleColumns),
          const SizedBox(width: 10),
        ],
        InkWell(
          onTap: onPickMonth,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Text(
                  _monthLabel(selectedDay),
                  style: const TextStyle(
                    color: AppColors.primaryBright,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        HeaderActionButton(
          icon: Icons.add_rounded,
          tooltip: 'Novo agendamento',
          onPressed: onNewBooking,
        ),
      ],
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.columnsView, required this.onChanged});

  final bool columnsView;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            label: 'Colunas',
            selected: columnsView,
            onTap: () => onChanged(true),
          ),
          _ToggleChip(
            label: 'Lista',
            selected: !columnsView,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
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
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.background : AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({
    required this.name,
    required this.radius,
    this.imageUrl = '',
  });

  final String name;
  final double radius;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surface,
      backgroundImage: imageUrl.isEmpty ? null : NetworkImage(imageUrl),
      child: imageUrl.isEmpty
          ? Text(
              initial,
              style: TextStyle(
                color: AppColors.primaryBright,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.72,
              ),
            )
          : null,
    );
  }
}

String _weekdayLong(DateTime value) {
  const days = [
    'Domingo',
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
  ];
  const months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  return '${days[value.weekday % 7]}, ${value.day} de ${months[value.month - 1]}';
}

class _BookingDetailsSheet extends StatefulWidget {
  const _BookingDetailsSheet({required this.booking});

  final AdminAgendaBooking booking;

  @override
  State<_BookingDetailsSheet> createState() => _BookingDetailsSheetState();
}

class _BookingDetailsSheetState extends State<_BookingDetailsSheet> {
  bool _saving = false;

  AdminAgendaBooking get booking => widget.booking;

  Future<void> _launchContact(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        showAdminSnack(
          context,
          adminOpError('abrir o contato'),
          error: true,
        );
      }
    } catch (_) {
      if (!mounted) return;
      showAdminSnack(context, adminOpError('abrir o contato'), error: true);
    }
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cancelar agendamento',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tem certeza que deseja cancelar este agendamento?',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AdminOutlineButton(
                        expand: true,
                        label: 'Voltar',
                        onPressed: () => Navigator.pop(dialogContext, false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminDangerButton(
                        expand: true,
                        label: 'Sim, cancelar',
                        onPressed: () => Navigator.pop(dialogContext, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed == true) {
      await _updateStatus('cancelado');
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _saving = true);
    try {
      await AdminService.updateAdminBookingStatus(
        bookingId: booking.id,
        status: status,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAdminSnack(
        context,
        adminOpError('atualizar o agendamento'),
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Detalhes do Agendamento',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundElevated,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _InitialAvatar(
                            name: booking.clientName,
                            radius: 30,
                            imageUrl: booking.clientPhotoUrl,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.clientName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (booking.clientPhone.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    booking.clientPhone,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                if (booking.clientEmail.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    booking.clientEmail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              if (booking.clientPhone.isNotEmpty)
                                _ContactButton(
                                  icon: Icons.phone_outlined,
                                  onTap: () => _launchContact(
                                    Uri(
                                      scheme: 'tel',
                                      path: booking.clientPhone.replaceAll(
                                        RegExp(r'[^\d+]'),
                                        '',
                                      ),
                                    ),
                                  ),
                                ),
                              if (booking.clientPhone.isNotEmpty &&
                                  booking.clientEmail.isNotEmpty)
                                const SizedBox(height: 8),
                              if (booking.clientEmail.isNotEmpty)
                                _ContactButton(
                                  icon: Icons.mail_outline_rounded,
                                  onTap: () => _launchContact(
                                    Uri(
                                      scheme: 'mailto',
                                      path: booking.clientEmail,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundElevated,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.content_cut_rounded,
                            label: 'Serviço',
                            value: booking.serviceName,
                          ),
                          _DetailRow(
                            icon: Icons.schedule_rounded,
                            label: 'Data e Hora',
                            value:
                                '${_formatDate(booking.dateTime)} às ${_formatTime(booking.dateTime)}',
                          ),
                          _DetailRow(
                            icon: Icons.timer_outlined,
                            label: 'Duração',
                            value: '${booking.durationMinutes} minutos',
                          ),
                          _DetailRow(
                            icon: Icons.attach_money_rounded,
                            label: 'Preço',
                            value: _formatCurrency(booking.price),
                          ),
                          _DetailRow(
                            icon: Icons.notes_rounded,
                            label: 'Observações',
                            value: 'Nenhuma observação registrada.',
                            last: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundElevated,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _InitialAvatar(
                            name: booking.barberName,
                            radius: 24,
                            imageUrl: booking.barberPhotoUrl,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Barbeiro',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  booking.barberName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Profissional responsável',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: AdminOutlineButton(
                            expand: true,
                            label: 'Cancelar',
                            icon: Icons.cancel_outlined,
                            destructive: true,
                            onPressed: _saving ? null : _cancelBooking,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AdminPrimaryButton(
                            expand: true,
                            label: _saving ? 'Salvando...' : 'Confirmar',
                            icon: Icons.check_circle_outline_rounded,
                            isLoading: _saving,
                            onPressed: _saving
                                ? null
                                : () => _updateStatus('confirmado'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaMessage extends StatelessWidget {
  const _AgendaMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 42),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _NewCounterBookingDialog extends StatefulWidget {
  const _NewCounterBookingDialog({required this.initialDay});

  final DateTime initialDay;

  @override
  State<_NewCounterBookingDialog> createState() =>
      _NewCounterBookingDialogState();
}

class _NewCounterBookingDialogState extends State<_NewCounterBookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  late DateTime _startAt;
  late Future<_BookingFormData> _dataFuture;
  Barber? _selectedBarber;
  List<AdminAgendaCustomer> _customers = const [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _startAt = DateTime(
      widget.initialDay.year,
      widget.initialDay.month,
      widget.initialDay.day,
      9,
    );
    _dataFuture = _loadFormData();
  }

  Future<_BookingFormData> _loadFormData() async {
    final result = await Future.wait([
      AdminService.fetchAdminBarbers(),
      AdminService.fetchAdminCustomers(),
    ]);
    return _BookingFormData(
      barbers: result[0] as List<Barber>,
      customers: result[1] as List<AdminAgendaCustomer>,
    );
  }

  @override
  void dispose() {
    _customerController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startAt),
    );
    if (time == null) return;
    setState(() {
      _startAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final customerText = _customerController.text.trim().toLowerCase();
    AdminAgendaCustomer? customer;
    for (final item in _customers) {
      if (item.name.trim().toLowerCase() == customerText) {
        customer = item;
        break;
      }
    }
    if (customer == null) {
      showAdminSnack(context, 'Selecione um cliente cadastrado na lista.');
      return;
    }
    if (_selectedBarber == null) return;

    setState(() => _saving = true);
    try {
      await AdminService.createCounterBooking(
        customerId: customer.id,
        barberId: _selectedBarber!.id,
        startAt: _startAt,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        showAdminSnack(
          context,
          adminOpError('salvar o agendamento'),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Novo Agendamento',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: FutureBuilder<_BookingFormData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              width: 360,
              height: 180,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          if (snapshot.hasError) {
            return Text(
              'Não foi possível carregar barbeiros e clientes.',
              style: const TextStyle(color: AppColors.textSecondary),
            );
          }
          final data = snapshot.data!;
          _customers = data.customers;
          return SizedBox(
            width: 420,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogInput(
                    controller: _customerController,
                    label: 'Nome do Cliente',
                    icon: Icons.person_outline_rounded,
                    hint: 'Digite o nome exato do cliente',
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe o cliente'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<Barber>(
                    initialValue: _selectedBarber,
                    dropdownColor: AppColors.backgroundElevated,
                    decoration: _inputDecoration(
                      label: 'Barbeiro',
                      icon: Icons.content_cut_rounded,
                    ),
                    items: data.barbers
                        .map(
                          (barber) => DropdownMenuItem(
                            value: barber,
                            child: Text(barber.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedBarber = value),
                    validator: (value) =>
                        value == null ? 'Selecione o barbeiro' : null,
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickDateTime,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: _inputDecoration(
                        label: 'Data e horário',
                        icon: Icons.schedule_rounded,
                      ),
                      child: Text(
                        '${_formatDate(_startAt)} às ${_formatTime(_startAt)}',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        AdminPrimaryButton(
          label: _saving ? 'Salvando...' : 'Confirmar',
          icon: Icons.check_rounded,
          isLoading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }

  Widget _dialogInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _inputDecoration(label: label, icon: icon, hint: hint),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.surfaceLight.withValues(alpha: 0.25),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}

class _BookingFormData {
  const _BookingFormData({required this.barbers, required this.customers});

  final List<Barber> barbers;
  final List<AdminAgendaCustomer> customers;
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _formatTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _formatCurrency(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

String _monthLabel(DateTime value) {
  const months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return '${months[value.month - 1]} de ${value.year}';
}
