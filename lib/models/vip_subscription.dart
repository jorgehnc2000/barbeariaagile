import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'vip_plan.dart';

/// Status de benefício VIP considerando preapproval + último pagamento.
enum VipEntitlementStatus {
  active,
  pastDue,
  inactive;

  /// Aceita strings do RPC/DB: ACTIVE, PAST_DUE, INACTIVE (e variações).
  static VipEntitlementStatus fromDb(String? raw) {
    final key = (raw ?? '')
        .trim()
        .toUpperCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
    switch (key) {
      case 'ACTIVE':
      case 'ATIVO':
      case 'AUTHORIZED':
        return VipEntitlementStatus.active;
      case 'PAST_DUE':
      case 'EM_ATRASO':
      case 'PAUSED':
      case 'PAUSADO':
        return VipEntitlementStatus.pastDue;
      default:
        return VipEntitlementStatus.inactive;
    }
  }

  bool get isActive => this == VipEntitlementStatus.active;
  bool get isPastDue => this == VipEntitlementStatus.pastDue;
}

/// Helpers de status Mercado Pago / DB ↔ UI / regras de benefício.
///
/// Canonicaliza strings heterogêneas (authorized, ATIVO, em_atraso, Pausado…)
/// para tokens estáveis usados nas checagens.
abstract final class VipSubscriptionStatus {
  static const authorized = 'authorized';
  static const paused = 'paused';
  static const pastDue = 'past_due';
  static const pending = 'pending';
  static const inProcess = 'in_process';
  static const canceled = 'canceled';
  static const expired = 'expired';

  static const pastDuePreapprovalStatuses = {
    pending,
    paused,
    pastDue,
    inProcess,
  };

  static const pastDuePaymentStatuses = {
    'rejected',
    canceled,
    'cancelled',
    inProcess,
  };

  static const cancelledStatuses = {canceled, expired};

  /// Normaliza status de preapproval / assinatura para token canônico.
  static String normalize(String? raw) {
    var status = (raw ?? '').trim().toLowerCase();
    if (status.isEmpty) return pending;
    status = status.replaceAll(' ', '_').replaceAll('-', '_');

    const aliases = <String, String>{
      'authorized': authorized,
      'active': authorized,
      'ativo': authorized,
      'autorizado': authorized,
      'aprovado': authorized,
      'paused': paused,
      'pausado': paused,
      'pausada': paused,
      'past_due': pastDue,
      'pastdue': pastDue,
      'em_atraso': pastDue,
      'atrasado': pastDue,
      'atrasada': pastDue,
      'pending': pending,
      'pendente': pending,
      'in_process': inProcess,
      'inprocess': inProcess,
      'em_processamento': inProcess,
      'processando': inProcess,
      'cancelled': canceled,
      'canceled': canceled,
      'cancelado': canceled,
      'cancelada': canceled,
      'expired': expired,
      'expirado': expired,
      'expirada': expired,
    };

    return aliases[status] ?? status;
  }

  static String normalizePayment(String? raw) {
    final trimmed = (raw ?? '').trim();
    if (trimmed.isEmpty) return '';
    final key = trimmed.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    if (key == 'approved' || key == 'aprovado') return 'approved';
    return normalize(trimmed);
  }

  /// Benefício R$ 0,00: preapproval autorizado + último pagamento aprovado.
  static bool isAuthorized(String? raw) => normalize(raw) == authorized;

  static bool isPaused(String? raw) => normalize(raw) == paused;

  static bool isPaymentPastDue(String? lastPaymentStatus) {
    final payment = normalizePayment(lastPaymentStatus);
    if (payment.isEmpty) return false;
    if (payment == 'approved') return false;
    return pastDuePaymentStatuses.contains(payment) ||
        payment == pastDue ||
        payment == pending ||
        !_nonBlockingPaymentStatuses.contains(payment);
  }

  static const _nonBlockingPaymentStatuses = {'approved', ''};

  static bool isPastDue(String? raw) =>
      pastDuePreapprovalStatuses.contains(normalize(raw));

  static bool isCancelled(String? raw) =>
      cancelledStatuses.contains(normalize(raw));

  static VipEntitlementStatus entitlement({
    required String? preapprovalStatus,
    required String? lastPaymentStatus,
  }) {
    if (isCancelled(preapprovalStatus)) {
      return VipEntitlementStatus.inactive;
    }
    // Pausado / pendente / past_due no preapproval → benefício pausado.
    if (isPastDue(preapprovalStatus)) {
      return VipEntitlementStatus.pastDue;
    }
    if (!isAuthorized(preapprovalStatus)) {
      return VipEntitlementStatus.inactive;
    }
    if (isPaymentPastDue(lastPaymentStatus)) {
      return VipEntitlementStatus.pastDue;
    }
    final payment = normalizePayment(lastPaymentStatus);
    if (payment == 'approved' || payment.isEmpty) {
      return VipEntitlementStatus.active;
    }
    return VipEntitlementStatus.pastDue;
  }

  static String label(
    String? raw, {
    String? lastPaymentStatus,
  }) {
    final status = normalize(raw);
    if (isAuthorized(raw) && isPaymentPastDue(lastPaymentStatus)) {
      return 'Em atraso';
    }
    if (status == authorized) return 'Ativa';
    if (status == paused) return 'Pausada';
    if (status == pastDue || status == pending || status == inProcess) {
      return 'Em atraso';
    }
    if (cancelledStatuses.contains(status)) return 'Cancelada';
    return raw?.trim().isNotEmpty == true ? raw!.trim() : 'Desconhecido';
  }

  static Color color(
    String? raw, {
    String? lastPaymentStatus,
  }) {
    final status = normalize(raw);
    if (isAuthorized(raw) && isPaymentPastDue(lastPaymentStatus)) {
      return const Color(0xFFFF9800);
    }
    if (status == authorized) return AppColors.success;
    if (status == paused) return const Color(0xFFFF9800);
    if (pastDuePreapprovalStatuses.contains(status)) {
      return const Color(0xFFFF9800);
    }
    if (cancelledStatuses.contains(status)) return AppColors.error;
    return AppColors.textSecondary;
  }
}

class VipSubscription {
  const VipSubscription({
    required this.id,
    required this.userId,
    required this.barbershopId,
    required this.status,
    this.planId,
    this.mpPreapprovalId,
    this.mpPlanId,
    this.nextPaymentDate,
    this.lastPaymentStatus,
    this.lastPaymentAt,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
    this.plan,
    this.subscriberName = '',
    this.subscriberEmail = '',
    this.subscriberPhone,
    this.subscriberAvatarUrl,
  });

  final String id;
  final String userId;
  final String barbershopId;
  final String? planId;
  final String? mpPreapprovalId;
  final String? mpPlanId;
  final String status;
  final DateTime? nextPaymentDate;
  final String? lastPaymentStatus;
  final DateTime? lastPaymentAt;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final VipPlan? plan;
  final String subscriberName;
  final String subscriberEmail;
  final String? subscriberPhone;
  final String? subscriberAvatarUrl;

  String get normalizedStatus => VipSubscriptionStatus.normalize(status);

  /// Libera benefício VIP (R$ 0,00) — preapproval + pagamento aprovado.
  bool get isAuthorized => entitlementStatus.isActive;

  /// Alias de [isAuthorized] para checagens de benefício.
  bool get isActive => isAuthorized;

  /// Preapproval autorizado, mas último pagamento pendente/recusado.
  bool get isPaymentPastDue =>
      VipSubscriptionStatus.isPaymentPastDue(lastPaymentStatus);

  bool get isPaused => VipSubscriptionStatus.isPaused(status);

  /// Em atraso (pagamento ou preapproval) ou pausada.
  bool get isPastDue =>
      entitlementStatus.isPastDue ||
      VipSubscriptionStatus.isPastDue(status);

  bool get isCancelled => VipSubscriptionStatus.isCancelled(status);

  /// Assinatura vigente para UI (ativa, atraso ou pausada — não cancelada).
  bool get hasMembership => !isCancelled;

  VipEntitlementStatus get entitlementStatus =>
      VipSubscriptionStatus.entitlement(
        preapprovalStatus: status,
        lastPaymentStatus: lastPaymentStatus,
      );

  bool get canCancel => !isCancelled;

  String get statusLabel => VipSubscriptionStatus.label(
    status,
    lastPaymentStatus: lastPaymentStatus,
  );

  Color get statusColor => VipSubscriptionStatus.color(
    status,
    lastPaymentStatus: lastPaymentStatus,
  );

  factory VipSubscription.fromJson(
    Map<String, dynamic> json, {
    VipPlan? plan,
    Map<String, dynamic>? subscriber,
  }) {
    return VipSubscription(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      barbershopId: json['barbershop_id']?.toString() ?? '',
      planId: json['plan_id']?.toString(),
      mpPreapprovalId: json['mp_preapproval_id']?.toString(),
      mpPlanId: json['mp_plan_id']?.toString(),
      status: VipSubscriptionStatus.normalize(json['status']?.toString()),
      nextPaymentDate: _dateTime(json['next_payment_date']),
      lastPaymentStatus: json['last_payment_status']?.toString(),
      lastPaymentAt: _dateTime(json['last_payment_at']),
      cancelledAt: _dateTime(json['cancelled_at']),
      createdAt: _dateTime(json['created_at']),
      updatedAt: _dateTime(json['updated_at']),
      plan: plan,
      subscriberName: subscriber?['nome']?.toString() ?? '',
      subscriberEmail: subscriber?['email']?.toString() ?? '',
      subscriberPhone:
          subscriber?['telefone']?.toString() ??
          subscriber?['whatsapp']?.toString(),
      subscriberAvatarUrl:
          subscriber?['foto_url']?.toString() ??
          subscriber?['avatar_url']?.toString(),
    );
  }

  VipSubscription copyWith({
    String? status,
    String? lastPaymentStatus,
    VipPlan? plan,
  }) {
    return VipSubscription(
      id: id,
      userId: userId,
      barbershopId: barbershopId,
      status: status ?? this.status,
      planId: planId,
      mpPreapprovalId: mpPreapprovalId,
      mpPlanId: mpPlanId,
      nextPaymentDate: nextPaymentDate,
      lastPaymentStatus: lastPaymentStatus ?? this.lastPaymentStatus,
      lastPaymentAt: lastPaymentAt,
      cancelledAt: cancelledAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      plan: plan ?? this.plan,
      subscriberName: subscriberName,
      subscriberEmail: subscriberEmail,
      subscriberPhone: subscriberPhone,
      subscriberAvatarUrl: subscriberAvatarUrl,
    );
  }

  static DateTime? _dateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class VipUsage {
  const VipUsage({
    required this.used,
    required this.periodStart,
    required this.periodEnd,
    this.limit,
  });

  final int used;
  final int? limit;
  final DateTime periodStart;
  final DateTime periodEnd;

  int? get remaining =>
      limit == null ? null : (limit! - used).clamp(0, limit!).toInt();
  bool get hasRemaining => limit == null || used < limit!;
}

class VipEligibility {
  const VipEligibility({
    required this.eligible,
    required this.serviceCovered,
    required this.usage,
    required this.entitlement,
    this.subscription,
  });

  final bool eligible;
  final bool serviceCovered;
  final VipSubscription? subscription;
  final VipUsage usage;
  final VipEntitlementStatus entitlement;

  bool get isPastDue => entitlement.isPastDue;
  bool get isActive => entitlement.isActive;
}
