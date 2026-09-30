import '../utils/horarios_mapper.dart';

class OpeningHourEntry {
  const OpeningHourEntry({required this.day, required this.schedule});

  final String day;
  final String schedule;
}

class BarbeariaInfo {
  const BarbeariaInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.instagramUrl,
    required this.photoUrl,
    required this.openingHours,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final String instagramUrl;
  final String photoUrl;
  final List<OpeningHourEntry> openingHours;

  factory BarbeariaInfo.fromJson(Map<String, dynamic> json) {
    final horariosMap = extractHorariosMap(json);

    return BarbeariaInfo(
      id: json['id']?.toString() ?? '',
      name: json['nome'] as String? ?? '',
      address: json['endereco'] as String? ?? '',
      phone: json['telefone'] as String? ?? '',
      instagramUrl: _readInstagram(json),
      photoUrl:
          json['foto_url'] as String? ??
          json['foto_capa_url'] as String? ??
          json['foto_capa'] as String? ??
          '',
      openingHours: _parseOpeningHours(horariosMap),
    );
  }

  static dynamic resolveHorariosRaw(Map<String, dynamic> json) {
    return HorariosMapper.extractHorariosMap(json);
  }

  static Map<String, dynamic>? extractHorariosMap(Map<String, dynamic> json) {
    return HorariosMapper.extractHorariosMap(json);
  }

  static String _readInstagram(Map<String, dynamic> json) {
    return json['instagram_url'] as String? ??
        json['instagram'] as String? ??
        '';
  }

  static List<OpeningHourEntry> _parseOpeningHours(
    Map<String, dynamic>? horariosMap,
  ) {
    if (horariosMap == null || horariosMap.isEmpty) return [];

    return HorariosMapper.orderedWeekRules(horariosMap)
        .map(
          (rule) => OpeningHourEntry(
            day: rule.displayDay,
            schedule: rule.displayText,
          ),
        )
        .where((entry) => entry.schedule.isNotEmpty)
        .toList();
  }
}
