import '../utils/horarios_mapper.dart';
import 'admin_agenda_booking.dart';

class AdminDashboardData {
  const AdminDashboardData({
    required this.totalRevenue,
    required this.monthRevenue,
    required this.totalBookings,
    required this.averageTicket,
    required this.activeBarbers,
    required this.vipSubscribers,
    required this.topServices,
    required this.topBarbers,
    required this.weeklyRevenue,
    required this.todayBookings,
  });

  final double totalRevenue;
  final double monthRevenue;
  final int totalBookings;
  final double averageTicket;
  final int activeBarbers;
  final int vipSubscribers;
  final List<TopServiceEntry> topServices;
  final List<TopBarberEntry> topBarbers;
  final List<WeeklyRevenuePoint> weeklyRevenue;
  final List<AdminAgendaBooking> todayBookings;
}

class TopServiceEntry {
  const TopServiceEntry({
    required this.name,
    required this.count,
    required this.revenue,
  });

  final String name;
  final int count;
  final double revenue;
}

class TopBarberEntry {
  const TopBarberEntry({
    required this.name,
    required this.photoUrl,
    required this.attendances,
    required this.revenue,
  });

  final String name;
  final String photoUrl;
  final int attendances;
  final double revenue;
}

class WeeklyRevenuePoint {
  const WeeklyRevenuePoint({required this.label, required this.amount});

  final String label;
  final double amount;
}

class DayHourInput {
  const DayHourInput({
    required this.day,
    required this.isOpen,
    required this.text,
    required this.abertura,
    required this.fechamento,
  });

  final String day;
  final bool isOpen;
  final String text;
  final String abertura;
  final String fechamento;

  DayHourInput copyWith({
    bool? isOpen,
    String? text,
    String? abertura,
    String? fechamento,
  }) {
    return DayHourInput(
      day: day,
      isOpen: isOpen ?? this.isOpen,
      text: text ?? this.text,
      abertura: abertura ?? this.abertura,
      fechamento: fechamento ?? this.fechamento,
    );
  }

  static List<DayHourInput> fromHorariosMap(Map<String, dynamic>? rawHours) {
    if (rawHours == null || rawHours.isEmpty) {
      return HorariosMapper.weekDays
          .map(
            (day) => DayHourInput(
              day: day.displayDay,
              isOpen: true,
              text: '09h às 20h',
              abertura: '09:00',
              fechamento: '20:00',
            ),
          )
          .toList();
    }

    return HorariosMapper.orderedWeekRules(rawHours)
        .map(
          (rule) => DayHourInput(
            day: rule.displayDay,
            isOpen: rule.isOpen,
            text: rule.texto.isNotEmpty ? rule.texto : rule.displayText,
            abertura: rule.abertura,
            fechamento: rule.fechamento,
          ),
        )
        .toList();
  }

  static String formatHour(String value) => HorariosMapper.formatHour(value);

  static Map<String, dynamic> toHorariosJson(List<DayHourInput> days) {
    final rules = days.map((day) {
      final canonical = HorariosMapper.weekDays
          .firstWhere((w) => w.displayDay == day.day)
          .canonicalKey;

      return DayScheduleRule(
        canonicalKey: canonical,
        displayDay: day.day,
        isOpen: day.isOpen,
        abertura: day.abertura,
        fechamento: day.fechamento,
        texto: day.isOpen ? day.text : 'Fechado',
      );
    }).toList();

    return HorariosMapper.toHorariosJson(rules);
  }
}
