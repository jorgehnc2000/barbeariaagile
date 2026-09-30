import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/config/app_urls.dart';
import '../../core/config/barbershop_runtime_config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/supabase_service.dart';
import '../../data/vip_service.dart';
import '../../models/service.dart';
import '../../models/vip_mercado_pago_config.dart';
import '../../models/vip_plan.dart';
import '../../models/vip_subscription.dart';
import '../../widgets/responsive_page.dart';
import 'widgets/admin_ui.dart';

class ClubeVipConfigPage extends StatefulWidget {
  const ClubeVipConfigPage({super.key});

  @override
  State<ClubeVipConfigPage> createState() => _ClubeVipConfigPageState();
}

class _ClubeVipConfigPageState extends State<ClubeVipConfigPage>
    with SingleTickerProviderStateMixin {
  final VipService _vipService = VipService();
  final _mpFormKey = GlobalKey<FormState>();
  final _publicKeyController = TextEditingController();
  final _accessTokenController = TextEditingController();

  late final TabController _tabController;
  late Future<List<VipPlan>> _plansFuture;
  late Future<List<Service>> _servicesFuture;
  late Future<List<VipSubscription>> _subscribersFuture;
  late Future<VipMercadoPagoConfig> _mpConfigFuture;

  bool _savingMp = false;
  bool _showAccessToken = false;
  bool _mpControllersInitialized = false;
  final Set<String> _busyPlanIds = {};
  final Set<String> _busySubscriptionIds = {};
  bool _syncingAllStatuses = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _plansFuture = _vipService.fetchPlans();
    _servicesFuture = SupabaseService.fetchServices();
    _subscribersFuture = _vipService.fetchSubscribers();
    _mpConfigFuture = _vipService.fetchMercadoPagoConfig();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _publicKeyController.dispose();
    _accessTokenController.dispose();
    super.dispose();
  }

  String get _clientUrl {
    final slug = BarbershopRuntimeConfig.current?.slug.trim() ?? '';
    return AppUrls.clientUrlForSlug(slug);
  }

  void _reloadPlans() {
    setState(() => _plansFuture = _vipService.fetchPlans());
  }

  void _reloadSubscribers() {
    setState(() => _subscribersFuture = _vipService.fetchSubscribers());
  }

  void _reloadMpConfig() {
    _mpControllersInitialized = false;
    setState(() => _mpConfigFuture = _vipService.fetchMercadoPagoConfig());
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    showAdminSnack(context, message, error: error);
  }

  String _humanError(String action) => adminOpError(action);

  Future<void> _openPlanForm({
    VipPlan? plan,
    required List<Service> services,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: plan?.name ?? '');
    final descriptionController = TextEditingController(
      text: plan?.description ?? '',
    );
    final benefitsController = TextEditingController(
      text: plan?.benefits.join('\n') ?? '',
    );
    final amountController = TextEditingController(
      text: plan == null
          ? ''
          : plan.monthlyAmount.toStringAsFixed(2).replaceAll('.', ','),
    );
    final limitController = TextEditingController(
      text: plan?.monthlyLimit?.toString() ?? '',
    );
    var frequency = plan?.frequency ?? VipPlanFrequency.monthly;
    // Novo plano nasce inativo até sincronizar Mercado Pago.
    var active = plan?.active ?? false;
    final mpSynchronized = plan?.isMpSynchronized ?? false;
    var unlimited = plan?.monthlyLimit == null;
    final selectedServices = <String>{...?plan?.serviceIds};
    var saving = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: !saving,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> save() async {
                if (saving || !(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                if (selectedServices.isEmpty) {
                  _showMessage(
                    'Selecione ao menos um serviço coberto.',
                    error: true,
                  );
                  return;
                }
                setDialogState(() => saving = true);
                try {
                  final benefits = benefitsController.text
                      .split('\n')
                      .map((item) => item.trim())
                      .where((item) => item.isNotEmpty)
                      .toList();
                  if (active && !mpSynchronized) {
                    _showMessage(
                      'Sincronize o Mercado Pago antes de ativar o plano.',
                      error: true,
                    );
                    setDialogState(() => saving = false);
                    return;
                  }
                  final value = VipPlan(
                    id: plan?.id ?? '',
                    barbershopId: plan?.barbershopId ?? '',
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    benefits: benefits,
                    monthlyAmount: double.parse(
                      amountController.text.trim().replaceAll(',', '.'),
                    ),
                    frequency: frequency,
                    monthlyLimit: unlimited
                        ? null
                        : int.parse(limitController.text.trim()),
                    active: active,
                    mpPlanId: plan?.mpPlanId,
                    mpStatus: plan?.mpStatus ?? VipPlanMpStatus.pending,
                    serviceIds: selectedServices.toList(),
                  );
                  if (plan == null) {
                    await _vipService.createPlan(value);
                  } else {
                    await _vipService.updatePlan(value);
                  }
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _reloadPlans();
                  _showMessage(
                    plan == null
                        ? 'Plano criado. Sincronize o Mercado Pago para poder ativá-lo.'
                        : 'Plano atualizado com sucesso.',
                  );
                } catch (error) {
                  _showMessage(_humanError('salvar o plano'), error: true);
                  if (dialogContext.mounted) {
                    setDialogState(() => saving = false);
                  }
                }
              }

              final width = MediaQuery.sizeOf(context).width;
              return AlertDialog(
                backgroundColor: AppColors.backgroundElevated,
                insetPadding: EdgeInsets.symmetric(
                  horizontal: width < 600 ? 12 : 40,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.28),
                  ),
                ),
                title: Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        plan == null ? 'Novo plano' : 'Editar plano',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 680,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration: _inputDecoration(
                              label: 'Nome do plano',
                              icon: Icons.badge_outlined,
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Informe o nome do plano.'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 2,
                            decoration: _inputDecoration(
                              label: 'Descrição',
                              icon: Icons.notes_rounded,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: benefitsController,
                            minLines: 3,
                            maxLines: 5,
                            decoration: _inputDecoration(
                              label: 'Benefícios (um por linha)',
                              icon: Icons.auto_awesome_rounded,
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Informe ao menos um benefício.'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          AdminCardGrid(
                            gap: 14,
                            columnsForWidth: (width) =>
                                width < 520 ? 1 : 2,
                            children: [
                              TextFormField(
                                controller: amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9,.]'),
                                  ),
                                ],
                                decoration: _inputDecoration(
                                  label: 'Valor mensal',
                                  icon: Icons.payments_outlined,
                                  prefixText: 'R\$ ',
                                ),
                                validator: (value) {
                                  final parsed = double.tryParse(
                                    (value ?? '').replaceAll(',', '.'),
                                  );
                                  return parsed == null || parsed <= 0
                                      ? 'Informe um valor válido.'
                                      : null;
                                },
                              ),
                              DropdownButtonFormField<VipPlanFrequency>(
                                initialValue: frequency,
                                dropdownColor: AppColors.card,
                                decoration: _inputDecoration(
                                  label: 'Frequência',
                                  icon: Icons.event_repeat_rounded,
                                ),
                                items: VipPlanFrequency.values
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(_frequencyLabel(item)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: saving
                                    ? null
                                    : (value) {
                                        if (value != null) {
                                          setDialogState(
                                            () => frequency = value,
                                          );
                                        }
                                      },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            activeTrackColor: AppColors.primary,
                            title: const Text('Limite mensal ilimitado'),
                            subtitle: const Text(
                              'Desative para definir um número de usos.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            value: unlimited,
                            onChanged: saving
                                ? null
                                : (value) =>
                                      setDialogState(() => unlimited = value),
                          ),
                          if (!unlimited) ...[
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: limitController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: _inputDecoration(
                                label: 'Usos por mês',
                                icon: Icons.speed_rounded,
                              ),
                              validator: (value) {
                                if (unlimited) return null;
                                final parsed = int.tryParse(value ?? '');
                                return parsed == null || parsed <= 0
                                    ? 'Informe um limite maior que zero.'
                                    : null;
                              },
                            ),
                          ],
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            activeTrackColor: AppColors.primary,
                            title: const Text('Plano ativo'),
                            subtitle: Text(
                              !mpSynchronized
                                  ? 'Obrigatório sincronizar o Mercado Pago antes de ativar.'
                                  : active
                                  ? 'Visível para novas assinaturas no app.'
                                  : 'Oculto para novas assinaturas.',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            value: active && mpSynchronized,
                            onChanged: saving || !mpSynchronized
                                ? null
                                : (value) =>
                                      setDialogState(() => active = value),
                          ),
                          if (!mpSynchronized) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Status: Pendente — use “Sincronizar Mercado Pago” no card do plano.',
                              style: TextStyle(
                                color: Color(0xFFFF9800),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          const Text(
                            'Serviços cobertos',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'A cobertura é explícita: marque todos os serviços incluídos.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          if (services.isEmpty)
                            _inlineEmpty(
                              'Cadastre serviços antes de criar um plano.',
                            )
                          else
                            Container(
                              constraints: const BoxConstraints(maxHeight: 250),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.surfaceLight,
                                ),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: services.length,
                                separatorBuilder: (_, _) => const Divider(
                                  height: 1,
                                  color: AppColors.surfaceLight,
                                ),
                                itemBuilder: (context, index) {
                                  final service = services[index];
                                  return CheckboxListTile(
                                    value: selectedServices.contains(
                                      service.id,
                                    ),
                                    activeColor: AppColors.primary,
                                    checkColor: AppColors.background,
                                    title: Text(service.name),
                                    subtitle: Text(
                                      '${formatAdminCurrency(service.price)} • ${service.durationMinutes} min',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    onChanged: saving
                                        ? null
                                        : (selected) {
                                            setDialogState(() {
                                              if (selected == true) {
                                                selectedServices.add(
                                                  service.id,
                                                );
                                              } else {
                                                selectedServices.remove(
                                                  service.id,
                                                );
                                              }
                                            });
                                          },
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  AdminPrimaryButton(
                    label: saving ? 'Salvando...' : 'Salvar plano',
                    icon: Icons.save_rounded,
                    isLoading: saving,
                    onPressed: saving || services.isEmpty ? null : save,
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      descriptionController.dispose();
      benefitsController.dispose();
      amountController.dispose();
      limitController.dispose();
    }
  }

  Future<void> _togglePlan(VipPlan plan) async {
    if (_busyPlanIds.contains(plan.id)) return;
    final willActivate = !plan.active;
    if (willActivate && !plan.isMpSynchronized) {
      _showMessage(
        'Sincronize o Mercado Pago antes de ativar este plano.',
        error: true,
      );
      return;
    }
    setState(() => _busyPlanIds.add(plan.id));
    try {
      await _vipService.updatePlan(
        plan.copyWith(active: willActivate),
      );
      _reloadPlans();
      _showMessage(willActivate ? 'Plano ativado.' : 'Plano desativado.');
    } catch (error) {
      _showMessage(
        error is StateError
            ? error.message
            : _humanError('atualizar o plano'),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _busyPlanIds.remove(plan.id));
    }
  }

  Future<void> _syncPlan(VipPlan plan) async {
    if (_busyPlanIds.contains(plan.id)) return;
    setState(() => _busyPlanIds.add(plan.id));
    try {
      await _vipService.syncPlanWithMercadoPago(plan.id);
      _reloadPlans();
      _showMessage('Mercado Pago sincronizado. Plano ativado.');
    } catch (error) {
      _showMessage(_humanError('sincronizar com o Mercado Pago'), error: true);
    } finally {
      if (mounted) setState(() => _busyPlanIds.remove(plan.id));
    }
  }

  Future<void> _deletePlan(VipPlan plan) async {
    final confirmed = await _confirm(
      title: 'Excluir plano?',
      message:
          'O plano “${plan.name}” será removido. Planos com assinaturas vinculadas não podem ser excluídos.',
      actionLabel: 'Excluir',
      destructive: true,
    );
    if (!confirmed || _busyPlanIds.contains(plan.id)) return;
    setState(() => _busyPlanIds.add(plan.id));
    try {
      await _vipService.deletePlan(plan.id);
      _reloadPlans();
      _showMessage('Plano excluído.');
    } catch (error) {
      _showMessage(_humanError('excluir o plano'), error: true);
    } finally {
      if (mounted) setState(() => _busyPlanIds.remove(plan.id));
    }
  }

  Future<void> _cancelSubscription(VipSubscription subscription) async {
    final name = subscription.subscriberName.trim().isEmpty
        ? subscription.subscriberEmail
        : subscription.subscriberName;
    final confirmed = await _confirm(
      title: 'Cancelar assinatura?',
      message:
          'A assinatura de $name será cancelada também no Mercado Pago. Esta ação não pode ser desfeita.',
      actionLabel: 'Confirmar cancelamento',
      destructive: true,
    );
    if (!confirmed || _busySubscriptionIds.contains(subscription.id)) return;
    setState(() => _busySubscriptionIds.add(subscription.id));
    try {
      await _vipService.cancelSubscription(subscription.id);
      _reloadSubscribers();
      _showMessage('Assinatura cancelada com sucesso.');
    } catch (error) {
      _showMessage(_humanError('cancelar a assinatura'), error: true);
    } finally {
      if (mounted) {
        setState(() => _busySubscriptionIds.remove(subscription.id));
      }
    }
  }

  Future<void> _refreshSubscriptionStatus(
    VipSubscription subscription,
  ) async {
    if (_busySubscriptionIds.contains(subscription.id)) return;
    setState(() => _busySubscriptionIds.add(subscription.id));
    try {
      final result = await _vipService.refreshSubscriptionStatus(
        subscription.id,
      );
      _reloadSubscribers();
      final status = result['status']?.toString() ?? subscription.status;
      final lastPaymentStatus =
          result['last_payment_status']?.toString() ??
          subscription.lastPaymentStatus;
      final updated = result['updated'] == true;
      _showMessage(
        updated
            ? 'Status atualizado: ${VipSubscriptionStatus.label(status, lastPaymentStatus: lastPaymentStatus)}'
            : 'Status conferido: ${VipSubscriptionStatus.label(status, lastPaymentStatus: lastPaymentStatus)}',
      );
    } catch (error) {
      _showMessage(_humanError('atualizar o status'), error: true);
    } finally {
      if (mounted) {
        setState(() => _busySubscriptionIds.remove(subscription.id));
      }
    }
  }

  Future<void> _refreshAllSubscriptionStatuses() async {
    if (_syncingAllStatuses) return;
    setState(() => _syncingAllStatuses = true);
    try {
      final result = await _vipService.refreshAllSubscriptionStatuses();
      _reloadSubscribers();
      final updated = result['updated_count'] is int
          ? result['updated_count'] as int
          : int.tryParse('${result['updated_count']}') ?? 0;
      _showMessage(
        updated == 0
            ? 'Nenhum status alterado no Mercado Pago.'
            : '$updated assinatura(s) atualizada(s) com o Mercado Pago.',
      );
    } catch (error) {
      _showMessage(_humanError('sincronizar os status'), error: true);
    } finally {
      if (mounted) setState(() => _syncingAllStatuses = false);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String actionLabel,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.backgroundElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(title),
            content: Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Voltar'),
              ),
              if (destructive)
                AdminDangerButton(
                  label: actionLabel,
                  onPressed: () => Navigator.pop(context, true),
                )
              else
                AdminPrimaryButton(
                  label: actionLabel,
                  onPressed: () => Navigator.pop(context, true),
                ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _saveMpConfig() async {
    if (_savingMp || !(_mpFormKey.currentState?.validate() ?? false)) return;
    setState(() => _savingMp = true);
    try {
      await _vipService.saveMercadoPagoConfig(
        publicKey: _publicKeyController.text,
        accessToken: _accessTokenController.text,
      );
      _reloadMpConfig();
      _showMessage('Credenciais do Mercado Pago salvas.');
    } catch (error) {
      _showMessage(_humanError('salvar as credenciais'), error: true);
    } finally {
      if (mounted) setState(() => _savingMp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return ResponsivePage(
      maxWidth: AppLayout.adminMaxWidth,
      padding: AppLayout.pagePadding(context, admin: true).copyWith(bottom: 0),
      expand: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminPageHeader(
            title: 'Clube VIP',
            subtitle: 'Planos, assinantes e cobrança recorrente.',
          ),
          const SizedBox(height: 18),
          Container(
            decoration: AdminVisuals.surface(context),
            padding: EdgeInsets.zero,
            child: TabBar(
              controller: _tabController,
              isScrollable: compact,
              tabAlignment: compact ? TabAlignment.start : TabAlignment.fill,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
                insets: EdgeInsets.symmetric(horizontal: 12),
              ),
              dividerColor: Colors.transparent,
              labelColor: AppColors.primaryBright,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(
                  icon: Icon(Icons.local_offer_outlined),
                  text: 'Planos & Preços',
                ),
                Tab(icon: Icon(Icons.groups_2_outlined), text: 'Assinantes'),
                Tab(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  text: 'Configurações MP',
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 18 : 22),
          Expanded(
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                return IndexedStack(
                  index: _tabController.index,
                  sizing: StackFit.expand,
                  children: [
                    _buildPlansTab(),
                    _buildSubscribersTab(),
                    _buildMpTab(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansTab() {
    return SizedBox.expand(
      child: FutureBuilder<List<Service>>(
        future: _servicesFuture,
        builder: (context, serviceSnapshot) {
          return FutureBuilder<List<VipPlan>>(
            future: _plansFuture,
            builder: (context, planSnapshot) {
              if (planSnapshot.connectionState == ConnectionState.waiting ||
                  serviceSnapshot.connectionState == ConnectionState.waiting) {
                return _loading();
              }
              if (planSnapshot.hasError || serviceSnapshot.hasError) {
                return _errorState(
                  _humanError('carregar os planos'),
                  () {
                    setState(() {
                      _plansFuture = _vipService.fetchPlans();
                      _servicesFuture = SupabaseService.fetchServices();
                    });
                  },
                );
              }
              final plans = planSnapshot.data ?? const <VipPlan>[];
              final services = serviceSnapshot.data ?? const <Service>[];
              final serviceNames = {
                for (final item in services) item.id: item.name,
              };
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 520;
                      final countLabel =
                          '${plans.length} ${plans.length == 1 ? 'plano cadastrado' : 'planos cadastrados'}';
                      final action = AdminPrimaryButton(
                        label: 'Novo plano',
                        icon: Icons.add_rounded,
                        onPressed: services.isEmpty
                            ? null
                            : () => _openPlanForm(services: services),
                      );
                      if (stacked) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              countLabel,
                              softWrap: true,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: action,
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              countLabel,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          action,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: plans.isEmpty
                        ? _emptyState(
                            icon: Icons.workspace_premium_outlined,
                            title: 'Nenhum plano cadastrado',
                            message: services.isEmpty
                                ? 'Cadastre serviços antes de criar seu primeiro plano VIP.'
                                : 'Crie opções de assinatura com benefícios e coberturas diferentes.',
                            actionLabel: services.isEmpty
                                ? null
                                : 'Criar plano',
                            onAction: services.isEmpty
                                ? null
                                : () => _openPlanForm(services: services),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 28),
                            child: AdminCardGrid(
                              gap: 20,
                              columnsForWidth:
                                  AdminCardGrid.defaultCardColumns,
                              children: [
                                for (final plan in plans)
                                  _planCard(plan, services, serviceNames),
                              ],
                            ),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _planCard(
    VipPlan plan,
    List<Service> services,
    Map<String, String> serviceNames,
  ) {
    final busy = _busyPlanIds.contains(plan.id);
    final coveredNames = plan.serviceIds
        .map((id) => serviceNames[id])
        .whereType<String>()
        .toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AdminVisuals.surface(context, radius: 16).copyWith(
        border: Border.all(
          color: plan.adminStatusIsActive
              ? AppColors.primary.withValues(alpha: 0.28)
              : plan.adminStatusIsPending
              ? const Color(0xFFFF9800).withValues(alpha: 0.45)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminVisuals.goldContainer(context).withValues(
                    alpha: AdminVisuals.isElite(context) ? 1 : 0.18,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: AdminVisuals.isElite(context)
                      ? AdminVisuals.onGoldContainer(context)
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _statusChip(
                      plan.adminStatusLabel,
                      plan.adminStatusIsActive
                          ? AppColors.success
                          : plan.adminStatusIsPending
                          ? const Color(0xFFFF9800)
                          : AppColors.textMuted,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                enabled: !busy,
                color: AppColors.card,
                iconColor: AppColors.textSecondary,
                onSelected: (value) {
                  if (value == 'edit') {
                    _openPlanForm(plan: plan, services: services);
                  } else if (value == 'sync') {
                    _syncPlan(plan);
                  } else if (value == 'delete') {
                    _deletePlan(plan);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(
                    value: 'sync',
                    child: Text(
                      plan.isMpSynchronized
                          ? 'Ressincronizar Mercado Pago'
                          : 'Sincronizar Mercado Pago',
                    ),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatAdminCurrency(plan.monthlyAmount),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(
                  text: ' / mês',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${_frequencyLabel(plan.frequency)} • cobrança de ${formatAdminCurrency(plan.billingAmount)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          _infoLine(
            Icons.speed_rounded,
            plan.monthlyLimit == null
                ? 'Uso mensal ilimitado'
                : '${plan.monthlyLimit} usos por mês',
          ),
          _infoLine(
            Icons.link_rounded,
            plan.isMpSynchronized
                ? 'Mercado Pago sincronizado'
                : 'Mercado Pago pendente — sincronize para ativar',
          ),
          if (plan.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              plan.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Benefícios',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          if (plan.benefits.isEmpty)
            const Text(
              'Nenhum benefício informado.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            ...plan.benefits
                .take(4)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          const Text(
            'Serviços cobertos',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (coveredNames.isEmpty)
            const Text(
              'Nenhum serviço selecionado.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: coveredNames
                  .map(
                    (name) => Chip(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                      label: Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.primaryBright,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 18),
          if (!plan.isMpSynchronized)
            AdminPrimaryButton(
              expand: true,
              label: 'Sincronizar Mercado Pago',
              icon: Icons.sync_rounded,
              isLoading: busy,
              onPressed: busy ? null : () => _syncPlan(plan),
            )
          else
            AdminPrimaryButton(
              expand: true,
              label: plan.active ? 'Desativar' : 'Ativar',
              icon: plan.active
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              isLoading: busy,
              onPressed: busy ? null : () => _togglePlan(plan),
            ),
        ],
      ),
    );
  }

  Widget _buildSubscribersTab() {
    return SizedBox.expand(
      child: FutureBuilder<List<VipSubscription>>(
        future: _subscribersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loading();
          }
          if (snapshot.hasError) {
            return _errorState(
              _humanError('carregar os assinantes'),
              _reloadSubscribers,
            );
          }
          final subscribers = snapshot.data ?? const <VipSubscription>[];
          if (subscribers.isEmpty) {
            return _emptyState(
              icon: Icons.groups_2_outlined,
              title: 'Nenhum assinante',
              message:
                  'As assinaturas aparecerão aqui com cliente, plano e renovação.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${subscribers.length} ${subscribers.length == 1 ? 'assinatura' : 'assinaturas'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  AdminOutlineButton(
                    label: _syncingAllStatuses
                        ? 'Atualizando...'
                        : 'Atualizar status',
                    icon: Icons.sync_rounded,
                    isLoading: _syncingAllStatuses,
                    onPressed: _syncingAllStatuses
                        ? null
                        : _refreshAllSubscriptionStatuses,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 900) {
                      return _subscribersTable(subscribers);
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 28),
                      itemCount: subscribers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, index) =>
                          _subscriberCard(subscribers[index]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _subscribersTable(List<VipSubscription> subscriptions) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: SingleChildScrollView(
        child: DataTable(
          headingTextStyle: const TextStyle(
            color: AppColors.primaryBright,
            fontWeight: FontWeight.w700,
          ),
          dataTextStyle: const TextStyle(color: AppColors.textPrimary),
          dividerThickness: 0.35,
          columns: const [
            DataColumn(label: Text('Assinante')),
            DataColumn(label: Text('Plano')),
            DataColumn(label: Text('Valor')),
            DataColumn(label: Text('Renovação')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Ações')),
          ],
          rows: subscriptions.map((subscription) {
            final busy = _busySubscriptionIds.contains(subscription.id);
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      _avatar(subscription, 34),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 170,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _subscriberName(subscription),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              subscription.subscriberEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(subscription.plan?.name ?? 'Plano removido')),
                DataCell(
                  Text(
                    subscription.plan == null
                        ? '—'
                        : formatAdminCurrency(subscription.plan!.billingAmount),
                  ),
                ),
                DataCell(Text(_formatDate(subscription.nextPaymentDate))),
                DataCell(_subscriptionStatus(subscription)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Atualizar status no Mercado Pago',
                        onPressed: busy
                            ? null
                            : () => _refreshSubscriptionStatus(subscription),
                        icon: busy
                            ? const SizedBox.square(
                                dimension: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.sync_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                      ),
                      TextButton.icon(
                        onPressed: !subscription.canCancel || busy
                            ? null
                            : () => _cancelSubscription(subscription),
                        icon: const Icon(Icons.cancel_outlined, size: 17),
                        label: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _subscriberCard(VipSubscription subscription) {
    final busy = _busySubscriptionIds.contains(subscription.id);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _avatar(subscription, 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _subscriberName(subscription),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (subscription.subscriberEmail.isNotEmpty)
                      Text(
                        subscription.subscriberEmail,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              _subscriptionStatus(subscription),
            ],
          ),
          const Divider(height: 26, color: AppColors.surfaceLight),
          Row(
            children: [
              Expanded(
                child: _metric(
                  'Plano',
                  subscription.plan?.name ?? 'Plano removido',
                ),
              ),
              Expanded(
                child: _metric(
                  'Valor',
                  subscription.plan == null
                      ? '—'
                      : formatAdminCurrency(subscription.plan!.billingAmount),
                ),
              ),
              Expanded(
                child: _metric(
                  'Renovação',
                  _formatDate(subscription.nextPaymentDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AdminOutlineButton(
                  expand: true,
                  label: 'Atualizar status',
                  icon: Icons.sync_rounded,
                  onPressed: busy
                      ? null
                      : () => _refreshSubscriptionStatus(subscription),
                ),
              ),
              if (subscription.canCancel) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: AdminOutlineButton(
                    expand: true,
                    label: busy ? '...' : 'Cancelar',
                    icon: Icons.cancel_outlined,
                    destructive: true,
                    onPressed: busy
                        ? null
                        : () => _cancelSubscription(subscription),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMpTab() {
    return SizedBox.expand(
      child: FutureBuilder<VipMercadoPagoConfig>(
        future: _mpConfigFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loading();
          }
          if (snapshot.hasError) {
            return _errorState(
              _humanError('carregar o Mercado Pago'),
              _reloadMpConfig,
            );
          }
          final config = snapshot.data!;
          if (!_mpControllersInitialized) {
            _publicKeyController.text = config.publicKey;
            _accessTokenController.text = config.accessToken ?? '';
            _mpControllersInitialized = true;
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: _clientUrl.isEmpty
                ? _mpCredentialsCard(config)
                : AdminSplitRow(
                    gap: 24,
                    leftFlex: 5,
                    rightFlex: 3,
                    left: _mpCredentialsCard(config),
                    right: _clientAccessCard(),
                  ),
          );
        },
      ),
    );
  }

  Widget _mpCredentialsCard(VipMercadoPagoConfig config) {
    return _sectionCard(
      child: Form(
        key: _mpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Credenciais Mercado Pago',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _statusChip(
                  config.hasAccessToken ? 'Configurado' : 'Pendente',
                  config.hasAccessToken
                      ? AppColors.success
                      : AppColors.primaryBright,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Estas credenciais são usadas pelos planos deste tenant. Salvar não recria planos.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _publicKeyController,
              decoration: _inputDecoration(
                label: 'Public Key',
                icon: Icons.key_rounded,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe a Public Key.'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _accessTokenController,
              obscureText: !_showAccessToken,
              decoration: _inputDecoration(
                label: 'Access Token',
                icon: Icons.lock_rounded,
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _showAccessToken = !_showAccessToken),
                  icon: Icon(
                    _showAccessToken
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe o Access Token.'
                  : null,
            ),
            const SizedBox(height: 20),
            AdminPrimaryButton(
              expand: true,
              label: _savingMp ? 'Salvando...' : 'Salvar configurações',
              icon: Icons.save_rounded,
              isLoading: _savingMp,
              onPressed: _savingMp ? null : _saveMpConfig,
            ),
          ],
        ),
      ),
    );
  }

  Widget _clientAccessCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Acesso do cliente',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            _clientUrl,
            style: const TextStyle(
              color: AppColors.primaryBright,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final qrSize = (constraints.maxWidth - 8).clamp(140.0, 220.0);
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: QrImageView(
                    data: _clientUrl,
                    version: QrVersions.auto,
                    size: qrSize,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AdminOutlineButton(
              expand: true,
              label: 'Copiar link',
              icon: Icons.copy_rounded,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _clientUrl));
                _showMessage('Link copiado.');
              },
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? prefixText,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.surfaceLight),
    );
    return InputDecoration(
      labelText: label,
      prefixText: prefixText,
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.background,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
      ),
      child: child,
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _subscriptionStatus(VipSubscription subscription) {
    return _statusChip(subscription.statusLabel, subscription.statusColor);
  }

  Widget _avatar(VipSubscription subscription, double size) {
    final url = subscription.subscriberAvatarUrl?.trim() ?? '';
    final name = _subscriberName(subscription);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primary.withValues(alpha: 0.18),
      backgroundImage: url.isEmpty ? null : NetworkImage(url),
      child: url.isEmpty
          ? Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primaryBright,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }

  String _subscriberName(VipSubscription subscription) {
    if (subscription.subscriberName.trim().isNotEmpty) {
      return subscription.subscriberName;
    }
    if (subscription.subscriberEmail.trim().isNotEmpty) {
      return subscription.subscriberEmail;
    }
    return 'Cliente';
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loading() =>
      const Center(child: CircularProgressIndicator(color: AppColors.primary));

  Widget _errorState(String message, VoidCallback retry) {
    return _emptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Não foi possível carregar',
      message: message,
      actionLabel: 'Tentar novamente',
      onAction: retry,
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 38),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                AdminPrimaryButton(
                  label: actionLabel,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _inlineEmpty(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  static String _frequencyLabel(VipPlanFrequency frequency) {
    return switch (frequency) {
      VipPlanFrequency.monthly => 'Mensal',
      VipPlanFrequency.quarterly => 'Trimestral',
      VipPlanFrequency.yearly => 'Anual',
    };
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return 'Não informada';
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }
}
