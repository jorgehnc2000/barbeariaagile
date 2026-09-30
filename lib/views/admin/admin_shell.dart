import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/admin_session.dart';
import '../../core/config/barbershop_runtime_config.dart';
import '../../core/config/barbershop_resolver.dart';
import '../../core/theme/app_colors.dart';
import '../../data/supabase_service.dart';
import '../../models/barbearia_info.dart';
import 'agenda_online_page.dart';
import 'clube_vip_config_page.dart';
import 'dashboard_page.dart';
import 'gerenciar_barbeiros_page.dart';
import 'gerenciar_servicos_page.dart';
import 'info_barbearia_page.dart';
import 'relatorios_page.dart';
import 'widgets/admin_visuals.dart';

/// Layout pai do painel admin: sidebar fixa + header + corpo (IndexedStack).
class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.slug,
    this.initialSection = 'dashboard',
  });

  final String slug;
  final String initialSection;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late int _selectedIndex;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final Future<String> _adminBarbershopFuture;
  late final Future<BarbeariaInfo> _brandFuture =
      SupabaseService.fetchBarbeariaInfo();
  late final List<Widget?> _pageCache;

  static const _destinations = [
    (Icons.dashboard_rounded, 'Dashboard'),
    (Icons.calendar_month_rounded, 'Agenda Online'),
    (Icons.content_cut_rounded, 'Barbeiros'),
    (Icons.design_services_rounded, 'Serviços'),
    (Icons.store_rounded, 'Barbearia'),
    (Icons.workspace_premium_rounded, 'Clube VIP'),
    (Icons.insights_rounded, 'Relatórios'),
  ];
  static const _sectionPaths = [
    'dashboard',
    'agenda',
    'barbeiros',
    'servicos',
    'barbearia',
    'clube-vip',
    'relatorios',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = _indexForSection(widget.initialSection);
    _pageCache = List<Widget?>.filled(_destinations.length, null);
    _pageCache[_selectedIndex] = _buildPage(_selectedIndex);
    _adminBarbershopFuture = _loadAdminBarbershop();
  }

  @override
  void didUpdateWidget(covariant AdminShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = _indexForSection(widget.initialSection);
    if (nextIndex != _selectedIndex) {
      _selectedIndex = nextIndex;
      _pageCache[nextIndex] ??= _buildPage(nextIndex);
    }
  }

  static int _indexForSection(String section) {
    final index = _sectionPaths.indexOf(section.trim().toLowerCase());
    return index < 0 ? 0 : index;
  }

  bool get _vipEnabled => BarbershopRuntimeConfig.current?.vipEnabled ?? false;

  bool _isDestinationVisible(int index) => index != 5 || _vipEnabled;

  void _onVipEnabledChanged(bool enabled) {
    setState(() {
      if (!enabled && _selectedIndex == 5) {
        _selectedIndex = 4;
        _pageCache[4] ??= _buildPage(4);
        SystemNavigator.routeInformationUpdated(
          uri: Uri.parse(_adminPath(4)),
          replace: true,
        );
      }
    });
  }

  String _adminPath(int index) =>
      '/${widget.slug}/admin/${_sectionPaths[index]}';

  void _selectDestination(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
      _pageCache[index] ??= _buildPage(index);
    });
    SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(_adminPath(index)),
      replace: true,
    );
  }

  Widget _buildPageStack() {
    return IndexedStack(
      index: _selectedIndex,
      sizing: StackFit.expand,
      children: List.generate(
        _destinations.length,
        (index) =>
            _pageCache[index] ??
            const SizedBox.expand(
              child: ColoredBox(color: AppColors.background),
            ),
      ),
    );
  }

  Widget _buildPage(int index) {
    return switch (index) {
      0 => const DashboardPage(),
      1 => const AgendaOnlinePage(),
      2 => const GerenciarBarbeirosPage(),
      3 => const GerenciarServicosPage(),
      4 => InfoBarbeariaPage(onVipEnabledChanged: _onVipEnabledChanged),
      5 => const ClubeVipConfigPage(),
      6 => const RelatoriosPage(),
      _ => const DashboardPage(),
    };
  }

  Future<String> _loadAdminBarbershop() async {
    final client = Supabase.instance.client;
    final routeConfig = await BarbershopResolver.resolveBySlug(widget.slug);
    if (routeConfig == null) {
      throw Exception('A barbearia informada na URL não foi encontrada.');
    }

    final userId = client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('Acesso Negado: usuário não autenticado.');
    }

    final row = await client
        .from('users')
        .select('role, barbershop_id')
        .eq('id', userId)
        .maybeSingle();

    final role = row?['role']?.toString().trim().toLowerCase();
    final barbershopId = row?['barbershop_id']?.toString().trim() ?? '';

    if (role != 'admin' || barbershopId.isEmpty) {
      await client.auth.signOut();
      throw Exception(
        'Acesso Negado: Esta conta não possui privilégios de administrador.',
      );
    }

    if (routeConfig.id != barbershopId) {
      throw Exception(
        'Acesso Negado: você não tem permissão para gerenciar esta barbearia.',
      );
    }

    BarbershopRuntimeConfig.current = routeConfig;
    if (!routeConfig.vipEnabled && _selectedIndex == 5) {
      _selectedIndex = 0;
    }
    return routeConfig.id;
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/${widget.slug}/login');
  }

  String? get _adminEmail => Supabase.instance.client.auth.currentUser?.email;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _adminBarbershopFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _AdminAccessDenied(
            slug: widget.slug,
            message:
                snapshot.error?.toString().replaceFirst('Exception: ', '') ??
                'Acesso Negado: Esta conta não possui privilégios de administrador.',
          );
        }

        return AdminSessionScope(
          session: AdminSession(barbershopId: snapshot.data!),
          child: FutureBuilder<BarbeariaInfo>(
            future: _brandFuture,
            builder: (context, brandSnap) => AdminBrandScope(
              brand: brandSnap.data,
              child: _buildAdminShell(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminShell(BuildContext context) {
    final isDesktop = AdminBreakpoints.isDesktop(context);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            _AdminSidebar(
              slug: widget.slug,
              brand: AdminBrandScope.maybeOf(context),
              selectedIndex: _selectedIndex,
              destinations: _destinations,
              isDestinationVisible: _isDestinationVisible,
              onSelect: _selectDestination,
              onHome: () async {
                await BarbershopResolver.refreshCurrent();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/${widget.slug}');
              },
              extended: MediaQuery.sizeOf(context).width >= 1100,
            ),
            Expanded(
              child: Column(
                children: [
                  _AdminTopHeader(
                    brand: AdminBrandScope.maybeOf(context),
                    email: _adminEmail,
                    onLogout: _logout,
                    onHome: () async {
                      await BarbershopResolver.refreshCurrent();
                      if (!context.mounted) return;
                      Navigator.pushReplacementNamed(
                        context,
                        '/${widget.slug}',
                      );
                    },
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: AppColors.background,
                      child: SizedBox.expand(child: _buildPageStack()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final brand = AdminBrandScope.maybeOf(context);
    final shopTitle = AdminBrandScope.shopName(context, fallback: widget.slug);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shopTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              _destinations[_selectedIndex].$2,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Conta',
            color: AppColors.card,
            onSelected: (value) async {
              if (value == 'logout') {
                _logout();
                return;
              }
              if (value == 'home') {
                await BarbershopResolver.refreshCurrent();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/${widget.slug}');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'home', child: Text('Voltar ao app')),
              PopupMenuItem(value: 'logout', child: Text('Sair')),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.18),
                child: Text(
                  (_adminEmail?.isNotEmpty == true)
                      ? _adminEmail![0].toUpperCase()
                      : 'A',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.card,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: AdminBrandMark(
                  brand: brand,
                  subtitle: 'Gestão da casa',
                ),
              ),
              const Divider(color: AppColors.border, height: 1),
              for (var i = 0; i < _destinations.length; i++)
                if (_isDestinationVisible(i))
                  Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Icon(
                      _destinations[i].$1,
                      color: _selectedIndex == i
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    title: Text(
                      _destinations[i].$2,
                      style: TextStyle(
                        color: _selectedIndex == i
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: _selectedIndex == i
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    selected: _selectedIndex == i,
                    selectedTileColor: AppColors.primary.withValues(
                      alpha: 0.12,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _selectDestination(i);
                    },
                  ),
                ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Sair'),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
      body: SizedBox.expand(child: _buildPageStack()),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: _AdminBottomNav(
          selectedIndex: _selectedIndex,
          onSelect: _selectDestination,
          onOpenOperations: _openOperationsSheet,
          onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
    );
  }

  void _openOperationsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Text(
                    'Operações',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: Icon(
                    Icons.content_cut_rounded,
                    color: _selectedIndex == 2
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                  title: const Text('Equipe'),
                  subtitle: const Text('Barbeiros e disponibilidade'),
                  selected: _selectedIndex == 2,
                  selectedTileColor: AppColors.primary.withValues(alpha: 0.12),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _selectDestination(2);
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: Icon(
                    Icons.design_services_rounded,
                    color: _selectedIndex == 3
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                  title: const Text('Serviços'),
                  subtitle: const Text('Preços e catálogo'),
                  selected: _selectedIndex == 3,
                  selectedTileColor: AppColors.primary.withValues(alpha: 0.12),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _selectDestination(3);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.slug,
    required this.brand,
    required this.selectedIndex,
    required this.destinations,
    required this.isDestinationVisible,
    required this.onSelect,
    required this.onHome,
    required this.extended,
  });

  final String slug;
  final BarbeariaInfo? brand;
  final int selectedIndex;
  final List<(IconData, String)> destinations;
  final bool Function(int index) isDestinationVisible;
  final ValueChanged<int> onSelect;
  final VoidCallback onHome;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: extended ? 248 : 92,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                extended ? 20 : 12,
                24,
                extended ? 20 : 12,
                20,
              ),
              child: extended
                  ? AdminBrandMark(
                      brand: brand,
                      subtitle: 'Gestão da casa',
                    )
                  : AdminBrandMark(brand: brand, compact: true),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: AppColors.border, height: 1),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  if (!isDestinationVisible(index)) {
                    return const SizedBox.shrink();
                  }
                  final (icon, label) = destinations[index];
                  final selected = selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onSelect(index),
                        child: Container(
                          decoration: AdminVisuals.navItem(
                            context,
                            selected: selected,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: extended ? 12 : 0,
                            vertical: 11,
                          ),
                          child: Row(
                            mainAxisAlignment: extended
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                            children: [
                              if (extended)
                                AdminVisuals.navAccent(
                                  context,
                                  selected: selected,
                                ),
                              Icon(
                                icon,
                                size: 20,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                              ),
                              if (extended) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: selected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onHome,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: extended ? 14 : 0,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: extended
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.home_rounded,
                          color: AppColors.textMuted,
                          size: 22,
                        ),
                        if (extended) ...[
                          const SizedBox(width: 12),
                          const Text(
                            'Voltar ao app',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTopHeader extends StatelessWidget {
  const _AdminTopHeader({
    required this.brand,
    required this.email,
    required this.onLogout,
    required this.onHome,
  });

  final BarbeariaInfo? brand;
  final String? email;
  final VoidCallback onLogout;
  final Future<void> Function() onHome;

  @override
  Widget build(BuildContext context) {
    final initial = (email != null && email!.isNotEmpty)
        ? email![0].toUpperCase()
        : 'A';

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          AdminBrandMark(
            brand: brand,
            compact: true,
            subtitle: 'Gestão da casa',
          ),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: 'Conta admin',
            color: AppColors.backgroundElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            onSelected: (value) async {
              if (value == 'logout') onLogout();
              if (value == 'home') await onHome();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'home',
                child: const Row(
                  children: [
                    Icon(Icons.home_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Voltar ao app'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    SizedBox(width: 10),
                    Text('Sair', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.18),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      email ?? 'Administrador',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
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

class _AdminBottomNav extends StatelessWidget {
  const _AdminBottomNav({
    required this.selectedIndex,
    required this.onSelect,
    required this.onOpenOperations,
    required this.onOpenMenu,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onOpenOperations;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final items = <({String id, IconData icon, String label, bool active})>[
      (
        id: 'home',
        icon: Icons.home_rounded,
        label: 'Início',
        active: selectedIndex == 0,
      ),
      (
        id: 'agenda',
        icon: Icons.calendar_month_rounded,
        label: 'Agenda',
        active: selectedIndex == 1,
      ),
      (
        id: 'ops',
        icon: Icons.handyman_rounded,
        label: 'Operações',
        active: selectedIndex == 2 || selectedIndex == 3,
      ),
      (
        id: 'more',
        icon: Icons.menu_rounded,
        label: 'Mais',
        active: selectedIndex >= 4,
      ),
    ];

    return Container(
      decoration: AdminVisuals.surface(context, radius: 18),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: InkWell(
              onTap: () {
                if (item.id == 'home') {
                  onSelect(0);
                } else if (item.id == 'agenda') {
                  onSelect(1);
                } else if (item.id == 'ops') {
                  onOpenOperations();
                } else {
                  onOpenMenu();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: item.active
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            item.active ? FontWeight.w600 : FontWeight.w500,
                        color: item.active
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AdminAccessDenied extends StatelessWidget {
  const _AdminAccessDenied({required this.slug, required this.message});

  final String slug;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Acesso Negado'),
          content: Text(
            message.contains('não foi encontrada')
                ? '$message\n\nConfira o endereço: /$slug/admin'
                : message,
          ),
          actions: [
            AdminPrimaryButton(
              label: 'Ir para o login',
              icon: Icons.login_rounded,
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/$slug/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
