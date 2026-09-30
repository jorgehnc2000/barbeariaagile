import 'booking_status.dart';

class AdminAgendaBooking {
  const AdminAgendaBooking({
    required this.id,
    required this.clientName,
    required this.clientPhotoUrl,
    required this.clientPhone,
    required this.clientEmail,
    required this.barberId,
    required this.barberName,
    required this.barberPhotoUrl,
    required this.serviceName,
    required this.price,
    required this.dateTime,
    required this.durationMinutes,
    required this.status,
  });

  final String id;
  final String clientName;
  final String clientPhotoUrl;
  final String clientPhone;
  final String clientEmail;
  final String barberId;
  final String barberName;
  final String barberPhotoUrl;
  final String serviceName;
  final double price;
  final DateTime dateTime;
  final int durationMinutes;
  final BookingStatus status;
}

class AdminAgendaCustomer {
  const AdminAgendaCustomer({required this.id, required this.name});

  final String id;
  final String name;
}
