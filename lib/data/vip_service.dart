import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/barbershop_runtime_config.dart';
import '../models/vip_mercado_pago_config.dart';
import '../models/vip_plan.dart';
import '../models/vip_plan_service.dart';
import '../models/vip_subscription.dart';

class VipService {
  VipService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _planColumns =
      'id, barbershop_id, name, description, benefits, monthly_amount, '
      'frequency, monthly_limit, active, mp_plan_id, mp_status, created_at, '
      'updated_at';

  static const _subscriptionColumns =
      'id, user_id, barbershop_id, plan_id, mp_preapproval_id, mp_plan_id, '
      'status, next_payment_date, last_payment_status, last_payment_at, '
      'cancelled_at, created_at, updated_at';

  static const _planServiceColumns =
      'plan_id, service_id, barbershop_id, created_at';

  static const _subscriptionWithPlanSelect =
      '$_subscriptionColumns, '
      'plans (id, barbershop_id, name, description, benefits, monthly_amount, '
      'frequency, monthly_limit, active, mp_plan_id, mp_status)';

  String get _barbershopId => BarbershopRuntimeConfig.requireCurrentId();

  /// [activeOnly] filtra `active = true`.
  /// [synchronizedOnly] exige `mp_status = synchronized` (obrigatório no app cliente).
  Future<List<VipPlan>> fetchPlans({
    bool activeOnly = false,
    bool synchronizedOnly = false,
  }) async {
    final tenantId = _barbershopId;
    var query = _client
        .from('plans')
        .select(_planColumns)
        .eq('barbershop_id', tenantId);
    if (activeOnly) query = query.eq('active', true);
    if (synchronizedOnly) {
      query = query.eq('mp_status', VipPlanMpStatus.synchronized.databaseValue);
    }
    final rows = await query.order('created_at');
    final servicesByPlan = await _fetchServiceIdsByPlan(tenantId);

    final plans = (rows as List<dynamic>)
        .map((raw) {
          final row = Map<String, dynamic>.from(raw as Map);
          return VipPlan.fromJson(
            row,
            serviceIds: servicesByPlan[row['id']?.toString()] ?? const [],
          );
        })
        .toList(growable: false);

    // Cinto de segurança: nunca devolver plano sem MP pronto no fluxo cliente.
    if (synchronizedOnly || activeOnly) {
      return plans.where((plan) {
        if (activeOnly && !plan.active) return false;
        if (synchronizedOnly && !plan.isMpSynchronized) return false;
        return true;
      }).toList(growable: false);
    }
    return plans;
  }

  /// Planos visíveis no app do cliente: ativos e sincronizados com o MP.
  Future<List<VipPlan>> fetchClientReadyPlans() {
    return fetchPlans(activeOnly: true, synchronizedOnly: true);
  }

  Future<VipPlan?> fetchPlan(String planId) async {
    final tenantId = _barbershopId;
    final row = await _client
        .from('plans')
        .select(_planColumns)
        .eq('id', planId)
        .eq('barbershop_id', tenantId)
        .maybeSingle();
    if (row == null) return null;

    final services = await fetchPlanServices(planId);
    return VipPlan.fromJson(
      Map<String, dynamic>.from(row),
      serviceIds: services.map((item) => item.serviceId).toList(),
    );
  }

  Future<VipPlan> createPlan(VipPlan plan) async {
    final tenantId = _barbershopId;
    // Novo plano nasce pendente no MP — não pode ficar ativo até sincronizar.
    final payload = plan
        .copyWith(active: false, mpStatus: VipPlanMpStatus.pending)
        .toInsertJson(tenantId);
    final row = await _client
        .from('plans')
        .insert(payload)
        .select()
        .single();
    final created = VipPlan.fromJson(Map<String, dynamic>.from(row));

    try {
      await replacePlanServices(created.id, plan.serviceIds);
    } catch (_) {
      await _client
          .from('plans')
          .delete()
          .eq('id', created.id)
          .eq('barbershop_id', tenantId);
      rethrow;
    }
    return (await fetchPlan(created.id))!;
  }

  Future<VipPlan> updatePlan(VipPlan plan) async {
    final tenantId = _barbershopId;
    if (plan.active && !plan.isMpSynchronized) {
      throw StateError(
        'Sincronize o plano com o Mercado Pago antes de ativá-lo.',
      );
    }
    final updated = await _client
        .from('plans')
        .update(plan.toUpdateJson())
        .eq('id', plan.id)
        .eq('barbershop_id', tenantId)
        .select('id')
        .maybeSingle();
    if (updated == null) {
      throw StateError('Plano não encontrado na barbearia ativa.');
    }

    await replacePlanServices(plan.id, plan.serviceIds);
    return (await fetchPlan(plan.id))!;
  }

  Future<void> deletePlan(String planId) async {
    final tenantId = _barbershopId;
    await _client
        .from('plans')
        .delete()
        .eq('id', planId)
        .eq('barbershop_id', tenantId);
  }

  Future<List<VipPlanService>> fetchPlanServices(String planId) async {
    final rows = await _client
        .from('plan_services')
        .select(_planServiceColumns)
        .eq('plan_id', planId)
        .eq('barbershop_id', _barbershopId)
        .order('created_at');
    return (rows as List<dynamic>)
        .map(
          (raw) =>
              VipPlanService.fromJson(Map<String, dynamic>.from(raw as Map)),
        )
        .toList(growable: false);
  }

  Future<void> replacePlanServices(
    String planId,
    Iterable<String> serviceIds,
  ) async {
    final tenantId = _barbershopId;
    final uniqueIds = serviceIds.where((id) => id.isNotEmpty).toSet().toList();

    final plan = await _client
        .from('plans')
        .select('id')
        .eq('id', planId)
        .eq('barbershop_id', tenantId)
        .maybeSingle();
    if (plan == null) {
      throw StateError('Plano não encontrado na barbearia ativa.');
    }

    if (uniqueIds.isNotEmpty) {
      final services = await _client
          .from('servicos')
          .select('id')
          .eq('barbershop_id', tenantId)
          .inFilter('id', uniqueIds);
      if ((services as List<dynamic>).length != uniqueIds.length) {
        throw StateError('Um ou mais serviços pertencem a outra barbearia.');
      }
    }

    await _client
        .from('plan_services')
        .delete()
        .eq('plan_id', planId)
        .eq('barbershop_id', tenantId);
    if (uniqueIds.isEmpty) return;

    await _client
        .from('plan_services')
        .insert(
          uniqueIds
              .map(
                (serviceId) => {
                  'plan_id': planId,
                  'service_id': serviceId,
                  'barbershop_id': tenantId,
                },
              )
              .toList(),
        );
  }

  Future<List<VipSubscription>> fetchSubscribers() async {
    final tenantId = _barbershopId;
    final rawSubscriptions = await _client
        .from('subscriptions')
        .select(_subscriptionColumns)
        .eq('barbershop_id', tenantId)
        .order('created_at', ascending: false)
        .limit(500);
    final subscriptions = (rawSubscriptions as List<dynamic>)
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
    if (subscriptions.isEmpty) return const [];

    final userIds = subscriptions
        .map((row) => row['user_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final planIds = subscriptions
        .map((row) => row['plan_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final results = await Future.wait([
      _client
          .from('users')
          .select('id, nome, telefone')
          .eq('barbershop_id', tenantId)
          .inFilter('id', userIds),
      planIds.isEmpty
          ? Future.value(<dynamic>[])
          : _client
                .from('plans')
                .select(_planColumns)
                .eq('barbershop_id', tenantId)
                .inFilter('id', planIds),
    ]);

    final usersById = {
      for (final raw in results[0] as List<dynamic>)
        (raw as Map)['id'].toString(): Map<String, dynamic>.from(raw),
    };
    final plansById = {
      for (final raw in results[1] as List<dynamic>)
        (raw as Map)['id'].toString(): VipPlan.fromJson(
          Map<String, dynamic>.from(raw),
        ),
    };

    return subscriptions
        .map(
          (row) => VipSubscription.fromJson(
            row,
            plan: plansById[row['plan_id']?.toString()],
            subscriber: usersById[row['user_id']?.toString()],
          ),
        )
        .toList(growable: false);
  }

  Future<VipSubscription?> fetchCurrentSubscription() async {
    final userId = _requireUserId();
    final tenantId = _barbershopId;

    try {
      final row = await _client
          .from('subscriptions')
          .select(_subscriptionWithPlanSelect)
          .eq('user_id', userId)
          .eq('barbershop_id', tenantId)
          .maybeSingle();
      if (row == null) return null;
      return _subscriptionFromRow(row);
    } catch (_) {
      final row = await _client
          .from('subscriptions')
          .select(_subscriptionColumns)
          .eq('user_id', userId)
          .eq('barbershop_id', tenantId)
          .maybeSingle();
      if (row == null) return null;

      final data = Map<String, dynamic>.from(row);
      final planId = data['plan_id']?.toString();
      return VipSubscription.fromJson(
        data,
        plan: planId == null ? null : await fetchPlan(planId),
      );
    }
  }

  VipSubscription _subscriptionFromRow(Map<String, dynamic> row) {
    final data = Map<String, dynamic>.from(row);
    final planRaw = data.remove('plans');
    VipPlan? plan;
    if (planRaw is Map) {
      plan = VipPlan.fromJson(Map<String, dynamic>.from(planRaw));
    } else if (planRaw is List && planRaw.isNotEmpty && planRaw.first is Map) {
      plan = VipPlan.fromJson(
        Map<String, dynamic>.from(planRaw.first as Map),
      );
    }
    return VipSubscription.fromJson(data, plan: plan);
  }

  Future<void> cancelSubscription(String subscriptionId) async {
    final tenantId = _barbershopId;
    final subscription = await _client
        .from('subscriptions')
        .select('id')
        .eq('id', subscriptionId)
        .eq('barbershop_id', tenantId)
        .maybeSingle();
    if (subscription == null) {
      throw StateError('Assinatura não encontrada na barbearia ativa.');
    }
    await _invokeAuthenticated('cancel-subscription', {
      'subscription_id': subscriptionId,
    });
  }

  /// Consulta `GET /preapproval/{id}` no Mercado Pago e atualiza `subscriptions.status`.
  Future<Map<String, dynamic>> refreshSubscriptionStatus(
    String subscriptionId,
  ) async {
    final tenantId = _barbershopId;
    final subscription = await _client
        .from('subscriptions')
        .select('id')
        .eq('id', subscriptionId)
        .eq('barbershop_id', tenantId)
        .maybeSingle();
    if (subscription == null) {
      throw StateError('Assinatura não encontrada na barbearia ativa.');
    }
    return _invokeAuthenticated('sync-subscription-status', {
      'subscription_id': subscriptionId,
    });
  }

  /// Revalida todas as assinaturas do tenant no Mercado Pago.
  Future<Map<String, dynamic>> refreshAllSubscriptionStatuses() {
    return _invokeAuthenticated('sync-subscription-status', {
      'sync_all': true,
    });
  }

  Future<VipMercadoPagoConfig> fetchMercadoPagoConfig() async {
    final row = await _client
        .from('barbershops')
        .select('mp_public_key, mp_access_token')
        .eq('id', _barbershopId)
        .maybeSingle();
    if (row == null) {
      throw StateError('Barbearia ativa não encontrada.');
    }
    return VipMercadoPagoConfig.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> saveMercadoPagoConfig({
    required String publicKey,
    required String accessToken,
  }) async {
    await _invokeAuthenticated('save-mp-config', {
      'barbershop_id': _barbershopId,
      'mp_public_key': publicKey.trim(),
      'mp_access_token': accessToken.trim(),
    });
  }

  Future<Map<String, dynamic>> syncPlanWithMercadoPago(String planId) async {
    final plan = await fetchPlan(planId);
    if (plan == null) {
      throw StateError('Plano não encontrado na barbearia ativa.');
    }
    return _invokeAuthenticated('create-mp-plan', {'plan_id': planId});
  }

  Future<VipUsage> fetchMonthlyUsage({
    String? subscriptionId,
    DateTime? month,
    VipSubscription? subscription,
  }) async {
    final tenantId = _barbershopId;
    final reference = (month ?? DateTime.now()).toUtc();
    final periodStart = DateTime.utc(reference.year, reference.month);
    final periodEnd = DateTime.utc(reference.year, reference.month + 1);
    final resolvedSubscription =
        subscription ??
        (subscriptionId == null
            ? await fetchCurrentSubscription()
            : await _fetchSubscription(subscriptionId, tenantId));
    if (resolvedSubscription == null) {
      return VipUsage(used: 0, periodStart: periodStart, periodEnd: periodEnd);
    }

    var used = 0;
    try {
      final result = await _client.rpc(
        'count_vip_monthly_usage',
        params: {
          'p_subscription_id': resolvedSubscription.id,
          'p_barbershop_id': tenantId,
          'p_period_start': periodStart.toIso8601String(),
          'p_period_end': periodEnd.toIso8601String(),
        },
      );
      used = (result as num?)?.toInt() ?? 0;
    } catch (_) {
      final rows = await _client
          .from('agendamentos')
          .select('status')
          .eq('barbershop_id', tenantId)
          .eq('subscription_id', resolvedSubscription.id)
          .eq('covered_by_plan', true)
          .gte('data_inicio', periodStart.toIso8601String())
          .lt('data_inicio', periodEnd.toIso8601String());
      used = (rows as List<dynamic>).where((raw) {
        final status = (raw as Map)['status']?.toString().toLowerCase() ?? '';
        return !const {'cancelado', 'canceled', 'cancelled'}.contains(status);
      }).length;
    }

    return VipUsage(
      used: used,
      limit: resolvedSubscription.plan?.monthlyLimit,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }

  Future<VipEligibility> checkEligibility(
    String serviceId, {
    DateTime? month,
    bool revalidateWithMercadoPago = false,
  }) async {
    final vipEnabled = BarbershopRuntimeConfig.current?.vipEnabled ?? false;
    var subscription = await fetchCurrentSubscription();

    if (!vipEnabled && subscription == null) {
      return VipEligibility(
        eligible: false,
        serviceCovered: false,
        subscription: null,
        usage: VipUsage(
          used: 0,
          periodStart: DateTime.utc(
            (month ?? DateTime.now()).year,
            (month ?? DateTime.now()).month,
          ),
          periodEnd: DateTime.utc(
            (month ?? DateTime.now()).year,
            (month ?? DateTime.now()).month + 1,
          ),
        ),
        entitlement: VipEntitlementStatus.inactive,
      );
    }

    if (revalidateWithMercadoPago &&
        subscription != null &&
        (subscription.mpPreapprovalId?.isNotEmpty ?? false) &&
        !subscription.isCancelled) {
      try {
        await _invokeAuthenticated('sync-subscription-status', {
          'subscription_id': subscription.id,
        });
        subscription = await fetchCurrentSubscription();
      } catch (_) {
        // Mantém status local se a consulta ao MP falhar.
      }
    }

    final usage = await fetchMonthlyUsage(
      subscriptionId: subscription?.id,
      month: month,
      subscription: subscription,
    );

    VipEntitlementStatus entitlement = VipEntitlementStatus.inactive;
    if (subscription != null) {
      try {
        entitlement = await getVipEntitlementStatus();
      } catch (_) {
        entitlement = subscription.entitlementStatus;
      }
    }

    if (subscription == null ||
        subscription.plan == null ||
        !subscription.plan!.active) {
      return VipEligibility(
        eligible: false,
        serviceCovered: false,
        subscription: subscription,
        usage: usage,
        entitlement: entitlement,
      );
    }

    final covered = await _client
        .from('plan_services')
        .select('plan_id')
        .eq('plan_id', subscription.plan!.id)
        .eq('service_id', serviceId)
        .eq('barbershop_id', _barbershopId)
        .maybeSingle();
    return VipEligibility(
      eligible: entitlement.isActive && covered != null && usage.hasRemaining,
      serviceCovered: covered != null,
      subscription: subscription,
      usage: usage,
      entitlement: entitlement,
    );
  }

  /// Avalia benefício VIP no servidor (preapproval + último pagamento).
  Future<VipEntitlementStatus> getVipEntitlementStatus({String? userId}) async {
    final uid = userId ?? _requireUserId();
    final result = await _client.rpc(
      'get_vip_entitlement_status',
      params: {'p_user_id': uid, 'p_barbershop_id': _barbershopId},
    );
    return VipEntitlementStatus.fromDb(result?.toString());
  }

  Future<Map<String, List<String>>> _fetchServiceIdsByPlan(
    String tenantId,
  ) async {
    final rows = await _client
        .from('plan_services')
        .select('plan_id, service_id')
        .eq('barbershop_id', tenantId);
    final result = <String, List<String>>{};
    for (final raw in rows as List<dynamic>) {
      final row = raw as Map;
      final planId = row['plan_id']?.toString() ?? '';
      final serviceId = row['service_id']?.toString() ?? '';
      if (planId.isNotEmpty && serviceId.isNotEmpty) {
        result.putIfAbsent(planId, () => []).add(serviceId);
      }
    }
    return result;
  }

  Future<VipSubscription?> _fetchSubscription(
    String subscriptionId,
    String tenantId,
  ) async {
    final row = await _client
        .from('subscriptions')
        .select(_subscriptionColumns)
        .eq('id', subscriptionId)
        .eq('barbershop_id', tenantId)
        .maybeSingle();
    if (row == null) return null;
    final data = Map<String, dynamic>.from(row);
    final planId = data['plan_id']?.toString();
    return VipSubscription.fromJson(
      data,
      plan: planId == null ? null : await fetchPlan(planId),
    );
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('Usuário não autenticado.');
    }
    return userId;
  }

  Future<Map<String, dynamic>> _invokeAuthenticated(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    if (_client.auth.currentSession?.accessToken == null) {
      throw StateError('Sessão autenticada necessária.');
    }
    final response = await _client.functions.invoke(functionName, body: body);
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }
}
