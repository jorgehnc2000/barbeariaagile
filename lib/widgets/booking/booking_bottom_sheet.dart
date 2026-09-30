import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/barbershop_runtime_config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock_data.dart';
import '../../data/supabase_service.dart';
import '../../data/vip_service.dart';
import '../../models/barber.dart';
import '../../models/service.dart';
import '../../models/vip_subscription.dart';
import '../../screens/subscription/clube_assinatura_page.dart';
import '../../utils/time_slot_utils.dart';
import '../customer/atelier_shell.dart';
import '../customer/customer_dialog.dart';
import 'day_timeline.dart';
import 'time_slot_grid.dart';

class BookingBottomSheet extends StatefulWidget {
  const BookingBottomSheet({
    super.key,
    required this.service,
    required this.barber,
    this.services = const [],
    this.barbers = const [],
  });

  final Service service;
  final Barber barber;
  final List<Service> services;
  final List<Barber> barbers;

  /// Abre o sheet só se autenticado; caso contrário, oferece porta de login.
  static Future<void> show(
    BuildContext context, {
    required Service service,
    required Barber barber,
    List<Service> services = const [],
    List<Barber> barbers = const [],
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      final goLogin = await showCustomerDialog(
        context: context,
        title: 'Entre para agendar',
        message:
            'Faça login para escolher o horário e confirmar seu corte nesta barbearia.',
        cancelLabel: 'Agora não',
        confirmLabel: 'Entrar',
      );
      if (goLogin == true && context.mounted) {
        final slug = BarbershopRuntimeConfig.current?.slug.trim();
        if (slug != null && slug.isNotEmpty) {
          await Navigator.of(context).pushNamed('/$slug/login');
        }
      }
      return;
    }

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingBottomSheet(
        service: service,
        barber: barber,
        services: services,
        barbers: barbers,
      ),
    );
  }

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  final _vipService = VipService();
  late Service _service;
  late Barber _barber;
  late final List<DateTime> _weekDays;
  late DateTime _selectedDay;
  String? _selectedTimeSlot;
  bool _isSubmitting = false;
  bool _eligibilityFailed = false;

  Map<String, dynamic>? _horarios;
  Set<String> _occupiedSlots = {};
  bool _loadingSlots = true;
  bool _loadingEligibility = true;
  VipEligibility? _eligibility;
  int _eligibilityRequest = 0;
  GerarSlotsResult _slotsResult = const GerarSlotsResult(
    allSlots: [],
    isClosed: false,
  );

  @override
  void initState() {
    super.initState();
    _service = widget.service;
    _barber = widget.barber;
    _weekDays = MockData.upcomingWeekdays();
    _selectedDay = _weekDays.first;
    _loadScheduleData();
    _loadEligibility();
  }

  Future<void> _loadEligibility() async {
    final vipEnabled =
        BarbershopRuntimeConfig.current?.vipEnabled ?? false;
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
        _service.id,
        month: _selectedDay,
      );
      if (!mounted || request != _eligibilityRequest) return;
      setState(() {
        _eligibility = eligibility;
        _loadingEligibility = false;
        _eligibilityFailed = false;
      });
    } catch (error) {
      debugPrint('[BookingBottomSheet] Erro ao verificar Clube VIP: $error');
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
    setState(() => _loadingSlots = true);

    Map<String, dynamic>? horarios;
    Set<String> occupiedSlots = {};

    try {
      horarios = await SupabaseService.fetchBarbeariaHorarios();
    } catch (error) {
      debugPrint('[BookingBottomSheet] Erro ao carregar horários: $error');
    }

    try {
      occupiedSlots = await SupabaseService.fetchOccupiedSlots(
        barberId: _barber.id,
        day: _selectedDay,
      );
    } catch (error) {
      debugPrint('[BookingBottomSheet] Erro ao carregar ocupados: $error');
    }

    if (!mounted) return;

    setState(() {
      _horarios = horarios;
      _occupiedSlots = occupiedSlots;
      _updateGeneratedSlots();
      _selectedTimeSlot = _isSlotStillValid(_selectedTimeSlot)
          ? _selectedTimeSlot
          : null;
      _loadingSlots = false;
    });
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDay = day;
      _updateGeneratedSlots();
      _selectedTimeSlot = _isSlotStillValid(_selectedTimeSlot)
          ? _selectedTimeSlot
          : null;
    });
    _loadScheduleData();
    _loadEligibility();
  }

  bool _isSlotStillValid(String? slot) {
    if (slot == null) return false;
    if (_slotsResult.isClosed) return false;
    if (!_bookableSlots.contains(slot)) return false;
    return TimeSlotUtils.isSlotAvailableForDay(slot, _selectedDay);
  }

  /// Todos os horários do expediente do dia (inclui ocupados e passados).
  List<String> get _daySlots => _slotsResult.allSlots;

  Set<String> get _pastSlots => TimeSlotUtils.pastSlotsForDay(
    allSlots: _daySlots,
    selectedDay: _selectedDay,
  );

  /// Slots livres (não ocupados e não no passado).
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
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      hour,
      minute,
    );
  }

  String _friendlyBookingError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('ocupado') ||
        text.contains('overlap') ||
        text.contains('conflito') ||
        text.contains('already') ||
        text.contains('duplicate')) {
      return 'Este horário acabou de ser preenchido. Escolha outro.';
    }
    if (text.contains('network') ||
        text.contains('socket') ||
        text.contains('timeout') ||
        text.contains('failed host')) {
      return 'Falha de conexão. Verifique a internet e tente de novo.';
    }
    if (text.contains('auth') || text.contains('jwt') || text.contains('28000')) {
      return 'Sua sessão expirou. Entre novamente para confirmar.';
    }
    return 'Não foi possível confirmar o agendamento. Tente outro horário.';
  }

  Future<void> _changeService() async {
    final options = widget.services.isNotEmpty
        ? widget.services
        : [_service];
    if (options.length <= 1) return;
    final picked = await showModalBottomSheet<Service>(
      context: context,
      backgroundColor: AppColors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Text(
              'Trocar serviço',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            for (final service in options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  service.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'R\$ ${service.price.toStringAsFixed(2).replaceAll('.', ',')} · ${service.durationMinutes} min',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                selected: service.id == _service.id,
                onTap: () => Navigator.pop(context, service),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted || picked.id == _service.id) return;
    setState(() {
      _service = picked;
      _selectedTimeSlot = null;
    });
    _loadEligibility();
  }

  Future<void> _changeBarber() async {
    final options = widget.barbers.isNotEmpty
        ? widget.barbers.where((b) => b.isAvailable).toList()
        : [_barber];
    final list = options.isEmpty ? [_barber] : options;
    if (list.length <= 1) return;
    final picked = await showModalBottomSheet<Barber>(
      context: context,
      backgroundColor: AppColors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Text(
              'Trocar barbeiro',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            for (final barber in list)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: barber.photoUrl.trim().isNotEmpty
                      ? NetworkImage(barber.photoUrl)
                      : null,
                  child: barber.photoUrl.trim().isEmpty
                      ? Text(barber.name.isEmpty ? '?' : barber.name[0])
                      : null,
                ),
                title: Text(
                  barber.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                selected: barber.id == _barber.id,
                onTap: () => Navigator.pop(context, barber),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted || picked.id == _barber.id) return;
    setState(() {
      _barber = picked;
      _selectedTimeSlot = null;
    });
    _loadScheduleData();
  }

  Future<void> _onConfirm() async {
    if (_selectedTimeSlot == null || _isSubmitting) return;

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
          content: Text('Este horário acabou de ser preenchido. Escolha outro.'),
        ),
      );
      setState(() => _selectedTimeSlot = null);
      return;
    }

    final clientId = Supabase.instance.client.auth.currentUser?.id;
    if (clientId == null) {
      final goLogin = await showCustomerDialog(
        context: context,
        title: 'Sessão necessária',
        message: 'Entre na sua conta para confirmar este horário.',
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

      final result = await SupabaseService.createBooking(
        barberId: _barber.id,
        serviceId: _service.id,
        startAt: startAt,
        durationMinutes: _service.durationMinutes,
      );

      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            '${_service.name} · ${_selectedTimeSlot!} · '
            '${_barber.name.split(' ').first}'
            '${result.coveredByPlan ? ' · Coberto pelo Plano VIP 👑' : ''}',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    } catch (error) {
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildSlotsSection(BuildContext context) {
    if (_loadingSlots) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_slotsResult.isClosed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            Text(
              _slotsResult.closedMessage ??
                  'A barbearia está fechada neste dia.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _selectNextOpenDay,
              child: const Text('Ver outro dia'),
            ),
          ],
        ),
      );
    }

    final byPeriod = _slotsByPeriod;
    if (byPeriod.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            Text(
              'Nenhum horário disponível para este dia.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _selectNextOpenDay,
              child: const Text('Tentar outro dia'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_bookableSlots.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              'Todos os horários deste dia já passaram ou estão ocupados.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        for (final entry in byPeriod.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 10),
            child: Text(
              entry.key,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          TimeSlotGrid(
            slots: entry.value,
            occupiedSlots: _occupiedSlots,
            pastSlots: _pastSlots,
            selectedSlot: _selectedTimeSlot,
            onSlotSelected: (slot) {
              setState(() => _selectedTimeSlot = slot);
            },
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  void _selectNextOpenDay() {
    final index = _weekDays.indexWhere((d) => d == _selectedDay);
    if (index < 0 || index >= _weekDays.length - 1) return;
    _onDaySelected(_weekDays[index + 1]);
  }

  Widget _buildPriceSummary(BuildContext context) {
    final eligibility = _eligibility;
    final covered = !_loadingEligibility && eligibility?.eligible == true;
    final price = covered ? 0.0 : _service.price;
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
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: covered
              ? AppColors.primary.withValues(alpha: 0.6)
              : const Color(0xFF2A2A2A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Valor', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (_loadingEligibility)
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
                  'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: covered
                        ? AppColors.success
                        : AppColors.primaryBright,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          if (_eligibilityFailed) ...[
            const SizedBox(height: 10),
            Text(
              'Não foi possível verificar o Clube VIP agora. O valor cheio será cobrado.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
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
          if (!_loadingEligibility && eligibility?.isPastDue == true) ...[
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
                    '⚠️ Identificamos uma pendência no pagamento do seu Clube VIP.\n'
                    'O valor deste agendamento será cobrado normalmente na barbearia.\n'
                    'Para reativar seus benefícios VIP de R\$ 0,00, atualize seu cartão no perfil.',
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
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ClubeAssinaturaPage(),
                          ),
                        );
                      },
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (!_loadingEligibility &&
              eligibility?.entitlement.isActive == true &&
              eligibility?.serviceCovered == true &&
              usage?.hasRemaining == false) ...[
            const SizedBox(height: 8),
            Text(
              'Limite mensal atingido. Será cobrado o valor normal.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final canChangeService = widget.services.length > 1;
    final canChangeBarber =
        widget.barbers.where((b) => b.isAvailable).length > 1;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Agendar',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _service.name,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: AppColors.primaryBright,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_service.durationMinutes} min · '
                                  'R\$ ${_service.price.toStringAsFixed(2).replaceAll('.', ',')}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.card,
                            backgroundImage: _barber.photoUrl.trim().isNotEmpty
                                ? NetworkImage(_barber.photoUrl)
                                : null,
                            child: _barber.photoUrl.trim().isEmpty
                                ? Text(
                                    _barber.name.isEmpty
                                        ? '?'
                                        : _barber.name[0].toUpperCase(),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'com ${_barber.name}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    if (canChangeService || canChangeBarber) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            if (canChangeService)
                              TextButton.icon(
                                onPressed: _changeService,
                                icon: const Icon(Icons.swap_horiz_rounded),
                                label: const Text('Trocar serviço'),
                              ),
                            if (canChangeBarber)
                              TextButton.icon(
                                onPressed: _changeBarber,
                                icon: const Icon(Icons.person_outline_rounded),
                                label: const Text('Trocar barbeiro'),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Escolha o dia',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DayTimeline(
                      days: _weekDays,
                      selectedDay: _selectedDay,
                      onDaySelected: _onDaySelected,
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Horários do dia',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSlotsSection(context),
                    const SizedBox(height: 20),
                    _buildPriceSummary(context),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_selectedTimeSlot == null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                'Selecione um horário para confirmar.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textMuted),
                              ),
                            ),
                          AtelierGoldButton(
                            expand: true,
                            weight: AtelierButtonWeight.peak,
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
                            onPressed: _selectedTimeSlot == null || _isSubmitting
                                ? null
                                : _onConfirm,
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
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
      ),
    );
  }
}
