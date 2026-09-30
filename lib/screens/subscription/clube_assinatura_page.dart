import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/barbershop_runtime_config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/supabase_payment_service.dart';
import '../../data/supabase_service.dart';
import '../../data/vip_service.dart';
import '../../models/barbearia_info.dart';
import '../../models/service.dart';
import '../../models/vip_plan.dart';
import '../../models/vip_subscription.dart';
import '../../widgets/customer/atelier_shell.dart';
import '../../widgets/customer/customer_form.dart';
import '../../widgets/customer/customer_page_header.dart';
import '../../widgets/customer/customer_scaffold.dart';
import '../../utils/card_brand_utils.dart';
import '../../widgets/customer/customer_vip_header.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/screen_background.dart';

/// Rota empilhada (booking, perfil, etc.) — mesmo corpo da aba Clube VIP.
class ClubeAssinaturaPage extends StatelessWidget {
  const ClubeAssinaturaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomerScaffold(
      showBack: true,
      maxWidth: 900,
      child: ClubeVipView(),
    );
  }
}

/// Componente único do Clube VIP (aba + rota).
///
/// - Sem assinatura: grade com todos os planos ativos.
/// - Com assinatura (ativa / atraso / pausada): card do plano atual;
///   form de cartão se pendente; "Ver outros planos / Alterar plano" abre modal.
class ClubeVipView extends StatefulWidget {
  const ClubeVipView({super.key, this.embedded = false});

  /// `true` na aba do shell (sem scroll externo do [CustomerScaffold]).
  final bool embedded;

  @override
  State<ClubeVipView> createState() => _ClubeVipViewState();
}

class _ClubeVipViewState extends State<ClubeVipView> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardholderController = TextEditingController();
  final _payerEmailController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _paymentService = SupabasePaymentService();
  final _vipService = VipService();

  bool _isLoading = false;
  bool _isCatalogLoading = true;
  /// Usuário com membership escolheu outro plano no modal (aguardando cartão).
  bool _changingPlan = false;
  String? _catalogError;
  List<VipPlan> _plans = const [];
  Map<String, Service> _servicesById = const {};
  VipPlan? _selectedPlan;
  VipSubscription? _currentSubscription;
  late final Future<BarbeariaInfo> _barbeariaFuture =
      SupabaseService.fetchBarbeariaInfo();

  bool get _hasMembership => _currentSubscription?.hasMembership == true;

  bool get _needsCardUpdate {
    final sub = _currentSubscription;
    if (!_hasMembership || sub == null) return false;
    return sub.isPastDue || sub.isPaymentPastDue || sub.isPaused;
  }

  VipPlan? get _currentPlan {
    final sub = _currentSubscription;
    if (sub == null || !_hasMembership) return null;
    for (final plan in _plans) {
      if (plan.id == sub.planId) return plan;
    }
    return sub.plan;
  }

  bool get _isPlanChange =>
      _hasMembership &&
      _changingPlan &&
      _selectedPlan != null &&
      _selectedPlan!.id != _currentPlan?.id;

  /// Form de cartão na mesma tela.
  bool get _showPaymentForm {
    if (_selectedPlan == null) return false;
    if (!_hasMembership) return true;
    if (_needsCardUpdate) return true;
    if (_isPlanChange) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email != null && email.isNotEmpty) {
      _payerEmailController.text = email;
    }
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    if (mounted) {
      setState(() {
        _isCatalogLoading = true;
        _catalogError = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        _vipService.fetchClientReadyPlans(),
        SupabaseService.fetchServices(),
        _vipService.fetchCurrentSubscription(),
      ]);
      final plans = results[0] as List<VipPlan>;
      final services = results[1] as List<Service>;
      final subscription = results[2] as VipSubscription?;
      final hasMembership = subscription?.hasMembership == true;
      final subscribedPlanId = hasMembership ? subscription!.planId : null;

      VipPlan? selectedPlan;
      if (hasMembership && subscribedPlanId != null) {
        for (final plan in plans) {
          if (plan.id == subscribedPlanId) {
            selectedPlan = plan;
            break;
          }
        }
        selectedPlan ??= subscription?.plan;
      } else if (plans.isNotEmpty) {
        selectedPlan = plans.first;
      }

      if (!mounted) return;
      setState(() {
        _plans = plans;
        _servicesById = {for (final service in services) service.id: service};
        _currentSubscription = subscription;
        _selectedPlan = selectedPlan;
        _changingPlan = false;
        _isCatalogLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _catalogError = _friendlyError(error);
        _isCatalogLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardholderController.dispose();
    _payerEmailController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _selectPlan(VipPlan plan) {
    if (_isLoading) return;
    setState(() => _selectedPlan = plan);
  }

  void _cancelPlanChange() {
    setState(() {
      _changingPlan = false;
      _selectedPlan = _currentPlan ?? _selectedPlan;
    });
  }

  Future<void> _openPlanPicker() async {
    if (_plans.isEmpty || _isLoading) return;

    final chosen = await showModalBottomSheet<VipPlan>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _PlanPickerSheet(
          plans: _plans,
          currentPlanId: _currentSubscription?.planId,
          subscription: _currentSubscription,
          servicesById: _servicesById,
        );
      },
    );

    if (!mounted || chosen == null) return;

    if (chosen.id == _currentPlan?.id) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Este já é o seu plano atual.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    if (chosen.mpPlanId == null || chosen.mpPlanId!.isEmpty) {
      _showError('Este plano ainda não está disponível para assinatura.');
      return;
    }

    setState(() {
      _selectedPlan = chosen;
      _changingPlan = true;
    });
  }

  Future<void> _submitPayment() async {
    if (_isLoading || !(_formKey.currentState?.validate() ?? false)) return;
    final selectedPlan = _selectedPlan;
    if (selectedPlan == null) {
      _showError('Selecione um plano para continuar.');
      return;
    }
    if (selectedPlan.mpPlanId == null || selectedPlan.mpPlanId!.isEmpty) {
      _showError('Este plano ainda não está disponível para assinatura.');
      return;
    }

    final vipEnabled = BarbershopRuntimeConfig.current?.vipEnabled ?? false;
    if (!vipEnabled) {
      _showError('O Clube VIP não está habilitado nesta barbearia.');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showError('Faça login para assinar o Clube VIP.');
      return;
    }

    final barbershop = BarbershopScope.maybeOf(context);
    if (barbershop == null) {
      _showError(
        'Barbearia não encontrada para esta URL. Acesse pelo link correto.',
      );
      return;
    }

    final payerEmail = _payerEmailController.text.trim();
    final accountEmail = user.email?.trim().toLowerCase();
    if (accountEmail == null || payerEmail.toLowerCase() != accountEmail) {
      _showError('Use o mesmo e-mail da sua conta para assinar.');
      return;
    }

    if (barbershop.mpPublicKey == 'public_key_not_configured') {
      _showError('Configure a Public Key do Mercado Pago antes de continuar.');
      return;
    }

    final isChange = _isPlanChange;
    if (isChange) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Confirmar troca de plano'),
          content: Text(
            'Vamos atualizar sua assinatura no Mercado Pago para '
            '${selectedPlan.name}. A cobrança passa a seguir o novo plano.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Confirmar',
                style: TextStyle(color: AppColors.primaryBright),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _isLoading = true);

    try {
      final cardTokenId = await _createCardToken(barbershop.mpPublicKey);

      if (isChange) {
        await _paymentService.changePlan(
          userId: user.id,
          barbershopId: barbershop.id,
          planId: selectedPlan.id,
          cardTokenId: cardTokenId,
          email: payerEmail,
        );
      } else {
        await _paymentService.createSubscription(
          userId: user.id,
          barbershopId: barbershop.id,
          planId: selectedPlan.id,
          cardTokenId: cardTokenId,
          email: payerEmail,
        );
      }

      if (!mounted) return;
      await _showSuccess(planChanged: isChange);
      await _loadCatalog();
    } catch (error) {
      if (mounted) _showError(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _createCardToken(String publicKey) async {
    final expiry = _expiryController.text.replaceAll('/', '');
    final response = await http.post(
      Uri.https('api.mercadopago.com', '/v1/card_tokens', {
        'public_key': publicKey,
      }),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'card_number': _cardNumberController.text.replaceAll(' ', ''),
        'expiration_month': int.parse(expiry.substring(0, 2)),
        'expiration_year': int.parse('20${expiry.substring(2, 4)}'),
        'security_code': _cvvController.text,
        'cardholder': {'name': _cardholderController.text.trim()},
      }),
    );

    final body = _decodeBody(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        body['message'] ??
            body['error'] ??
            'Não foi possível validar o cartão.',
      );
    }

    final tokenId = body['id']?.toString();
    if (tokenId == null || tokenId.isEmpty) {
      throw Exception('O Mercado Pago não retornou um token válido.');
    }
    return tokenId;
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) return {};
    final decoded = jsonDecode(body);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
  }

  String _friendlyError(Object error) {
    if (error is SupabasePaymentException) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
  }

  Future<void> _showSuccess({required bool planChanged}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SubscriptionSuccessDialog(planChanged: planChanged),
    );
  }

  String? _validateExpiry(String? value) {
    final expiry = value?.replaceAll('/', '') ?? '';
    if (expiry.length != 4) return 'Use MM/AA.';

    final month = int.tryParse(expiry.substring(0, 2));
    final year = int.tryParse(expiry.substring(2, 4));
    if (month == null || month < 1 || month > 12 || year == null) {
      return 'Vencimento inválido.';
    }

    final now = DateTime.now();
    final currentYear = now.year % 100;
    if (year < currentYear || (year == currentYear && month < now.month)) {
      return 'Cartão vencido.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final vipEnabled = BarbershopRuntimeConfig.current?.vipEnabled ?? false;

    final Widget body;
    if (_isCatalogLoading) {
      body = const LoadingView();
    } else if (_catalogError != null) {
      body = ErrorView(
        message: _catalogError!,
        onRetry: _loadCatalog,
      );
    } else if (!vipEnabled && !_hasMembership) {
      body = const ErrorView(
        message: 'O Clube VIP não está disponível nesta barbearia no momento.',
      );
    } else {
      body = Form(key: _formKey, child: _buildContent());
    }

    final scrollable = body is Form;
    final pageChild = scrollable
        ? SingleChildScrollView(child: body)
        : body;

    if (!widget.embedded) return pageChild;

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: ResponsivePage(
          expand: true,
          maxWidth: AppLayout.clientMaxWidth,
          padding: AppLayout.pagePadding(context).copyWith(
            bottom: AppLayout.clientBottomInset(context),
          ),
          child: pageChild,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final splitDesktop =
            constraints.maxWidth >= 900 && _showPaymentForm;

        final top = <Widget>[
          CustomerPageHeader(
            title: 'Clube VIP',
            subtitle: _needsCardUpdate
                ? 'Atualize o cartão para reativar o benefício.'
                : _isPlanChange
                ? 'Finalize a troca para o novo plano.'
                : _hasMembership
                ? 'Sua assinatura nesta barbearia.'
                : 'Planos e benefícios exclusivos nesta casa.',
          ),
          const SizedBox(height: 16),
          FutureBuilder<BarbeariaInfo>(
            future: _barbeariaFuture,
            builder: (context, snapshot) {
              final name = snapshot.data?.name.trim();
              return CustomerVipPromoHeader(
                brandName: (name == null || name.isEmpty) ? 'Barbearia' : name,
                tagline: _needsCardUpdate
                    ? 'Atualize o cartão para reativar o benefício.'
                    : _isPlanChange
                    ? 'Finalize a troca para o novo plano.'
                    : _hasMembership
                    ? 'Sua assinatura nesta barbearia.'
                    : 'Seu estilo merece tratamento exclusivo.',
              );
            },
          ),
          if (_needsCardUpdate && !_isPlanChange) ...[
            const SizedBox(height: 16),
            const _PastDueBanner(),
          ],
        ];

        if (!splitDesktop) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...top,
              const SizedBox(height: 24),
              _buildPlansSection(),
              if (_showPaymentForm) ...[
                const SizedBox(height: 28),
                _buildPaymentSection(),
              ],
              const SizedBox(height: 28),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...top,
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPlansSection()),
                const SizedBox(width: 24),
                Expanded(child: _buildPaymentSection()),
              ],
            ),
            const SizedBox(height: 28),
          ],
        );
      },
    );
  }

  Widget _buildPlansSection() {
    if (!_hasMembership) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _VipSectionHeader(
            title: 'Escolha seu plano',
            subtitle: 'Compare benefícios e serviços incluídos.',
          ),
          const SizedBox(height: 16),
          _PlanGrid(
            plans: _plans,
            selectedPlanId: _selectedPlan?.id,
            currentPlanId: null,
            subscription: null,
            servicesById: _servicesById,
            enabled: !_isLoading,
            onSelect: _selectPlan,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VipSectionHeader(
          title: 'Seu plano',
          subtitle: _isPlanChange
              ? 'Você selecionou ${_selectedPlan!.name}. Confirme o pagamento para concluir.'
              : _needsCardUpdate
              ? 'Atualize o cartão para retomar o benefício.'
              : 'Gerencie sua assinatura ou altere para outro plano.',
        ),
        const SizedBox(height: 16),
        if (_isPlanChange && _selectedPlan != null)
          _VipPlanCard(
            plan: _selectedPlan!,
            selected: true,
            isCurrent: false,
            subscription: _currentSubscription,
            servicesById: _servicesById,
            onTap: null,
          )
        else if (_currentPlan != null)
          _VipPlanCard(
            plan: _currentPlan!,
            selected: true,
            isCurrent: true,
            subscription: _currentSubscription,
            servicesById: _servicesById,
            onTap: null,
          )
        else
          const _CatalogMessage(
            icon: Icons.workspace_premium_outlined,
            message: 'Não encontramos o plano vinculado à sua assinatura.',
          ),
        const SizedBox(height: 14),
        if (_isPlanChange)
          TextButton(
            onPressed: _isLoading ? null : _cancelPlanChange,
            child: const Text(
              'Cancelar troca de plano',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          OutlinedButton(
            onPressed: _plans.isEmpty ? null : _openPlanPicker,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBright,
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.55),
              ),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Ver outros planos / Alterar plano'
              '${_plans.isEmpty ? '' : ' (${_plans.length})'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    if (!_showPaymentForm) return const SizedBox.shrink();

    final paymentTitle = _isPlanChange
        ? 'Confirmar novo plano'
        : _needsCardUpdate
        ? 'Atualizar cartão'
        : 'Pagamento seguro';
    final paymentSubtitle = _isPlanChange
        ? 'Informe o cartão para o Mercado Pago ativar ${_selectedPlan?.name ?? 'o novo plano'}.'
        : _needsCardUpdate
        ? 'Tokenizamos o cartão com o Mercado Pago para retomar a cobrança.'
        : 'Seus dados são tokenizados pelo Mercado Pago.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VipSectionHeader(title: paymentTitle, subtitle: paymentSubtitle),
        const SizedBox(height: 16),
        _VipPaymentSurface(
          child: _PaymentForm(
            cardNumberController: _cardNumberController,
            cardholderController: _cardholderController,
            payerEmailController: _payerEmailController,
            expiryController: _expiryController,
            cvvController: _cvvController,
            validateExpiry: _validateExpiry,
          ),
        ),
        const SizedBox(height: 20),
        _SubscribeButton(
          plan: _selectedPlan,
          isLoading: _isLoading,
          pastDue: _needsCardUpdate && !_isPlanChange,
          planChange: _isPlanChange,
          onPressed: _submitPayment,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Building blocks (DRY)
// ---------------------------------------------------------------------------

class _VipSectionHeader extends StatelessWidget {
  const _VipSectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _VipPaymentSurface extends StatelessWidget {
  const _VipPaymentSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.primaryBright,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mercado Pago',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Dados do cartão criptografados — não armazenamos o número.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: AppColors.textMuted.withValues(alpha: 0.9),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(
            height: 1,
            color: AppColors.border.withValues(alpha: 0.85),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _PlanGrid extends StatelessWidget {
  const _PlanGrid({
    required this.plans,
    required this.selectedPlanId,
    required this.currentPlanId,
    required this.subscription,
    required this.servicesById,
    required this.enabled,
    required this.onSelect,
  });

  final List<VipPlan> plans;
  final String? selectedPlanId;
  final String? currentPlanId;
  final VipSubscription? subscription;
  final Map<String, Service> servicesById;
  final bool enabled;
  final ValueChanged<VipPlan> onSelect;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return const _CatalogMessage(
        icon: Icons.workspace_premium_outlined,
        message: 'Nenhum plano VIP está disponível no momento.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        if (wide && plans.length == 2) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < 2; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i == 0 ? 8 : 0, left: i == 1 ? 8 : 0),
                      child: _VipPlanCard(
                        plan: plans[i],
                        selected: selectedPlanId == plans[i].id,
                        isCurrent: currentPlanId == plans[i].id &&
                            !(subscription?.isCancelled ?? true),
                        subscription: subscription,
                        servicesById: servicesById,
                        onTap: enabled ? () => onSelect(plans[i]) : null,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        final cardWidth = wide ? (constraints.maxWidth - 16) / 2 : null;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: plans
              .map(
                (plan) => SizedBox(
                  width: cardWidth ?? constraints.maxWidth,
                  child: _VipPlanCard(
                    plan: plan,
                    selected: selectedPlanId == plan.id,
                    isCurrent: currentPlanId == plan.id &&
                        !(subscription?.isCancelled ?? true),
                    subscription: subscription,
                    servicesById: servicesById,
                    onTap: enabled ? () => onSelect(plan) : null,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _VipPlanCard extends StatelessWidget {
  const _VipPlanCard({
    required this.plan,
    required this.selected,
    required this.isCurrent,
    required this.subscription,
    required this.servicesById,
    required this.onTap,
  });

  final VipPlan plan;
  final bool selected;
  final bool isCurrent;
  final VipSubscription? subscription;
  final Map<String, Service> servicesById;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pastDue = isCurrent &&
        (subscription?.isPastDue == true ||
            subscription?.isPaymentPastDue == true);
    final frequencyLabel = switch (plan.frequency) {
      VipPlanFrequency.monthly => 'mês',
      VipPlanFrequency.quarterly => 'trimestre',
      VipPlanFrequency.yearly => 'ano',
    };
    final coveredServices = plan.serviceIds
        .map((id) => servicesById[id]?.name)
        .whereType<String>()
        .toList(growable: false);
    final limitLabel = plan.monthlyLimit == null
        ? 'Uso ilimitado nos serviços cobertos'
        : '${plan.monthlyLimit} uso(s) por mês';
    final amount = plan.billingAmount
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    final monthly = plan.monthlyAmount
        .toStringAsFixed(2)
        .replaceAll('.', ',');

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AtelierVisuals.selectablePlanCard(
        context,
        selected: selected || isCurrent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (isCurrent)
                _PlanBadge(
                  label: pastDue
                      ? (subscription?.statusLabel ?? 'Em atraso')
                      : 'Seu plano atual',
                  color: pastDue
                      ? (subscription?.statusColor ?? const Color(0xFFFF9800))
                      : null,
                )
              else if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryBright,
                ),
            ],
          ),
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              plan.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'R\$ $amount / $frequencyLabel',
            style: const TextStyle(
              color: AppColors.primaryBright,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (plan.frequency != VipPlanFrequency.monthly)
            Text(
              'Equivale a R\$ $monthly por mês',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 18),
          _Benefit(text: limitLabel),
          ...plan.benefits.map((benefit) => _Benefit(text: benefit)),
          if (coveredServices.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Serviços cobertos',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: coveredServices
                  .map((name) => _ServiceChip(name: name))
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;

    return Semantics(
      selected: selected,
      button: true,
      label: 'Selecionar plano ${plan.name}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}

class _PaymentForm extends StatefulWidget {
  const _PaymentForm({
    required this.cardNumberController,
    required this.cardholderController,
    required this.payerEmailController,
    required this.expiryController,
    required this.cvvController,
    required this.validateExpiry,
  });

  final TextEditingController cardNumberController;
  final TextEditingController cardholderController;
  final TextEditingController payerEmailController;
  final TextEditingController expiryController;
  final TextEditingController cvvController;
  final FormFieldValidator<String> validateExpiry;

  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
  CardBrand _brand = CardBrand.unknown;

  @override
  void initState() {
    super.initState();
    _brand = CardBrandUtils.detect(widget.cardNumberController.text);
    widget.cardNumberController.addListener(_onCardNumberChanged);
  }

  @override
  void dispose() {
    widget.cardNumberController.removeListener(_onCardNumberChanged);
    super.dispose();
  }

  void _onCardNumberChanged() {
    final next = CardBrandUtils.detect(widget.cardNumberController.text);
    if (next != _brand) setState(() => _brand = next);
  }

  @override
  Widget build(BuildContext context) {
    final brandLabel = CardBrandUtils.label(_brand);
    final cardDecoration = customerInputDecoration(
      label: 'Número do cartão',
      hint: '0000 0000 0000 0000',
      icon: CardBrandUtils.icon(_brand),
    ).copyWith(
      suffixText: brandLabel.isEmpty ? null : brandLabel,
      suffixStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );

    return Column(
      children: [
        TextFormField(
          controller: widget.cardNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(19),
          ],
          decoration: cardDecoration,
          validator: (value) {
            final number = value?.replaceAll(' ', '') ?? '';
            if (number.length < 13 || number.length > 19) {
              return 'Informe um número de cartão válido.';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: widget.cardholderController,
          textCapitalization: TextCapitalization.words,
          decoration: customerInputDecoration(
            label: 'Nome do titular',
            icon: Icons.person_outline_rounded,
          ),
          validator: (value) => value == null || value.trim().length < 3
              ? 'Informe o nome do titular.'
              : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: widget.payerEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: customerInputDecoration(
            label: 'E-mail do pagador',
            hint: 'cliente.teste@email.com',
            icon: Icons.alternate_email_rounded,
          ),
          validator: (value) {
            final email = value?.trim() ?? '';
            final accountEmail = Supabase
                .instance
                .client
                .auth
                .currentUser
                ?.email
                ?.trim()
                .toLowerCase();
            if (email.isEmpty || !email.contains('@')) {
              return 'Informe um e-mail válido.';
            }
            if (accountEmail != null && email.toLowerCase() != accountEmail) {
              return 'Use o mesmo e-mail da sua conta.';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'O e-mail deve ser o mesmo usado no login.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.primaryBright),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.expiryController,
                keyboardType: TextInputType.number,
                inputFormatters: [_ExpiryInputFormatter()],
                decoration: customerInputDecoration(
                  label: 'Vencimento',
                  hint: 'MM/AA',
                  icon: Icons.calendar_month_outlined,
                ),
                validator: widget.validateExpiry,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextFormField(
                controller: widget.cvvController,
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: customerInputDecoration(
                  label: 'CVV',
                  hint: '•••',
                  icon: Icons.lock_outline_rounded,
                ),
                validator: (value) {
                  final cvv = value ?? '';
                  return cvv.length < 3 ? 'CVV inválido.' : null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({
    required this.plan,
    required this.isLoading,
    required this.pastDue,
    required this.planChange,
    required this.onPressed,
  });

  final VipPlan? plan;
  final bool isLoading;
  final bool pastDue;
  final bool planChange;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final paymentReady =
        plan != null && plan!.mpPlanId != null && plan!.mpPlanId!.isNotEmpty;
    final label = !paymentReady
        ? 'Plano indisponível'
        : planChange
        ? 'Confirmar troca — ${plan!.name}'
        : pastDue
        ? 'Regularizar pagamento'
        : 'Assinar ${plan!.name}';
    return AtelierGoldButton(
      expand: true,
      weight: AtelierButtonWeight.peak,
      isLoading: isLoading,
      leading: paymentReady
          ? const Icon(Icons.lock_rounded, size: 18, color: AppColors.background)
          : null,
      label: label,
      onPressed: isLoading || !paymentReady ? null : onPressed,
    );
  }
}

class _PlanPickerSheet extends StatelessWidget {
  const _PlanPickerSheet({
    required this.plans,
    required this.currentPlanId,
    required this.subscription,
    required this.servicesById,
  });

  final List<VipPlan> plans;
  final String? currentPlanId;
  final VipSubscription? subscription;
  final Map<String, Service> servicesById;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Planos disponíveis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Escolha um plano para trocar. A cobrança é atualizada no Mercado Pago.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: plans.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    final isCurrent = plan.id == currentPlanId;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _VipPlanCard(
                          plan: plan,
                          selected: isCurrent,
                          isCurrent: isCurrent,
                          subscription: subscription,
                          servicesById: servicesById,
                          onTap: isCurrent
                              ? null
                              : () => Navigator.pop(context, plan),
                        ),
                        if (!isCurrent) ...[
                          const SizedBox(height: 10),
                          AtelierGoldButton(
                            expand: true,
                            label: 'Trocar para ${plan.name}',
                            onPressed: () => Navigator.pop(context, plan),
                          ),
                        ],
                      ],
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

class _PastDueBanner extends StatelessWidget {
  const _PastDueBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1408),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFB74D).withValues(alpha: 0.45),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB74D), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pagamento pendente. Atualize o cartão para reativar o benefício de R\$ 0,00 nos cortes cobertos.',
              style: TextStyle(
                color: Color(0xFFFFB74D),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? AppColors.primaryBright,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: label == 'Seu plano atual' ? 0.2 : 0.7,
        ),
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        name,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 36),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SubscriptionSuccessDialog extends StatelessWidget {
  const _SubscriptionSuccessDialog({required this.planChanged});

  final bool planChanged;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            planChanged ? 'Plano atualizado!' : 'Sucesso!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            planChanged
                ? 'Sua assinatura foi alterada no Mercado Pago. O novo plano já está ativo.'
                : 'Sua assinatura do Clube VIP foi ativada. Prepare-se para viver uma experiência exclusiva.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: AtelierGoldButton(
              expand: true,
              label: 'Continuar',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;
    final formatted = limited.length > 2
        ? '${limited.substring(0, 2)}/${limited.substring(2)}'
        : limited;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
