class VipPlanService {
  const VipPlanService({
    required this.planId,
    required this.serviceId,
    required this.barbershopId,
    this.createdAt,
  });

  final String planId;
  final String serviceId;
  final String barbershopId;
  final DateTime? createdAt;

  factory VipPlanService.fromJson(Map<String, dynamic> json) {
    return VipPlanService(
      planId: json['plan_id']?.toString() ?? '',
      serviceId: json['service_id']?.toString() ?? '',
      barbershopId: json['barbershop_id']?.toString() ?? '',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'plan_id': planId,
    'service_id': serviceId,
    'barbershop_id': barbershopId,
  };
}
