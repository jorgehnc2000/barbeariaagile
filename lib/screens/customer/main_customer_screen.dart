import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/barbershop_resolver.dart';
import '../../core/config/barbershop_runtime_config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/supabase_service.dart';
import '../../data/vip_service.dart';
import '../../models/barbearia_info.dart';
import '../../models/barber.dart';
import '../../models/booking.dart';
import '../../models/booking_status.dart';
import '../../models/service.dart';
import '../../models/user.dart';
import '../../models/vip_subscription.dart';
import '../../widgets/booking/booking_detail_sheet.dart';
import '../../widgets/customer/barbearia_tab_panel.dart';
import '../../widgets/customer/atelier_shell.dart';
import '../../widgets/customer/customer_dialog.dart';
import '../../widgets/customer/customer_empty_state.dart';
import '../../widgets/customer/customer_page_header.dart';
import '../../widgets/customer/v0_booking/v0_booking.dart';
import '../../widgets/customer/v0_dashboard/v0_dashboard.dart';
import '../../widgets/operate/operate_kit.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/screen_background.dart';
import '../barbearia/barbearia_details_screen.dart';
import '../subscription/clube_assinatura_page.dart';

/// Shell principal do app cliente — experiência premium Dark & Gold.
class MainCustomerScreen extends StatefulWidget {
  const MainCustomerScreen({super.key});

  @override
  State<MainCustomerScreen> createState() => _MainCustomerScreenState();
}

/// Alias de compatibilidade com rotas existentes.
typedef HomeScreen = MainCustomerScreen;

class _MainCustomerScreenState extends State<MainCustomerScreen>
    with WidgetsBindingObserver {
  int _index = 0;
  bool _vipTabMounted = false;

  late final Future<List<Barber>> _barbersFuture =
      SupabaseService.fetchBarbers();
  late final Future<List<Service>> _servicesFuture =
      SupabaseService.fetchServices();
  late final Future<BarbeariaInfo> _barbeariaFuture =
      SupabaseService.fetchBarbeariaInfo();
  late Future<List<Booking>> _bookingsFuture =
      SupabaseService.fetchUserBookings();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Garante que o flag do admin (vip_enabled) chegue ao cliente sem F5.
    BarbershopResolver.refreshCurrent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      BarbershopResolver.refreshCurrent();
    }
  }

  void _goTo(int index) => setState(() {
    _index = index;
    if (index == 3) _vipTabMounted = true;
  });

  void _reloadBookings() => setState(() {
    _bookingsFuture = SupabaseService.fetchUserBookings();
  });

  String get _userName {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? {};
    return metadata['full_name']?.toString() ??
        metadata['name']?.toString() ??
        user?.email?.split('@').first ??
        'Cliente';
  }

  String? get _avatarUrl {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? {};
    return metadata['avatar_url'] as String? ?? metadata['picture'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AppLayout.isClientDesktop(context);
    final vipEnabled =
        BarbershopScope.maybeOf(context)?.vipEnabled ??
        BarbershopRuntimeConfig.current?.vipEnabled ??
        false;
    final slot3Label = vipEnabled ? 'Clube VIP' : 'Barbearia';
    final slot3Icon = vipEnabled
        ? Icons.workspace_premium_rounded
        : Icons.storefront_rounded;

    return FutureBuilder<BarbeariaInfo>(
      future: _barbeariaFuture,
      builder: (context, brandSnap) {
        return BrandScope(
          brand: brandSnap.data,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                if (desktop)
                  _DesktopTopNav(
                    currentIndex: _index,
                    onTap: _goTo,
                    brand: brandSnap.data,
                    userName: _userName,
                    avatarUrl: _avatarUrl,
                    vipEnabled: vipEnabled,
                  ),
                Expanded(
                  child: IndexedStack(
                    index: _index,
                    sizing: StackFit.expand,
                    children: [
                      _HomeTab(
                        barbersFuture: _barbersFuture,
                        servicesFuture: _servicesFuture,
                        barbeariaFuture: _barbeariaFuture,
                        bookingsFuture: _bookingsFuture,
                        userName: _userName,
                        avatarUrl: _avatarUrl,
                        vipEnabled: vipEnabled,
                        onOpenSlot3: () => _goTo(3),
                        onOpenAgendar: () => _goTo(1),
                        onOpenAgenda: () => _goTo(2),
                      ),
                      _AgendarTab(
                        barbersFuture: _barbersFuture,
                        servicesFuture: _servicesFuture,
                        userName: _userName,
                        onBooked: _reloadBookings,
                      ),
                      _AgendaTab(
                        bookingsFuture: _bookingsFuture,
                        onReload: _reloadBookings,
                        onOpenAgendar: () => _goTo(1),
                      ),
                      vipEnabled
                          ? (_vipTabMounted
                              ? const ClubeVipView(embedded: true)
                              : const SizedBox.shrink())
                          : BarbeariaTabPanel(onOpenAgendar: () => _goTo(1)),
                      _PerfilTab(
                        onOpenAgendar: () => _goTo(1),
                        vipEnabled: vipEnabled,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            extendBody: true,
            bottomNavigationBar: desktop
                ? null
                : SafeArea(
                    minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: OperateBottomNav(
                      selectedIndex: _index,
                      onSelect: _goTo,
                      items: [
                        (index: 0, icon: Icons.home_rounded, label: 'Início'),
                        (
                          index: 1,
                          icon: Icons.calendar_month_rounded,
                          label: 'Agendar',
                        ),
                        (
                          index: 2,
                          icon: Icons.event_note_rounded,
                          label: 'Agenda',
                        ),
                        (index: 3, icon: slot3Icon, label: slot3Label),
                        (index: 4, icon: Icons.person_rounded, label: 'Perfil'),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// NAV
// ---------------------------------------------------------------------------

class _DesktopTopNav extends StatelessWidget {
  const _DesktopTopNav({
    required this.currentIndex,
    required this.onTap,
    required this.brand,
    required this.userName,
    required this.avatarUrl,
    required this.vipEnabled,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final BarbeariaInfo? brand;
  final String userName;
  final String? avatarUrl;
  final bool vipEnabled;

  List<String> get _links => [
    'Início',
    'Agendar',
    'Agenda',
    vipEnabled ? 'Clube VIP' : 'Barbearia',
    'Perfil',
  ];

  @override
  Widget build(BuildContext context) {
    final first = userName.split(' ').first;
    return Material(
      color: AppColors.card,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.clientMaxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => onTap(0),
                      borderRadius: BorderRadius.circular(8),
                      child: BrandMark(
                        brand: brand,
                        compact: true,
                        subtitle: 'Sua barbearia',
                      ),
                    ),
                    const Spacer(),
                    ...List.generate(_links.length, (i) {
                      final active = currentIndex == i;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: TextButton(
                          onPressed: () => onTap(i),
                          style: TextButton.styleFrom(
                            foregroundColor: active
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _links[i],
                                style: TextStyle(
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(top: 6),
                                height: active ? 2 : 0,
                                width: active ? 24 : 0,
                                color: active
                                    ? AppColors.primary
                                    : Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => onTap(4),
                      borderRadius: BorderRadius.circular(24),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.surfaceLight,
                        backgroundImage: avatarUrl == null
                            ? null
                            : NetworkImage(avatarUrl!),
                        child: avatarUrl == null
                            ? Text(
                                first.isEmpty ? '?' : first[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
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

// ---------------------------------------------------------------------------
// SHARED HELPERS
// ---------------------------------------------------------------------------

EdgeInsets _tabPadding(BuildContext context) {
  final base = AppLayout.pagePadding(context);
  return base.copyWith(bottom: AppLayout.clientBottomInset(context));
}

Booking? _nextAppointment(List<Booking> bookings) {
  final now = DateTime.now();
  final upcoming =
      bookings
          .where(
            (b) =>
                b.status != BookingStatus.cancelled && b.dateTime.isAfter(now),
          )
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  return upcoming.isEmpty ? null : upcoming.first;
}

String _homeSubtitle(Booking? next) {
  if (next == null) {
    return 'Reserve seu horário quando quiser e viva a experiência premium.';
  }
  final time = formatTime(next.dateTime);
  final now = DateTime.now();
  final isToday = next.dateTime.year == now.year &&
      next.dateTime.month == now.month &&
      next.dateTime.day == now.day;
  if (isToday) {
    return 'Você tem um agendamento hoje às $time. Tudo pronto para o seu próximo visual.';
  }
  return 'Próximo horário em ${formatDate(next.dateTime)} às $time.';
}

String _hhmm(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

// ---------------------------------------------------------------------------
// INÍCIO
// ---------------------------------------------------------------------------

class _HomeTab extends StatefulWidget {
  const _HomeTab({
    required this.barbersFuture,
    required this.servicesFuture,
    required this.barbeariaFuture,
    required this.bookingsFuture,
    required this.userName,
    required this.avatarUrl,
    required this.vipEnabled,
    required this.onOpenSlot3,
    required this.onOpenAgendar,
    required this.onOpenAgenda,
  });

  final Future<List<Barber>> barbersFuture;
  final Future<List<Service>> servicesFuture;
  final Future<BarbeariaInfo> barbeariaFuture;
  final Future<List<Booking>> bookingsFuture;
  final String userName;
  final String? avatarUrl;
  final bool vipEnabled;
  final VoidCallback onOpenSlot3;
  final VoidCallback onOpenAgendar;
  final VoidCallback onOpenAgenda;

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  late Future<List<Object?>> _bundle = _load();

  Future<List<Object?>> _load() => Future.wait([
    widget.barbeariaFuture,
    widget.servicesFuture,
    widget.barbersFuture,
    widget.bookingsFuture,
  ]);

  void _retry() {
    setState(() {
      _bundle = Future.wait([
        SupabaseService.fetchBarbeariaInfo(),
        SupabaseService.fetchServices(),
        SupabaseService.fetchBarbers(),
        SupabaseService.fetchUserBookings(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AppLayout.isClientDesktop(context);

    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: ResponsivePage(
          expand: true,
          maxWidth: AppLayout.clientMaxWidth,
          padding: _tabPadding(context),
          child: FutureBuilder<List<Object?>>(
            future: _bundle,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView();
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return ErrorView(
                  message: 'Não foi possível carregar o início.',
                  onRetry: _retry,
                );
              }
              final barbearia = snapshot.data![0] as BarbeariaInfo;
              final services = snapshot.data![1] as List<Service>;
              final barbers = snapshot.data![2] as List<Barber>;
              final bookings = snapshot.data![3] as List<Booking>;
              final next = _nextAppointment(bookings);

              if (desktop) {
                return _HomeDesktop(
                  barbearia: barbearia,
                  serviceCount: services.length,
                  barberCount: barbers.length,
                  next: next,
                  userName: widget.userName,
                  vipEnabled: widget.vipEnabled,
                  onOpenSlot3: widget.onOpenSlot3,
                  onOpenAgendar: widget.onOpenAgendar,
                  onOpenAgenda: widget.onOpenAgenda,
                );
              }

              return _HomeMobile(
                barbearia: barbearia,
                serviceCount: services.length,
                barberCount: barbers.length,
                next: next,
                userName: widget.userName,
                vipEnabled: widget.vipEnabled,
                onOpenSlot3: widget.onOpenSlot3,
                onOpenAgendar: widget.onOpenAgendar,
                onOpenAgenda: widget.onOpenAgenda,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeDesktop extends StatelessWidget {
  const _HomeDesktop({
    required this.barbearia,
    required this.serviceCount,
    required this.barberCount,
    required this.next,
    required this.userName,
    required this.vipEnabled,
    required this.onOpenSlot3,
    required this.onOpenAgendar,
    required this.onOpenAgenda,
  });

  final BarbeariaInfo barbearia;
  final int serviceCount;
  final int barberCount;
  final Booking? next;
  final String userName;
  final bool vipEnabled;
  final VoidCallback onOpenSlot3;
  final VoidCallback onOpenAgendar;
  final VoidCallback onOpenAgenda;

  @override
  Widget build(BuildContext context) {
    final nextTime = next == null ? null : _hhmm(next!.dateTime);

    return CustomScrollView(
      slivers: [
        // Layout espelhando o page.tsx do v0.
        SliverToBoxAdapter(
          child: V0HomeGreeting(
            userName: userName,
            subtitle: _homeSubtitle(next),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 18)),
        SliverToBoxAdapter(
          child: V0StatCards(
            serviceCount: serviceCount,
            barberCount: barberCount,
            nextTime: nextTime,
            nextServiceName: next?.serviceName,
            compact: true,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: V0HeroCta(
                  barbearia: barbearia,
                  onAgendar: onOpenAgendar,
                  tall: true,
                  maxHeight: 360,
                  onOpenBarbearia: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const BarbeariaDetailsScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    if (vipEnabled)
                      _VipStatusCard(
                        onOpenVip: onOpenSlot3,
                        onOpenAgendar: onOpenAgendar,
                      )
                    else
                      BarbeariaSpotlightCard(
                        barbearia: barbearia,
                        onOpenBarbearia: onOpenSlot3,
                      ),
                    const SizedBox(height: 16),
                    V0NextAppointmentCard(
                      booking: next,
                      onOpenAgenda: onOpenAgenda,
                      onAgendar: onOpenAgendar,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

class _HomeMobile extends StatelessWidget {
  const _HomeMobile({
    required this.barbearia,
    required this.serviceCount,
    required this.barberCount,
    required this.next,
    required this.userName,
    required this.vipEnabled,
    required this.onOpenSlot3,
    required this.onOpenAgendar,
    required this.onOpenAgenda,
  });

  final BarbeariaInfo barbearia;
  final int serviceCount;
  final int barberCount;
  final Booking? next;
  final String userName;
  final bool vipEnabled;
  final VoidCallback onOpenSlot3;
  final VoidCallback onOpenAgendar;
  final VoidCallback onOpenAgenda;

  @override
  Widget build(BuildContext context) {
    final nextTime = next == null ? null : _hhmm(next!.dateTime);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: V0HomeGreeting(
            userName: userName,
            subtitle: _homeSubtitle(next),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 22)),
        SliverToBoxAdapter(
          child: V0StatCards(
            serviceCount: serviceCount,
            barberCount: barberCount,
            nextTime: nextTime,
            nextServiceName: next?.serviceName,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: V0HeroCta(
            barbearia: barbearia,
            onAgendar: onOpenAgendar,
            tall: false,
            onOpenBarbearia: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const BarbeariaDetailsScreen(),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: vipEnabled
              ? _VipStatusCard(
                  onOpenVip: onOpenSlot3,
                  onOpenAgendar: onOpenAgendar,
                )
              : BarbeariaSpotlightCard(
                  barbearia: barbearia,
                  onOpenBarbearia: onOpenSlot3,
                ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: V0NextAppointmentCard(
            booking: next,
            onOpenAgenda: onOpenAgenda,
            onAgendar: onOpenAgendar,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// HOME — VIP (lógica preservada; visual v0)
// ---------------------------------------------------------------------------

class _VipStatusCard extends StatefulWidget {
  const _VipStatusCard({required this.onOpenVip, required this.onOpenAgendar});

  final VoidCallback onOpenVip;
  final VoidCallback onOpenAgendar;

  @override
  State<_VipStatusCard> createState() => _VipStatusCardState();
}

class _VipHomeSnapshot {
  const _VipHomeSnapshot({this.subscription, required this.usage});

  final VipSubscription? subscription;
  final VipUsage usage;
}

String _vipUsageSummary(VipUsage usage) {
  if (usage.limit == null) {
    return '${usage.used} uso(s) neste mês · ilimitado';
  }
  if (!usage.hasRemaining) {
    return 'Limite de ${usage.limit} uso(s) atingido neste mês';
  }
  return '${usage.used} de ${usage.limit} uso(s) neste mês';
}

String _vipAuthorizedSubtitle(VipSubscription sub, VipUsage usage) {
  final planLabel = sub.plan?.name.trim().isNotEmpty == true
      ? 'Plano ${sub.plan!.name}'
      : 'Assinatura ativa';
  final usageLine = _vipUsageSummary(usage);

  if (usage.limit != null && !usage.hasRemaining) {
    return '$planLabel · $usageLine.';
  }

  return '$planLabel · cortes cobertos saem por R\$ 0,00. $usageLine.';
}

class _VipStatusCardState extends State<_VipStatusCard> {
  final VipService _vipService = VipService();
  late Future<_VipHomeSnapshot> _future = _load();

  Future<_VipHomeSnapshot> _load() async {
    final subscription = await _vipService.fetchCurrentSubscription();
    final usage = await _vipService.fetchMonthlyUsage(
      subscriptionId: subscription?.id,
    );
    return _VipHomeSnapshot(subscription: subscription, usage: usage);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_VipHomeSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError &&
            snapshot.connectionState != ConnectionState.waiting) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _future = _load()),
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: AtelierVisuals.vipCard(context),
                child: const Row(
                  children: [
                    Icon(Icons.refresh_rounded, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Não foi possível carregar o Clube VIP. Toque para tentar de novo.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final loading = snapshot.connectionState == ConnectionState.waiting;
        final sub = snapshot.data?.subscription;
        final usage = snapshot.data?.usage;
        String subtitle;
        String action;
        Color badgeColor;
        String badge;

        if (loading) {
          subtitle = 'Consultando sua assinatura...';
          action = '...';
          badgeColor = AppColors.textMuted;
          badge = '';
        } else if (sub != null && sub.isAuthorized && usage != null) {
          subtitle = _vipAuthorizedSubtitle(sub, usage);
          action = usage.hasRemaining ? 'Agendar' : 'Ver plano';
          badgeColor = sub.statusColor;
          badge = sub.statusLabel;
        } else if (sub != null && sub.hasMembership) {
          subtitle = sub.isPaused
              ? 'Assinatura pausada — atualize o cartão para reativar o benefício.'
              : 'Pendência no pagamento — benefício pausado até regularizar o cartão.';
          action = 'Regularizar';
          badgeColor = sub.statusColor;
          badge = sub.statusLabel;
        } else if (sub != null && sub.isCancelled) {
          subtitle =
              'Assinatura cancelada. Reative para voltar a pagar R\$ 0,00 nos cortes do plano.';
          action = 'Reativar';
          badgeColor = sub.statusColor;
          badge = sub.statusLabel;
        } else {
          subtitle =
              'Cortes elegíveis do plano saem por R\$ 0,00 no agendamento.';
          action = 'Conhecer';
          badgeColor = AppColors.primary;
          badge = 'Disponível';
        }

        final onAction =
            sub != null &&
                sub.isAuthorized &&
                usage != null &&
                usage.hasRemaining
            ? widget.onOpenAgendar
            : widget.onOpenVip;

        // Visual v0; regras de status/Mercado Pago intactas acima.
        return V0VipClubCard(
          badge: badge,
          badgeColor: badgeColor,
          message: subtitle,
          actionLabel: action,
          onAction: onAction,
          loading: loading,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// AGENDAR
// ---------------------------------------------------------------------------

class _AgendarTab extends StatelessWidget {
  const _AgendarTab({
    required this.barbersFuture,
    required this.servicesFuture,
    required this.userName,
    required this.onBooked,
  });

  final Future<List<Barber>> barbersFuture;
  final Future<List<Service>> servicesFuture;
  final String userName;
  final VoidCallback onBooked;

  @override
  Widget build(BuildContext context) {
    final desktop = AppLayout.isClientDesktop(context);

    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: ResponsivePage(
          expand: true,
          maxWidth: AppLayout.clientMaxWidth,
          padding: _tabPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomerPageHeader(
                title: 'Agendar',
                subtitle:
                    'Escolha serviço e barbeiro — depois confirme o horário.',
                showBrandGreeting: false,
              ),
              if (Supabase.instance.client.auth.currentUser == null) ...[
                const SizedBox(height: 12),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final slug =
                          BarbershopRuntimeConfig.current?.slug.trim();
                      if (slug != null && slug.isNotEmpty) {
                        Navigator.of(context).pushNamed('/$slug/login');
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.lock_open_rounded,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Entre na sua conta para confirmar o agendamento.',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: desktop ? 12 : 20),
              Expanded(
                child: V0BookingFlow(
                  servicesFuture: servicesFuture,
                  barbersFuture: barbersFuture,
                  userName: userName,
                  onBooked: onBooked,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AGENDA
// ---------------------------------------------------------------------------

class _AgendaTab extends StatefulWidget {
  const _AgendaTab({
    required this.bookingsFuture,
    required this.onReload,
    required this.onOpenAgendar,
  });

  final Future<List<Booking>> bookingsFuture;
  final VoidCallback onReload;
  final VoidCallback onOpenAgendar;

  @override
  State<_AgendaTab> createState() => _AgendaTabState();
}

class _AgendaTabState extends State<_AgendaTab> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final desktop = AppLayout.isClientDesktop(context);

    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: ResponsivePage(
          expand: true,
          maxWidth: AppLayout.clientMaxWidth,
          padding: _tabPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomerPageHeader(
                title: 'Agenda',
                subtitle: 'Acompanhe e gerencie seus horários nesta barbearia.',
                trailing: IconButton(
                  onPressed: widget.onReload,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AtelierSegmentTabs(
                labels: const ['Próximos', 'Finalizados'],
                index: _segment,
                onChanged: (value) => setState(() => _segment = value),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Booking>>(
                  future: widget.bookingsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingView();
                    }
                    if (snapshot.hasError) {
                      return ErrorView(
                        message: 'Não foi possível carregar a agenda.',
                        onRetry: widget.onReload,
                      );
                    }
                    final now = DateTime.now();
                    final all = snapshot.data ?? [];
                    final upcoming = all
                        .where(
                          (b) =>
                              b.status != BookingStatus.cancelled &&
                              !b.dateTime.isBefore(now),
                        )
                        .toList();
                    final past = all
                        .where(
                          (b) =>
                              b.status == BookingStatus.cancelled ||
                              b.dateTime.isBefore(now),
                        )
                        .toList();
                    final items = _segment == 0 ? upcoming : past;
                    if (items.isEmpty) {
                      if (_segment == 0) {
                        return CustomerEmptyState(
                          icon: Icons.event_available_rounded,
                          title: 'Nenhum horário marcado',
                          message:
                              'Reserve seu próximo corte em poucos toques.',
                          actionLabel: 'Agendar agora',
                          onAction: widget.onOpenAgendar,
                        );
                      }
                      return const CustomerEmptyState(
                        icon: Icons.history_rounded,
                        title: 'Nenhum histórico ainda',
                        message:
                            'Seus agendamentos finalizados aparecerão aqui.',
                      );
                    }
                    if (desktop) {
                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 2.8,
                            ),
                        itemCount: items.length,
                        itemBuilder: (context, index) => _BookingTile(
                          booking: items[index],
                          onTap: () => BookingDetailSheet.show(
                            context,
                            booking: items[index],
                            onChanged: widget.onReload,
                            onReschedule: widget.onOpenAgendar,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _BookingTile(
                        booking: items[index],
                        onTap: () => BookingDetailSheet.show(
                          context,
                          booking: items[index],
                          onChanged: widget.onReload,
                          onReschedule: widget.onOpenAgendar,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUpcoming =
        booking.status != BookingStatus.cancelled &&
        booking.dateTime.isAfter(DateTime.now());
    final cancelled = booking.status == BookingStatus.cancelled;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUpcoming
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUpcoming
                        ? AppColors.primary.withValues(alpha: 0.40)
                        : AppColors.border,
                  ),
                  color: AppColors.surfaceLight,
                  image: booking.barberPhotoUrl.isEmpty
                      ? null
                      : DecorationImage(
                          image: NetworkImage(booking.barberPhotoUrl),
                          fit: BoxFit.cover,
                        ),
                ),
                child: booking.barberPhotoUrl.isEmpty
                    ? Center(
                        child: Text(
                          booking.barberName.isEmpty
                              ? '?'
                              : booking.barberName[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      booking.serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.barberName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${formatDate(booking.dateTime)} · ${formatTime(booking.dateTime)}',
                      style: TextStyle(
                        color: cancelled
                            ? AppColors.textMuted
                            : AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  booking.coveredByPlan
                      ? const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'R\$ 0,00',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'VIP',
                              style: TextStyle(
                                color: AppColors.primaryBright,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          formatCurrency(booking.price),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (cancelled ? AppColors.error : AppColors.primary)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      booking.status.label,
                      style: TextStyle(
                        color: cancelled
                            ? AppColors.error
                            : AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (isUpcoming)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PERFIL
// ---------------------------------------------------------------------------

class _PerfilTab extends StatefulWidget {
  const _PerfilTab({required this.onOpenAgendar, required this.vipEnabled});

  final VoidCallback onOpenAgendar;
  final bool vipEnabled;

  @override
  State<_PerfilTab> createState() => _PerfilTabState();
}

class _PerfilTabState extends State<_PerfilTab> {
  late Future<UserProfile> _future = SupabaseService.fetchUserProfile();
  late final Future<VipSubscription?> _subscriptionFuture = VipService()
      .fetchCurrentSubscription();

  Future<void> _logout() async {
    final confirmed = await showCustomerDialog(
      context: context,
      title: 'Sair da conta',
      message:
          'Você precisará entrar novamente para agendar ou ver sua agenda.',
      cancelLabel: 'Cancelar',
      confirmLabel: 'Sair',
    );
    if (confirmed != true) return;
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AppLayout.isClientDesktop(context);

    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: ResponsivePage(
          expand: true,
          maxWidth: desktop ? AppLayout.formMaxWidth : AppLayout.clientMaxWidth,
          padding: _tabPadding(context),
          child: FutureBuilder<UserProfile>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView();
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return ErrorView(
                  message: 'Não foi possível carregar o perfil.',
                  onRetry: () => setState(() {
                    _future = SupabaseService.fetchUserProfile();
                  }),
                );
              }
              final profile = snapshot.data!;
              return FutureBuilder<VipSubscription?>(
                future: _subscriptionFuture,
                builder: (context, subSnap) {
                  final subscription = subSnap.data;
                  final showLegacySubscription =
                      !widget.vipEnabled &&
                      subscription != null &&
                      subscription.hasMembership;

                  return ListView(
                    children: [
                      const CustomerPageHeader(
                        title: 'Perfil',
                        subtitle: 'Sua conta e preferências nesta barbearia.',
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.45),
                                  width: 1.5,
                                ),
                                color: AppColors.surfaceLight,
                                image: profile.avatarUrl == null ||
                                        profile.avatarUrl!.isEmpty
                                    ? null
                                    : DecorationImage(
                                        image:
                                            NetworkImage(profile.avatarUrl!),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              child: profile.avatarUrl == null ||
                                      profile.avatarUrl!.isEmpty
                                  ? Center(
                                      child: Text(
                                        profile.name.isEmpty
                                            ? '?'
                                            : profile.name[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              profile.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.email,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AtelierGoldButton(
                        expand: true,
                        weight: AtelierButtonWeight.peak,
                        label: 'Agendar um horário',
                        leading: const Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: AppColors.background,
                        ),
                        onPressed: widget.onOpenAgendar,
                      ),
                      if (showLegacySubscription) ...[
                        const SizedBox(height: 12),
                        AtelierMenuTile(
                          icon: Icons.workspace_premium_outlined,
                          label: subscription.hasMembership &&
                                  !subscription.isAuthorized
                              ? 'Minha assinatura · ${subscription.statusLabel.toLowerCase()}'
                              : 'Minha assinatura',
                          subtitle: 'Gerenciar plano e pagamento',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const ClubeAssinaturaPage(),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 20),
                      AtelierMenuTile(
                        icon: Icons.info_outline_rounded,
                        label: 'Sobre o app',
                        subtitle: 'Como funciona nesta barbearia',
                        onTap: () {
                          showCustomerDialog(
                            context: context,
                            title: 'Sobre',
                            message: widget.vipEnabled
                                ? 'Agende cortes, acompanhe sua agenda e use os benefícios do Clube VIP nesta barbearia.'
                                : 'Agende cortes e acompanhe sua agenda nesta barbearia.',
                            cancelLabel: 'Fechar',
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      AtelierMenuTile(
                        icon: Icons.logout_rounded,
                        label: 'Sair da conta',
                        danger: true,
                        onTap: _logout,
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

