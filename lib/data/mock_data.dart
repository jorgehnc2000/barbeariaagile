import '../models/barber.dart';
import '../models/booking.dart';
import '../models/booking_status.dart';
import '../models/service.dart';
import '../models/user.dart';

abstract final class MockData {
  static const currentUser = UserProfile(
    id: 'user-1',
    name: 'Jorge Henrique',
    email: 'jorge@email.com',
    avatarUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop',
  );

  static const barbers = <Barber>[
    Barber(
      id: 'barber-1',
      name: 'Marcos Silva',
      photoUrl:
          'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=400&h=400&fit=crop',
      specialty: 'Fade & Degradê',
      isAvailable: true,
      rating: 4.9,
    ),
    Barber(
      id: 'barber-2',
      name: 'Rafael Costa',
      photoUrl:
          'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400&h=400&fit=crop',
      specialty: 'Barba Premium',
      isAvailable: true,
      rating: 4.8,
    ),
    Barber(
      id: 'barber-3',
      name: 'Diego Alves',
      photoUrl:
          'https://images.unsplash.com/photo-1599351431202-1e0f0137892a?w=400&h=400&fit=crop',
      specialty: 'Corte Clássico',
      isAvailable: false,
      rating: 4.7,
    ),
    Barber(
      id: 'barber-4',
      name: 'Lucas Mendes',
      photoUrl:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop',
      specialty: 'Navalhado',
      isAvailable: true,
      rating: 5.0,
    ),
    Barber(
      id: 'barber-5',
      name: 'Thiago Rocha',
      photoUrl:
          'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400&h=400&fit=crop',
      specialty: 'Design & Pigmento',
      isAvailable: true,
      rating: 4.9,
    ),
  ];

  static const services = <Service>[
    Service(
      id: 'service-1',
      name: 'Corte Premium',
      description: 'Corte personalizado com acabamento na máquina e tesoura.',
      price: 65,
      durationMinutes: 45,
      imageUrl:
          'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=300&h=200&fit=crop',
    ),
    Service(
      id: 'service-2',
      name: 'Barba Completa',
      description: 'Toalha quente, navalha e hidratação pós-barba.',
      price: 45,
      durationMinutes: 30,
      imageUrl:
          'https://images.unsplash.com/photo-1599351431613-4d76d2d321a0?w=300&h=200&fit=crop',
    ),
    Service(
      id: 'service-3',
      name: 'Combo Agile',
      description: 'Corte + barba + sobrancelha. Experiência completa.',
      price: 95,
      durationMinutes: 75,
      imageUrl:
          'https://images.unsplash.com/photo-1585747860715-2ba37c788fab?w=300&h=200&fit=crop',
    ),
    Service(
      id: 'service-4',
      name: 'Pigmentação',
      description: 'Correção e design de barba com pigmento premium.',
      price: 55,
      durationMinutes: 40,
      imageUrl:
          'https://images.unsplash.com/photo-1599351431202-1e0f0137892a?w=300&h=200&fit=crop',
    ),
    Service(
      id: 'service-5',
      name: 'Sobrancelha',
      description: 'Design masculino com acabamento preciso.',
      price: 25,
      durationMinutes: 15,
      imageUrl:
          'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=300&h=200&fit=crop',
    ),
  ];

  static final bookings = <Booking>[
    Booking(
      id: 'booking-1',
      barberId: 'barber-1',
      barberName: 'Marcos Silva',
      barberPhotoUrl:
          'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=400&h=400&fit=crop',
      serviceName: 'Combo Agile',
      dateTime: DateTime.now().add(const Duration(days: 2, hours: 14)),
      status: BookingStatus.confirmed,
      price: 95,
    ),
    Booking(
      id: 'booking-2',
      barberId: 'barber-2',
      barberName: 'Rafael Costa',
      barberPhotoUrl:
          'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400&h=400&fit=crop',
      serviceName: 'Barba Completa',
      dateTime: DateTime.now().subtract(const Duration(days: 5)),
      status: BookingStatus.cancelled,
      price: 45,
    ),
  ];

  /// Horários ocupados simulados por barbeiro (formato HH:mm).
  static const occupiedSlots = <String, List<String>>{
    'barber-1': ['09:00', '10:30', '14:00', '16:30'],
    'barber-2': ['08:30', '11:00', '15:00'],
    'barber-3': ['09:30', '10:00', '11:30', '13:00', '14:30', '16:00'],
    'barber-4': ['10:00', '12:00'],
    'barber-5': ['09:00', '11:30', '14:30', '17:00'],
  };

  /// Próximos [count] dias corridos a partir de hoje (inclui sábado e domingo).
  static List<DateTime> upcomingWeekdays({int count = 7}) {
    final days = <DateTime>[];
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);

    for (var i = 0; i < count; i++) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return days;
  }

  static const allTimeSlots = [
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
  ];
}
