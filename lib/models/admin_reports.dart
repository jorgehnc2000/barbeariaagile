class AdminReportsData {
  const AdminReportsData({
    required this.monthRevenue,
    required this.monthBookings,
    required this.vipMrr,
    required this.vipActive,
    required this.vipCancelled,
    required this.topBarberName,
    required this.barberPerformance,
    required this.weekdayAverages,
    required this.peakHours,
    required this.hasFinancialData,
  });

  final double monthRevenue;
  final int monthBookings;
  final double vipMrr;
  final int vipActive;
  final int vipCancelled;
  final String topBarberName;
  final List<BarberPerformanceRow> barberPerformance;
  final List<WeekdayVolumePoint> weekdayAverages;
  final List<PeakHourPoint> peakHours;
  final bool hasFinancialData;
}

class BarberPerformanceRow {
  const BarberPerformanceRow({
    required this.barberId,
    required this.barberName,
    required this.photoUrl,
    required this.attendances,
    required this.revenue,
    required this.averageTicket,
  });

  final String barberId;
  final String barberName;
  final String photoUrl;
  final int attendances;
  final double revenue;
  final double averageTicket;
}

class WeekdayVolumePoint {
  const WeekdayVolumePoint({
    required this.label,
    required this.average,
    required this.total,
  });

  final String label;
  final double average;
  final int total;
}

class PeakHourPoint {
  const PeakHourPoint({required this.hourLabel, required this.count});

  final String hourLabel;
  final int count;
}
