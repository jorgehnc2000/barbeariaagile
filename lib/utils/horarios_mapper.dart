import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'time_slot_utils.dart';

/// Regra de horário de um dia da semana, tolerante a formatos mistos do JSON.
class DayScheduleRule {
  const DayScheduleRule({
    required this.canonicalKey,
    required this.displayDay,
    required this.isOpen,
    required this.abertura,
    required this.fechamento,
    required this.texto,
  });

  final String canonicalKey;
  final String displayDay;
  final bool isOpen;
  final String abertura;
  final String fechamento;
  final String texto;

  String get displayText {
    if (!isOpen) return 'Fechado';
    if (texto.isNotEmpty && texto.toLowerCase() != 'fechado') return texto;
    if (abertura.isNotEmpty && fechamento.isNotEmpty) {
      return '${HorariosMapper.formatHour(abertura)} às ${HorariosMapper.formatHour(fechamento)}';
    }
    return '';
  }

  Map<String, dynamic> toJson() {
    if (!isOpen) {
      return {
        'aberto': false,
        'texto': 'Fechado',
        'abertura': '',
        'fechamento': '',
      };
    }

    return {
      'aberto': true,
      'texto': displayText,
      'abertura': HorariosMapper.normalizeTime(abertura),
      'fechamento': HorariosMapper.normalizeTime(fechamento),
    };
  }
}

abstract final class HorariosMapper {
  static const _tag = '[HorariosMapper]';
  static const slotStepMinutes = 30;

  static const weekDays = [
    (canonicalKey: 'segunda_feira', displayDay: 'Segunda'),
    (canonicalKey: 'terca_feira', displayDay: 'Terça'),
    (canonicalKey: 'quarta_feira', displayDay: 'Quarta'),
    (canonicalKey: 'quinta_feira', displayDay: 'Quinta'),
    (canonicalKey: 'sexta_feira', displayDay: 'Sexta'),
    (canonicalKey: 'sabado', displayDay: 'Sábado'),
    (canonicalKey: 'domingo', displayDay: 'Domingo'),
  ];

  static const aliasesByWeekday = {
    DateTime.monday: ['segunda_feira', 'segunda', 'Segunda', 'Segunda-feira'],
    DateTime.tuesday: [
      'terca_feira',
      'terça_feira',
      'terca',
      'terça',
      'Terça',
      'Terca',
      'Terça-feira',
    ],
    DateTime.wednesday: ['quarta_feira', 'quarta', 'Quarta', 'Quarta-feira'],
    DateTime.thursday: ['quinta_feira', 'quinta', 'Quinta', 'Quinta-feira'],
    DateTime.friday: ['sexta_feira', 'sexta', 'Sexta', 'Sexta-feira'],
    DateTime.saturday: ['sabado', 'sábado', 'Sabado', 'Sábado'],
    DateTime.sunday: ['domingo', 'Domingo'],
  };

  static dynamic normalizeRaw(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      try {
        return jsonDecode(trimmed);
      } catch (error) {
        debugPrint('$_tag Falha ao decodificar JSON string: $error');
        return null;
      }
    }
    return raw;
  }

  /// Mescla `horarios` (text/json) e `horarios_funcionamento` (jsonb)
  /// normalizando chaves para Segunda…Domingo e preservando o registro mais completo.
  static Map<String, dynamic>? extractHorariosMap(Map<String, dynamic> json) {
    final horariosRaw = normalizeRaw(json['horarios']);
    final funcionamentoRaw = normalizeRaw(json['horarios_funcionamento']);

    debugPrint(
      '$_tag extractHorariosMap: '
      'horarios=${horariosRaw?.runtimeType}, '
      'funcionamento=${funcionamentoRaw?.runtimeType}',
    );

    final merged = <String, Map<String, dynamic>>{};

    void ingestMap(dynamic source, String origem) {
      if (source is! Map) return;
      for (final entry in source.entries) {
        final displayDay = _displayDayFromKey(entry.key.toString());
        if (displayDay == null) {
          debugPrint('$_tag Chave ignorada: "${entry.key}"');
          continue;
        }

        final node = _coerceDayNode(entry.value);
        if (node == null) {
          debugPrint('$_tag Nó inválido para "$displayDay" em $origem');
          continue;
        }

        final existing = merged[displayDay];
        merged[displayDay] = existing == null
            ? node
            : _mergeDayNodes(existing, node, origem);
      }
    }

    // Base: horarios_funcionamento (geralmente só texto nos fins de semana).
    ingestMap(funcionamentoRaw, 'horarios_funcionamento');
    // Sobrescreve/complementa: horarios (tem aberto, abertura, fechamento).
    ingestMap(horariosRaw, 'horarios');

    if (merged.isEmpty) return null;

    debugPrint('$_tag Dias mesclados: ${merged.keys.toList()}');
    return Map<String, dynamic>.from(merged);
  }

  static Map<String, dynamic>? _coerceDayNode(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      final decoded = normalizeRaw(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return null;
  }

  static String? _displayDayFromKey(String rawKey) {
    final weekday = weekdayIndexFromKey(rawKey);
    if (weekday == 0) return null;

    for (final day in weekDays) {
      if (weekdayIndexFromKey(day.canonicalKey) == weekday) {
        return day.displayDay;
      }
    }
    return null;
  }

  static Map<String, dynamic> _mergeDayNodes(
    Map<String, dynamic> base,
    Map<String, dynamic> incoming,
    String origem,
  ) {
    final merged = Map<String, dynamic>.from(base);

    void setIfBetter(String key) {
      final novo = incoming[key];
      if (novo == null) return;

      final atual = merged[key];
      final novoStr = novo.toString().trim();
      final atualStr = atual?.toString().trim() ?? '';

      if (key == 'aberto') {
        final parsed = readBool(novo);
        if (parsed != null) merged[key] = parsed;
        return;
      }

      if (novoStr.isEmpty) return;
      if (atualStr.isEmpty || origem == 'horarios') {
        merged[key] = novo;
      }
    }

    setIfBetter('aberto');
    setIfBetter('abertura');
    setIfBetter('fechamento');
    setIfBetter('texto');

    return merged;
  }

  static String normalizeKey(String key) {
    return key
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('-feira', '_feira')
        .replaceAll(' ', '_')
        .trim();
  }

  static int weekdayIndexFromKey(String key) {
    final normalized = normalizeKey(key);
    if (normalized.contains('seg')) return DateTime.monday;
    if (normalized.contains('ter')) return DateTime.tuesday;
    if (normalized.contains('qua')) return DateTime.wednesday;
    if (normalized.contains('qui')) return DateTime.thursday;
    if (normalized.contains('sex')) return DateTime.friday;
    if (normalized.contains('sab')) return DateTime.saturday;
    if (normalized.contains('dom')) return DateTime.sunday;
    return 0;
  }

  static Map<String, dynamic>? findRawRule(
    Map<String, dynamic>? horarios,
    DateTime date,
  ) {
    if (horarios == null || horarios.isEmpty) return null;

    final chavePrincipal = TimeSlotUtils.obterChaveDia(date);
    final principal = horarios[chavePrincipal];
    if (principal is Map) return Map<String, dynamic>.from(principal);

    for (final alias in aliasesByWeekday[date.weekday] ?? []) {
      final value = horarios[alias];
      if (value is Map) return Map<String, dynamic>.from(value);
    }

    for (final entry in horarios.entries) {
      if (weekdayIndexFromKey(entry.key.toString()) == date.weekday) {
        final value = entry.value;
        if (value is Map) return Map<String, dynamic>.from(value);
      }
    }

    return null;
  }

  static DayScheduleRule parseRule({
    required String canonicalKey,
    required String displayDay,
    required Map<String, dynamic> raw,
  }) {
    final texto = raw['texto']?.toString().trim() ?? '';
    final parsedFromText = TimeSlotUtils.extrairHorariosDoTexto(texto);

    var abertura = raw['abertura']?.toString().trim() ?? '';
    var fechamento = raw['fechamento']?.toString().trim() ?? '';

    if (abertura.isEmpty && parsedFromText != null) {
      abertura = parsedFromText.abertura;
    }
    if (fechamento.isEmpty && parsedFromText != null) {
      fechamento = parsedFromText.fechamento;
    }

    if (abertura.isEmpty) abertura = '09:00';
    if (fechamento.isEmpty) fechamento = '20:00';

    final isOpen = TimeSlotUtils.lerAberto(raw);

    return DayScheduleRule(
      canonicalKey: canonicalKey,
      displayDay: displayDay,
      isOpen: isOpen,
      abertura: normalizeTime(abertura),
      fechamento: normalizeTime(fechamento),
      texto: texto,
    );
  }

  static DayScheduleRule? ruleForDate(
    Map<String, dynamic>? horarios,
    DateTime date,
  ) {
    final raw = findRawRule(horarios, date);
    if (raw == null) return null;

    final weekDay = weekDays.firstWhere(
      (day) => weekdayIndexFromKey(day.canonicalKey) == date.weekday,
      orElse: () => weekDays.first,
    );

    return parseRule(
      canonicalKey: weekDay.canonicalKey,
      displayDay: weekDay.displayDay,
      raw: raw,
    );
  }

  static List<DayScheduleRule> orderedWeekRules(
    Map<String, dynamic>? horarios,
  ) {
    return weekDays.map((day) {
      final weekday = weekdayIndexFromKey(day.canonicalKey);
      final date = DateTime(2024, 1, weekday);
      final raw = findRawRule(horarios, date);

      if (raw == null) {
        return DayScheduleRule(
          canonicalKey: day.canonicalKey,
          displayDay: day.displayDay,
          isOpen: false,
          abertura: '09:00',
          fechamento: '20:00',
          texto: 'Fechado',
        );
      }

      return parseRule(
        canonicalKey: day.canonicalKey,
        displayDay: day.displayDay,
        raw: raw,
      );
    }).toList();
  }

  static Map<String, dynamic> toHorariosJson(List<DayScheduleRule> rules) {
    return {for (final rule in rules) rule.displayDay: rule.toJson()};
  }

  static bool? readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return null;
  }

  static String normalizeTime(String value) {
    final trimmed = value.trim();
    if (trimmed.contains('h')) {
      final parts = trimmed.split('h');
      final hour = parts[0].padLeft(2, '0');
      final minute = (parts.length > 1 ? parts[1] : '00').padLeft(2, '0');
      return '$hour:$minute';
    }
    return trimmed;
  }

  static String formatHour(String value) {
    final normalized = normalizeTime(value);
    final parts = normalized.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}h${parts[1]}';
    }
    return value;
  }

  static int timeToMinutes(String time) {
    final normalized = normalizeTime(time);
    final parts = normalized.split(':');
    if (parts.length < 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String minutesToTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static List<String> generateSlots30Min({
    required String abertura,
    required String fechamento,
  }) {
    final start = timeToMinutes(abertura);
    final end = timeToMinutes(fechamento);
    if (end <= start) return [];

    final slots = <String>[];
    for (var cursor = start; cursor < end; cursor += slotStepMinutes) {
      slots.add(minutesToTime(cursor));
    }
    return slots;
  }
}
