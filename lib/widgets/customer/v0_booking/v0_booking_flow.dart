import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/barbershop_runtime_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/mock_data.dart';
import '../../../data/supabase_service.dart';
import '../../../data/vip_service.dart';
import '../../../models/barber.dart';
import '../../../models/service.dart';
import '../../../models/vip_subscription.dart';
import '../../../screens/subscription/clube_assinatura_page.dart';
import '../../../utils/time_slot_utils.dart';
import '../../responsive_page.dart';
import '../atelier_shell.dart';
import '../customer_dialog.dart';
import '../v0_dashboard/v0_motion.dart';
import 'v0_barber_card.dart';
import 'v0_barber_chip.dart';
import 'v0_schedule_panel.dart';
import 'v0_service_card.dart';
import 'v0_summary_panel.dart';

/// Fluxo Agendar no layout v0 — lógica de slots/VIP/confirmação intacta.
class V0BookingFlow extends StatefulWidget {
  const V0BookingFlow({
    super.key,
    required this.servicesFuture,
    required this.barbersFuture,
    required this.userName,
    this.onBooked,
  });

  final Future<List<Service>> servicesFuture;
  final Future<List<Barber>> barbersFuture;
  final String userName;
  final VoidCallback? onBooked;

  @override
  State<V0BookingFlow> createState() => _V0BookingFlowState();
}

class _V0BookingFlowState extends State<V0BookingFlow> {
  static const int _previewServiceCount = 4;
  static const int _previewBarberCount = 5;

  final _vipService = VipService();

  Service? _service;
  Barber? _barber;
  bool _anyBarber = false;
  List<Service> _services = const [];
  List<Barber> _barbers = const [];
  bool _catalogLoading = true;
  String? _catalogError;

  late final List<DateTime> _weekDays;
  late DateTime _selectedDay;
  String? _selectedTimeSlot;
  bool _isSubmitting = false;
  bool _confirmed = false;

  Map<String, dynamic>? _horarios;
  Set<String> _occupiedSlots = {};
  bool _loadingSlots = true;
  bool _loadingEligibility = true;
  bool _eligibilityFailed = false;
  VipEligibility? _eligibility;
  int _eligibilityRequest = 0;
  GerarSlotsResult _slotsResult = const GerarSlotsResult(
    allSlots: [],
    isClosed: false,
  );

  @override
  void initState() {
    super.initState();
    _weekDays = MockData.upcomingWeekdays();
    _selectedDay = _weekDays.first;
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _catalogLoading = true;
      _catalogError = null;
    });
    try {
      final results = await Future.wait([
        widget.servicesFuture,
        widget.barbersFuture,
      ]);
      if (!mounted) return;
      final services = results[0] as List<Service>;
      final barbers = results[1] as List<Barber>;
      final available = barbers.where((b) => b.isAvailable).toList();
      final preferAny = available.length > 1;
      setState(() {
        _services = services;
        _barbers = barbers;
        _service = services.isNotEmpty ? services.first : null;
        _barber = available.isNotEmpty
            ? available.first
            : (barbers.isNotEmpty ? barbers.first : null);
        _anyBarber = preferAny && _barber != null;
        _catalogLoading = false;
      });
      if (_service != null && _barber != null) {
        _loadScheduleData();
        _loadEligibility();
      } else {
        setState(() => _loadingSlots = false);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _catalogLoading = false;
        _catalogError = 'Não foi possível carregar serviços e barbeiros.';
        _loadingSlots = false;
      });
    }
  }

  Future<void> _loadEligibility() async {
    final service = _service;
    if (service == null) return;

    final vipEnabled = BarbershopRuntimeConfig.current?.vipEnabled ?? false;
    if (!vipEnabled) {
      final now = DateTime.now().toUtc();
      final periodStart = DateTime.utc(now.year, now.month);
      final periodEnd = DateTime.utc(now.year, now.month + 1);
      if (mounted) {
        setState(() {
          _eligibility = VipEligibility(
            eligible: false,
            serviceCovered: false,
            usage: VipUsage(
              used: 0,
              periodStart: periodStart,
              periodEnd: periodEnd,
            ),
            entitlement: VipEntitlementStatus.inactive,
          );
          _loadingEligibility = false;
          _eligibilityFailed = false;
        });
      }
      return;
    }

    final request = ++_eligibilityRequest;
    if (mounted) {
      setState(() {
        _loadingEligibility = true;
        _eligibilityFailed = false;
      });
    }
    try {
      final eligibility = await _vipService.checkEligibility(
        service.id,
        month: _selectedDay,
      );
      if (!mounted || request != _eligibilityRequest) return;
      setState(() {
        _eligibility = eligibility;
        _loadingEligibility = false;
        _eligibilityFailed = false;
      });
    } catch (error) {
      debugPrint('[V0BookingFlow] Erro ao verificar Clube VIP: $error');
      if (!mounted || request != _eligibilityRequest) return;
      setState(() {
        _eligibility = null;
        _loadingEligibility = false;
        _eligibilityFailed = true;
      });
    }
  }

  void _updateGeneratedSlots() {
    _slotsResult = TimeSlotUtils.gerarSlotsDisponiveis(
      horarios: _horarios,
      selectedDay: _selectedDay,
    );
  }

  Future<void> _loadScheduleData() async {
    final barber = _barber;
    if (barber == null) return;

    setState(() => _loadingSlots = true);

    Map<String, dynamic>? horarios;
    Set<String> occupiedSlots = {};

    try {
      horarios = await SupabaseService.fetchBarbeariaHorarios();
    } catch (error) {
      debugPrint('[V0BookingFlow] Erro ao carregar horários: $error');
    }

    try {
      occupiedSlots = await SupabaseService.fetchOccupiedSlots(
        barberId: barber.id,
        day: _selectedDay,
      );
    } catch (error) {
      debugPrint('[V0BookingFlow] Erro ao carregar ocupados: $error');
    }

    if (!mounted) return;

    setState(() {
      _horarios = horarios;
      _occupiedSlots = occupiedSlots;
      _updateGeneratedSlots();
      _selectedTimeSlot =
          _isSlotStillValid(_selectedTimeSlot) ? _selectedTimeSlot : null;
      _loadingSlots = false;
    });
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDay = day;
      _updateGeneratedSlots();
      _selectedTimeSlot =
          _isSlotStillValid(_selectedTimeSlot) ? _selectedTimeSlot : null;
      _confirmed = false;
    });
    _loadScheduleData();
    _loadEligibility();
  }

  void _selectService(Service service) {
    if (_service?.id == service.id) return;
    setState(() {
      _service = service;
      _selectedTimeSlot = null;
      _confirmed = false;
    });
    _loadEligibility();
  }

  void _selectBarber(Barber barber) {
    if (!barber.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este barbeiro está indisponível.')),
      );
      return;
    }
    if (!_anyBarber && _barber?.id == barber.id) return;
    setState(() {
      _anyBarber = false;
      _barber = barber;
      _selectedTimeSlot = null;
      _confirmed = false;
    });
    _loadScheduleData();
  }

  void _selectAnyBarber() {
    final available = _barbers.where((b) => b.isAvailable).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum barbeiro disponível no momento.')),
      );
      return;
    }
    final pick = available.first;
    final same = _anyBarber && _barber?.id == pick.id;
    if (same) return;
    setState(() {
      _anyBarber = true;
      _barber = pick;
      _selectedTimeSlot = null;
      _confirmed = false;
    });
    _loadScheduleData();
  }

  /// Com “Qualquer”, confirma no primeiro barbeiro que ainda tem o slot livre.
  Future<Barber> _resolveAnyBarberForSlot(String slot) async {
    final candidates = _availableBarbers.isNotEmpty
        ? _availableBarbers
        : (_barber != null ? [_barber!] : <Barber>[]);
    if (candidates.isEmpty) {
      throw StateError('Nenhum barbeiro disponível para este horário.');
    }

    Object? lastError;
    for (final candidate in candidates) {
      try {
        final occupied = await SupabaseService.fetchOccupiedSlots(
          barberId: candidate.id,
          day: _selectedDay,
        );
        if (!occupied.contains(slot) &&
            TimeSlotUtils.isSlotAvailableForDay(slot, _selectedDay)) {
          return candidate;
        }
      } catch (error) {
        lastError = error;
        debugPrint(
          '[V0BookingFlow] Falha ao checar slot de ${candidate.name}: $error',
        );
      }
    }

    if (lastError != null) throw lastError;
    throw StateError(
      'Este horário acabou de ser preenchido. Escolha outro.',
    );
  }

  List<Barber> get _availableBarbers =>
      _barbers.where((b) => b.isAvailable).toList();

  List<Service> get _previewServices {
    if (_services.length <= _previewServiceCount) return _services;
    final selected = _service;
    if (selected == null) {
      return _services.take(_previewServiceCount).toList();
    }
    final rest = _services
        .where((s) => s.id != selected.id)
        .take(_previewServiceCount - 1)
        .toList();
    return [selected, ...rest];
  }

  List<Barber> get _previewBarbers {
    final available = _availableBarbers;
    final pool = available.isNotEmpty ? available : _barbers;
    if (pool.length <= _previewBarberCount) return pool;
    final selected = _anyBarber ? null : _barber;
    if (selected == null || !pool.any((b) => b.id == selected.id)) {
      return pool.take(_previewBarberCount).toList();
    }
    final rest = pool
        .where((b) => b.id != selected.id)
        .take(_previewBarberCount - 1)
        .toList();
    return [selected, ...rest];
  }

  Future<void> _openServicesSheet() async {
    final picked = await showModalBottomSheet<Service>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => _CatalogPickerSheet<Service>(
        title: 'Todos os serviços',
        items: _services,
        selectedId: _service?.id,
        searchHint: 'Buscar serviço',
        itemId: (s) => s.id,
        itemTitle: (s) => s.name,
        itemSubtitle: (s) =>
            'R\$ ${s.price.toStringAsFixed(2).replaceAll('.', ',')} · ${s.durationMinutes} min',
        itemBuilder: (service, selected, onTap) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: V0ServiceCard(
            service: service,
            selected: selected,
            onSelect: onTap,
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    _selectService(picked);
  }

  Future<void> _openBarbersSheet() async {
    final picked = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => _CatalogPickerSheet<Barber>(
        title: 'Todos os barbeiros',
        items: _barbers,
        selectedId: _anyBarber ? null : _barber?.id,
        searchHint: 'Buscar barbeiro',
        itemId: (b) => b.id,
        itemTitle: (b) => b.name,
        itemSubtitle: (b) => b.isAvailable
            ? (b.specialty.trim().isEmpty ? 'Barbeiro' : b.specialty)
            : 'Indisponível',
        header: _availableBarbers.length > 1
            ? Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context, _anyBarberToken),
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _anyBarber
                            ? AppColors.primary.withValues(alpha: 0.10)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _anyBarber
                              ? AppColors.primary.withValues(alpha: 0.70)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.15),
                            child: const Icon(
                              Icons.groups_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Qualquer disponível',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Primeiro com horário livre',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_anyBarber)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : null,
        itemBuilder: (barber, selected, onTap) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: V0BarberCard(
            barber: barber,
            selected: selected,
            onSelect: barber.isAvailable ? onTap : null,
          ),
        ),
      ),
    );
    if (!mounted || picked == null) return;
    if (identical(picked, _anyBarberToken)) {
      _selectAnyBarber();
      return;
    }
    if (picked is Barber) _selectBarber(picked);
  }

  bool _isSlotStillValid(String? slot) {
    if (slot == null) return false;
    if (_slotsResult.isClosed) return false;
    if (!_bookableSlots.contains(slot)) return false;
    return TimeSlotUtils.isSlotAvailableForDay(slot, _selectedDay);
  }

  List<String> get _daySlots => _slotsResult.allSlots;

  Set<String> get _pastSlots => TimeSlotUtils.pastSlotsForDay(
        allSlots: _daySlots,
        selectedDay: _selectedDay,
      );

  List<String> get _bookableSlots => _daySlots
      .where(
        (slot) =>
            !_occupiedSlots.contains(slot) &&
            TimeSlotUtils.isSlotAvailableForDay(slot, _selectedDay),
      )
      .toList();

  Map<String, List<String>> get _slotsByPeriod {
    final morning = <String>[];
    final afternoon = <String>[];
    final evening = <String>[];
    for (final slot in _daySlots) {
      final hour = int.tryParse(slot.split(':').first) ?? 0;
      if (hour < 12) {
        morning.add(slot);
      } else if (hour < 18) {
        afternoon.add(slot);
      } else {
        evening.add(slot);
      }
    }
    return {
      if (morning.isNotEmpty) 'Manhã': morning,
      if (afternoon.isNotEmpty) 'Tarde': afternoon,
      if (evening.isNotEmpty) 'Noite': evening,
    };
  }

  DateTime _buildStartDateTime(String timeSlot) {
    final parts = timeSlot.split(':');
    return DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  String _friendlyBookingError(Object error) {
    final raw = error is PostgrestException
        ? (error.message.trim().isNotEmpty
            ? error.message
            : error.toString())
        : error.toString();
    final text = raw.toLowerCase();
    if (text.contains('ocupado') ||
        text.contains('overlap') ||
        text.contains('conflito') ||
        text.contains('already') ||
        text.contains('duplicate') ||
        text.contains('unique')) {
      return 'Este horário acabou de ser preenchido. Escolha outro.';
    }
    if (text.contains('não pertence') ||
        text.contains('nao pertence') ||
        text.contains('42501') ||
        text.contains('23503')) {
      return 'Sua conta ou o serviço/barbeiro não batem com esta barbearia. '
          'Saia e entre de novo pelo link da loja.';
    }
    if (text.contains('intervalo') || text.contains('22023')) {
      return 'Horário inválido para este serviço. Escolha outro horário.';
    }
    if (text.contains('network') ||
        text.contains('socket') ||
        text.contains('timeout') ||
        text.contains('failed host')) {
      return 'Falha de conexão. Verifique a internet e tente de novo.';
    }
    if (text.contains('auth') ||
        text.contains('jwt') ||
        text.contains('28000') ||
        text.contains('não autenticado') ||
        text.contains('nao autenticado')) {
      return 'Sua sessão expirou. Entre novamente para confirmar.';
    }
    if (text.contains('barbearia') && text.contains('url')) {
      return 'Não foi possível identificar a barbearia. Recarregue a página.';
    }
    // Mensagem do backend quando for clara o suficiente para o cliente.
    final cleaned = raw
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^PostgrestException\([^:]*:\s*'), '')
        .trim();
    if (cleaned.isNotEmpty &&
        cleaned.length <= 140 &&
        !cleaned.contains('PostgrestException')) {
      return cleaned;
    }
    return 'Não foi possível confirmar o agendamento. Tente outro horário.';
  }

  String get _dateLabel {
    const weekdays = [
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
      'domingo',
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
    final d = _selectedDay;
    return '${weekdays[d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')} de ${months[d.month - 1]}';
  }

  double get _displayPrice {
    final covered = !_loadingEligibility && _eligibility?.eligible == true;
    return covered ? 0.0 : (_service?.price ?? 0);
  }

  String _formatBRL(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  void _selectNextOpenDay() {
    final index = _weekDays.indexWhere(
      (d) =>
          d.year == _selectedDay.year &&
          d.month == _selectedDay.month &&
          d.day == _selectedDay.day,
    );
    if (index < 0 || index >= _weekDays.length - 1) return;
    _onDaySelected(_weekDays[index + 1]);
  }

  Future<void> _onConfirm() async {
    final service = _service;
    final barber = _barber;
    if (service == null ||
        barber == null ||
        _selectedTimeSlot == null ||
        _isSubmitting) {
      return;
    }

    if (!TimeSlotUtils.isSlotAvailableForDay(
      _selectedTimeSlot!,
      _selectedDay,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este horário já passou. Selecione outro.'),
        ),
      );
      setState(() => _selectedTimeSlot = null);
      return;
    }

    if (_occupiedSlots.contains(_selectedTimeSlot)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este horário acabou de ser preenchido. Escolha outro.',
          ),
        ),
      );
      setState(() => _selectedTimeSlot = null);
      return;
    }

    final clientId = Supabase.instance.client.auth.currentUser?.id;
    if (clientId == null) {
      final goLogin = await showCustomerDialog(
        context: context,
        title: 'Entre para agendar',
        message:
            'Faça login para escolher o horário e confirmar seu corte nesta barbearia.',
        cancelLabel: 'Agora não',
        confirmLabel: 'Entrar',
      );
      if (goLogin == true && mounted) {
        final slug = BarbershopRuntimeConfig.current?.slug.trim();
        if (slug != null && slug.isNotEmpty) {
          await Navigator.of(context).pushNamed('/$slug/login');
        }
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final startAt = _buildStartDateTime(_selectedTimeSlot!);
      final bookingBarber = _anyBarber
          ? await _resolveAnyBarberForSlot(_selectedTimeSlot!)
          : barber;
      final result = await SupabaseService.createBooking(
        barberId: bookingBarber.id,
        serviceId: service.id,
        startAt: startAt,
        durationMinutes: service.durationMinutes,
      );

      if (!mounted) return;

      setState(() {
        _barber = bookingBarber;
        _anyBarber = false;
        _confirmed = true;
        _isSubmitting = false;
      });
      widget.onBooked?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            '${service.name} · ${_selectedTimeSlot!} · '
            '${bookingBarber.name.split(' ').first}'
            '${result.coveredByPlan ? ' · Coberto pelo Plano VIP 👑' : ''}',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    } catch (error) {
      debugPrint('[V0BookingFlow] Falha ao confirmar: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surface,
          content: Text(
            _friendlyBookingError(error),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          action: SnackBarAction(
            label: 'Agenda',
            textColor: AppColors.primary,
            onPressed: () {
              setState(() => _selectedTimeSlot = null);
              _loadScheduleData();
            },
          ),
        ),
      );
      setState(() => _isSubmitting = false);
    }
  }

  void _resetAfterConfirm() {
    setState(() {
      _confirmed = false;
      _selectedTimeSlot = null;
    });
    _loadScheduleData();
    _loadEligibility();
  }

  @override
  Widget build(BuildContext context) {
    if (_catalogLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_catalogError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _catalogError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadCatalog, child: const Text('Tentar de novo')),
          ],
        ),
      );
    }

    if (_services.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum serviço cadastrado.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    if (_barbers.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum barbeiro disponível.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    if (_confirmed && _service != null && _barber != null) {
      return _ConfirmedCard(
        serviceName: _service!.name,
        barberName: _barber!.name,
        dateLabel: _dateLabel,
        time: _selectedTimeSlot ?? '—',
        priceLabel: _formatBRL(_displayPrice),
        onAgain: _resetAfterConfirm,
      );
    }

    final desktop = AppLayout.isClientDesktop(context);
    final canConfirm = _service != null &&
        _barber != null &&
        _barber!.isAvailable &&
        _selectedTimeSlot != null &&
        !_isSubmitting;

    final summary = V0SummaryPanel(
      userName: widget.userName,
      service: _service,
      barber: _barber,
      dateLabel: _dateLabel,
      time: _selectedTimeSlot,
      anyBarber: _anyBarber,
      compact: false,
    );

    final selectionStack = _SelectionStack(
      compact: false,
      services: _previewServices,
      selectedServiceId: _service?.id,
      onSelectService: _selectService,
      showAllServices: _services.length > _previewServiceCount,
      totalServices: _services.length,
      onShowAllServices: _openServicesSheet,
      barbers: _previewBarbers,
      selectedBarberId: _anyBarber ? null : _barber?.id,
      anyBarber: _anyBarber,
      showAnyBarber: _availableBarbers.length > 1,
      onSelectBarber: _selectBarber,
      onSelectAnyBarber: _selectAnyBarber,
      showAllBarbers: _barbers.length > _previewBarberCount,
      totalBarbers: _barbers.length,
      onShowAllBarbers: _openBarbersSheet,
    );

    final schedulePanel = V0SchedulePanel(
      days: _weekDays,
      selectedDay: _selectedDay,
      onSelectDay: _onDaySelected,
      slotsByPeriod: _slotsByPeriod,
      occupiedSlots: _occupiedSlots,
      pastSlots: _pastSlots,
      selectedTime: _selectedTimeSlot,
      onSelectTime: (slot) => setState(() {
        _selectedTimeSlot = slot;
        _confirmed = false;
      }),
      loading: _loadingSlots,
      closedMessage: _slotsResult.isClosed
          ? (_slotsResult.closedMessage ??
              'A barbearia está fechada neste dia.')
          : null,
      onTryAnotherDay: _selectNextOpenDay,
      emptyBookableHint: !_loadingSlots &&
              !_slotsResult.isClosed &&
              _slotsByPeriod.isNotEmpty &&
              _bookableSlots.isEmpty
          ? 'Todos os horários deste dia já passaram ou estão ocupados.'
          : null,
    );

    final priceAndConfirm = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _PriceBlock(
          loading: _loadingEligibility,
          priceLabel: _formatBRL(_displayPrice),
          covered: !_loadingEligibility && _eligibility?.eligible == true,
          eligibilityFailed: _eligibilityFailed,
          eligibility: _eligibility,
          onRegularize: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ClubeAssinaturaPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        V0PressScale(
          enabled: canConfirm,
          child: AtelierGoldButton(
            expand: true,
            weight: AtelierButtonWeight.peak,
            height: desktop ? 48 : 52,
            isLoading: _isSubmitting,
            leading: _isSubmitting
                ? null
                : const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppColors.background,
                  ),
            label: _isSubmitting
                ? 'Confirmando...'
                : 'Confirmar agendamento',
            onPressed: canConfirm ? _onConfirm : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          canConfirm
              ? 'Tudo pronto — é só confirmar.'
              : 'Selecione um horário para confirmar.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );

    final schedule = Container(
      width: double.infinity,
      padding: EdgeInsets.all(desktop ? 20 : 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          schedulePanel,
          SizedBox(height: desktop ? 16 : 20),
          priceAndConfirm,
        ],
      ),
    );

    if (desktop) {
      // Scroll único no desktop: evita painel de horários “cortado” por altura fixa.
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 42,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  selectionStack,
                  const SizedBox(height: 20),
                  summary,
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(flex: 58, child: schedule),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          selectionStack,
          const SizedBox(height: 16),
          summary,
          const SizedBox(height: 20),
          schedule,
        ],
      ),
    );
  }
}

const Object _anyBarberToken = Object();

class _SelectionStack extends StatelessWidget {
  const _SelectionStack({
    required this.compact,
    required this.services,
    required this.selectedServiceId,
    required this.onSelectService,
    required this.showAllServices,
    required this.totalServices,
    required this.onShowAllServices,
    required this.barbers,
    required this.selectedBarberId,
    required this.anyBarber,
    required this.showAnyBarber,
    required this.onSelectBarber,
    required this.onSelectAnyBarber,
    required this.showAllBarbers,
    required this.totalBarbers,
    required this.onShowAllBarbers,
  });

  final bool compact;
  final List<Service> services;
  final String? selectedServiceId;
  final ValueChanged<Service> onSelectService;
  final bool showAllServices;
  final int totalServices;
  final VoidCallback onShowAllServices;
  final List<Barber> barbers;
  final String? selectedBarberId;
  final bool anyBarber;
  final bool showAnyBarber;
  final ValueChanged<Barber> onSelectBarber;
  final VoidCallback onSelectAnyBarber;
  final bool showAllBarbers;
  final int totalBarbers;
  final VoidCallback onShowAllBarbers;

  @override
  Widget build(BuildContext context) {
    final gap = compact ? 8.0 : 12.0;
    final sectionGap = compact ? 16.0 : 22.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(step: '1', title: 'Serviço', compact: compact),
        SizedBox(height: gap),
        for (final service in services) ...[
          V0ServiceCard(
            service: service,
            selected: selectedServiceId == service.id,
            onSelect: () => onSelectService(service),
            compact: compact,
          ),
          SizedBox(height: compact ? 6 : 10),
        ],
        if (showAllServices)
          _SeeAllLink(
            label: 'Ver todos os serviços ($totalServices)',
            onTap: onShowAllServices,
          ),
        SizedBox(height: sectionGap),
        _SectionLabel(step: '2', title: 'Com quem?', compact: compact),
        SizedBox(height: gap),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (showAnyBarber) ...[
                V0AnyBarberChip(
                  selected: anyBarber,
                  onSelect: onSelectAnyBarber,
                ),
                const SizedBox(width: 6),
              ],
              for (final barber in barbers) ...[
                V0BarberChip(
                  barber: barber,
                  selected: !anyBarber && selectedBarberId == barber.id,
                  onSelect: barber.isAvailable
                      ? () => onSelectBarber(barber)
                      : null,
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        if (showAllBarbers) ...[
          const SizedBox(height: 10),
          _SeeAllLink(
            label: 'Ver todos os barbeiros ($totalBarbers)',
            onTap: onShowAllBarbers,
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.step,
    required this.title,
    this.compact = false,
  });

  final String step;
  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 22 : 24,
          height: compact ? 22 : 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.45),
            ),
          ),
          child: Text(
            step,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: compact ? 14 : 16,
          ),
        ),
      ],
    );
  }
}

class _SeeAllLink extends StatelessWidget {
  const _SeeAllLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _CatalogPickerSheet<T> extends StatefulWidget {
  const _CatalogPickerSheet({
    required this.title,
    required this.items,
    required this.selectedId,
    required this.searchHint,
    required this.itemId,
    required this.itemTitle,
    required this.itemSubtitle,
    required this.itemBuilder,
    this.header,
  });

  final String title;
  final List<T> items;
  final String? selectedId;
  final String searchHint;
  final String Function(T) itemId;
  final String Function(T) itemTitle;
  final String Function(T) itemSubtitle;
  final Widget Function(T item, bool selected, VoidCallback onTap) itemBuilder;
  final Widget? header;

  @override
  State<_CatalogPickerSheet<T>> createState() => _CatalogPickerSheetState<T>();
}

class _CatalogPickerSheetState<T> extends State<_CatalogPickerSheet<T>> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.items
        : widget.items.where((item) {
            final title = widget.itemTitle(item).toLowerCase();
            final subtitle = widget.itemSubtitle(item).toLowerCase();
            return title.contains(q) || subtitle.contains(q);
          }).toList();

    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return SafeArea(
      child: SizedBox(
        height: maxHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (widget.items.length > 6)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: TextField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  if (widget.header != null && q.isEmpty) widget.header!,
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Nenhum resultado.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  else
                    for (final item in filtered)
                      widget.itemBuilder(
                        item,
                        widget.selectedId == widget.itemId(item),
                        () => Navigator.pop(context, item),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.loading,
    required this.priceLabel,
    required this.covered,
    required this.eligibilityFailed,
    required this.eligibility,
    required this.onRegularize,
  });

  final bool loading;
  final String priceLabel;
  final bool covered;
  final bool eligibilityFailed;
  final VipEligibility? eligibility;
  final VoidCallback onRegularize;

  @override
  Widget build(BuildContext context) {
    final usage = eligibility?.usage;
    String? usageLabel;
    if (eligibility?.entitlement.isActive == true &&
        eligibility?.serviceCovered == true &&
        usage != null) {
      usageLabel = usage.limit == null
          ? '${usage.used} uso(s) neste mês · ilimitado'
          : '${usage.used} de ${usage.limit} uso(s) neste mês';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: covered
              ? AppColors.primary.withValues(alpha: 0.55)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Valor total',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                Text(
                  priceLabel,
                  style: TextStyle(
                    color: covered
                        ? AppColors.success
                        : AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          if (eligibilityFailed) ...[
            const SizedBox(height: 10),
            const Text(
              'Não foi possível verificar o Clube VIP agora. O valor cheio será cobrado.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          if (covered) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.45),
                ),
              ),
              child: const Text(
                'Benefício Clube VIP Aplicado',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (!loading && eligibility?.isPastDue == true) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1408),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFB74D).withValues(alpha: 0.55),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Identificamos uma pendência no pagamento do seu Clube VIP.\n'
                    'O valor deste agendamento será cobrado normalmente na barbearia.\n'
                    'Para reativar seus benefícios VIP de R\$ 0,00, atualize seu cartão.',
                    style: TextStyle(
                      color: Color(0xFFFFB74D),
                      fontSize: 12,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: onRegularize,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB74D),
                        foregroundColor: const Color(0xFF1A1408),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Atualizar Cartão / Regularizar',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (usageLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              usageLabel,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          if (!loading &&
              eligibility?.entitlement.isActive == true &&
              eligibility?.serviceCovered == true &&
              usage?.hasRemaining == false) ...[
            const SizedBox(height: 8),
            const Text(
              'Limite mensal atingido. Será cobrado o valor normal.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfirmedCard extends StatelessWidget {
  const _ConfirmedCard({
    required this.serviceName,
    required this.barberName,
    required this.dateLabel,
    required this.time,
    required this.priceLabel,
    required this.onAgain,
  });

  final String serviceName;
  final String barberName;
  final String dateLabel;
  final String time;
  final String priceLabel;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.40),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Agendamento confirmado!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$serviceName com $barberName · $dateLabel às $time.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                priceLabel,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 22),
              OutlinedButton(
                onPressed: onAgain,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Fazer outro agendamento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
