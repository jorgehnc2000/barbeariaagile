enum VipPlanFrequency {
  monthly('monthly', 1),
  quarterly('quarterly', 3),
  yearly('yearly', 12);

  const VipPlanFrequency(this.databaseValue, this.months);

  final String databaseValue;
  final int months;

  static VipPlanFrequency fromDatabase(String? value) {
    return values.firstWhere(
      (frequency) => frequency.databaseValue == value,
      orElse: () => monthly,
    );
  }
}

/// Integração do plano com Mercado Pago.
enum VipPlanMpStatus {
  pending('pending'),
  synchronized('synchronized');

  const VipPlanMpStatus(this.databaseValue);

  final String databaseValue;

  static VipPlanMpStatus fromDatabase(String? value, {String? mpPlanId}) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized == synchronized.databaseValue) {
      return VipPlanMpStatus.synchronized;
    }
    if (normalized == pending.databaseValue) {
      return VipPlanMpStatus.pending;
    }
    // Fallback legado: presença de mp_plan_id implica sincronizado.
    final hasMpId = (mpPlanId ?? '').trim().isNotEmpty;
    return hasMpId
        ? VipPlanMpStatus.synchronized
        : VipPlanMpStatus.pending;
  }

  bool get isSynchronized => this == VipPlanMpStatus.synchronized;
  bool get isPending => this == VipPlanMpStatus.pending;
}

class VipPlan {
  const VipPlan({
    required this.id,
    required this.barbershopId,
    required this.name,
    required this.monthlyAmount,
    required this.frequency,
    required this.active,
    this.description = '',
    this.benefits = const [],
    this.monthlyLimit,
    this.mpPlanId,
    this.mpStatus = VipPlanMpStatus.pending,
    this.createdAt,
    this.updatedAt,
    this.serviceIds = const [],
  });

  final String id;
  final String barbershopId;
  final String name;
  final String description;
  final List<String> benefits;
  final double monthlyAmount;
  final VipPlanFrequency frequency;
  final int? monthlyLimit;
  final bool active;
  final String? mpPlanId;
  final VipPlanMpStatus mpStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> serviceIds;

  double get billingAmount => monthlyAmount * frequency.months;

  bool get isMpSynchronized => mpStatus.isSynchronized;

  /// Pronto para aparecer no app do cliente.
  bool get isClientReady => active && isMpSynchronized;

  /// Badge principal no admin: Ativo | Pendente | Inativo.
  String get adminStatusLabel {
    if (!active) return 'Inativo';
    if (!isMpSynchronized) return 'Pendente';
    return 'Ativo';
  }

  bool get adminStatusIsActive => adminStatusLabel == 'Ativo';
  bool get adminStatusIsPending => adminStatusLabel == 'Pendente';

  factory VipPlan.fromJson(
    Map<String, dynamic> json, {
    List<String> serviceIds = const [],
  }) {
    final mpPlanId = json['mp_plan_id']?.toString();
    return VipPlan(
      id: json['id']?.toString() ?? '',
      barbershopId: json['barbershop_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      benefits: _stringList(json['benefits']),
      monthlyAmount: (json['monthly_amount'] as num?)?.toDouble() ?? 0,
      frequency: VipPlanFrequency.fromDatabase(json['frequency']?.toString()),
      monthlyLimit: (json['monthly_limit'] as num?)?.toInt(),
      active: json['active'] as bool? ?? false,
      mpPlanId: mpPlanId,
      mpStatus: VipPlanMpStatus.fromDatabase(
        json['mp_status']?.toString(),
        mpPlanId: mpPlanId,
      ),
      createdAt: _dateTime(json['created_at']),
      updatedAt: _dateTime(json['updated_at']),
      serviceIds: List.unmodifiable(serviceIds),
    );
  }

  Map<String, dynamic> toInsertJson(String barbershopId) => {
    'barbershop_id': barbershopId,
    ...toUpdateJson(),
    'mp_status': VipPlanMpStatus.pending.databaseValue,
  };

  Map<String, dynamic> toUpdateJson() => {
    'name': name,
    'description': description,
    'benefits': benefits,
    'monthly_amount': monthlyAmount,
    'frequency': frequency.databaseValue,
    'monthly_limit': monthlyLimit,
    'active': active,
  };

  VipPlan copyWith({
    bool? active,
    String? mpPlanId,
    VipPlanMpStatus? mpStatus,
    List<String>? serviceIds,
  }) {
    return VipPlan(
      id: id,
      barbershopId: barbershopId,
      name: name,
      description: description,
      benefits: benefits,
      monthlyAmount: monthlyAmount,
      frequency: frequency,
      monthlyLimit: monthlyLimit,
      active: active ?? this.active,
      mpPlanId: mpPlanId ?? this.mpPlanId,
      mpStatus: mpStatus ?? this.mpStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
      serviceIds: serviceIds ?? this.serviceIds,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList(growable: false);
  }

  static DateTime? _dateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
