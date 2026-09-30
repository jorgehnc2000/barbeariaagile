import 'booking_status.dart';

class Booking {
  const Booking({
    required this.id,
    required this.barberId,
    required this.barberName,
    required this.barberPhotoUrl,
    required this.serviceName,
    required this.dateTime,
    required this.status,
    required this.price,
    this.coveredByPlan = false,
  });

  final String id;
  final String barberId;
  final String barberName;
  final String barberPhotoUrl;
  final String serviceName;
  final DateTime dateTime;
  final BookingStatus status;
  final double price;
  final bool coveredByPlan;

  factory Booking.fromJson(Map<String, dynamic> json) {
    final barber = _readNestedMap(json['barbeiros']);
    final service = _readNestedMap(json['servicos']);

    return Booking(
      id: json['id']?.toString() ?? '',
      barberId: json['barbeiro_id']?.toString() ?? '',
      barberName: barber?['nome'] as String? ?? 'Barbeiro',
      barberPhotoUrl: barber?['foto_url'] as String? ?? '',
      serviceName: service?['nome'] as String? ?? 'Serviço',
      dateTime: DateTime.parse(json['data_inicio'] as String).toLocal(),
      status: BookingStatus.fromDb(json['status'] as String? ?? 'pendente'),
      price:
          (json['charged_price'] as num?)?.toDouble() ??
          (service?['preco'] as num?)?.toDouble() ??
          0,
      coveredByPlan: json['covered_by_plan'] as bool? ?? false,
    );
  }

  static Map<String, dynamic>? _readNestedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
