import 'package:flutter/foundation.dart';

class HorarioIntervalo {
  const HorarioIntervalo({required this.abertura, required this.fechamento});

  final String abertura;
  final String fechamento;
}

class GerarSlotsResult {
  const GerarSlotsResult({
    required this.allSlots,
    required this.isClosed,
    this.closedMessage,
  });

  final List<String> allSlots;
  final bool isClosed;
  final String? closedMessage;
}

abstract final class TimeSlotUtils {
  static const _tag = '[TimeSlotUtils]';
  static const _slotStepMinutes = 30;

  static final _textoHorarioRegex = RegExp(
    r'(\d{1,2})\s*[h:]?\s*(\d{0,2})?\s*(?:às|as|a|-)\s*(\d{1,2})\s*[h:]?\s*(\d{0,2})?',
    caseSensitive: false,
  );

  // ---------------------------------------------------------------------------
  // 1. MAPEAMENTO SEGURO DOS DIAS DA SEMANA
  // ---------------------------------------------------------------------------

  static String obterChaveDia(DateTime data) {
    switch (data.weekday) {
      case DateTime.monday:
        return 'Segunda';
      case DateTime.tuesday:
        return 'Terça';
      case DateTime.wednesday:
        return 'Quarta';
      case DateTime.thursday:
        return 'Quinta';
      case DateTime.friday:
        return 'Sexta';
      case DateTime.saturday:
        return 'Sábado';
      case DateTime.sunday:
        return 'Domingo';
      default:
        return '';
    }
  }

  static List<String> _chavesFallback(DateTime data) {
    switch (data.weekday) {
      case DateTime.monday:
        return ['segunda_feira', 'segunda', 'Segunda-feira'];
      case DateTime.tuesday:
        return ['terca_feira', 'terça_feira', 'terca', 'Terca', 'Terça-feira'];
      case DateTime.wednesday:
        return ['quarta_feira', 'quarta', 'Quarta-feira'];
      case DateTime.thursday:
        return ['quinta_feira', 'quinta', 'Quinta-feira'];
      case DateTime.friday:
        return ['sexta_feira', 'sexta', 'Sexta-feira'];
      case DateTime.saturday:
        return ['sabado', 'Sabado', 'sábado'];
      case DateTime.sunday:
        return ['domingo'];
      default:
        return [];
    }
  }

  // ---------------------------------------------------------------------------
  // EXTRAÇÃO DE HORÁRIOS DO CAMPO "texto"
  // ---------------------------------------------------------------------------

  /// Extrai todos os intervalos de strings como "09h às 12h e 14h às 20h".
  static List<HorarioIntervalo> extrairIntervalosDoTexto(String texto) {
    final limpo = texto.trim();
    if (limpo.isEmpty || limpo.toLowerCase() == 'fechado') return [];

    final intervalos = <HorarioIntervalo>[];
    for (final match in _textoHorarioRegex.allMatches(limpo)) {
      final h1 = int.tryParse(match.group(1) ?? '') ?? 0;
      final m1 = int.tryParse(match.group(2) ?? '') ?? 0;
      final h2 = int.tryParse(match.group(3) ?? '') ?? 0;
      final m2 = int.tryParse(match.group(4) ?? '') ?? 0;
      if (h1 == 0 && h2 == 0) continue;

      intervalos.add(
        HorarioIntervalo(
          abertura: _minutosParaHora((h1 * 60) + m1),
          fechamento: _minutosParaHora((h2 * 60) + m2),
        ),
      );
    }
    return intervalos;
  }

  /// Extrai abertura/fechamento de strings como "09h às 20h" ou "08:30 às 12:00".
  static HorarioIntervalo? extrairHorariosDoTexto(String texto) {
    final intervalos = extrairIntervalosDoTexto(texto);
    if (intervalos.isEmpty) return null;
    if (intervalos.length == 1) return intervalos.first;

    var abertura = intervalos.first.abertura;
    var fechamento = intervalos.last.fechamento;
    for (final intervalo in intervalos) {
      if (_horaParaMinutos(intervalo.abertura) < _horaParaMinutos(abertura)) {
        abertura = intervalo.abertura;
      }
      if (_horaParaMinutos(intervalo.fechamento) > _horaParaMinutos(fechamento)) {
        fechamento = intervalo.fechamento;
      }
    }
    return HorarioIntervalo(abertura: abertura, fechamento: fechamento);
  }

  // ---------------------------------------------------------------------------
  // LEITURA DO MAPA DE HORÁRIOS
  // ---------------------------------------------------------------------------

  static Map<String, dynamic>? _buscarNoDia(
    Map<String, dynamic> horarios,
    DateTime data,
  ) {
    final chavePrincipal = obterChaveDia(data);
    debugPrint(
      '$_tag Buscando dia: $chavePrincipal (${data.toIso8601String()})',
    );
    debugPrint('$_tag Chaves no mapa: ${horarios.keys.toList()}');

    final principal = horarios[chavePrincipal];
    if (principal is Map) {
      debugPrint('$_tag Nó encontrado pela chave principal: "$chavePrincipal"');
      debugPrint('$_tag Conteúdo: $principal');
      return Map<String, dynamic>.from(principal);
    }

    for (final chave in _chavesFallback(data)) {
      final fallback = horarios[chave];
      if (fallback is Map) {
        debugPrint('$_tag Nó encontrado pelo fallback: "$chave"');
        debugPrint('$_tag Conteúdo: $fallback');
        return Map<String, dynamic>.from(fallback);
      }
    }

    final alvo = _normalizarChave(chavePrincipal);
    for (final entry in horarios.entries) {
      if (_normalizarChave(entry.key.toString()) == alvo &&
          entry.value is Map) {
        debugPrint('$_tag Nó encontrado por varredura: "${entry.key}"');
        return Map<String, dynamic>.from(entry.value as Map);
      }
    }

    debugPrint('$_tag FALHA: nó não encontrado para "$chavePrincipal".');
    return null;
  }

  static String _normalizarChave(String key) {
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

  // ---------------------------------------------------------------------------
  // 2. LEITURA SEGURA DOS INTERVALOS
  // ---------------------------------------------------------------------------

  static bool lerAberto(Map<String, dynamic> diaInfo) {
    final aberto = diaInfo['aberto'];

    if (aberto == true) return true;
    if (aberto == false) return false;
    if (aberto is num) return aberto != 0;
    if (aberto is String) {
      final valor = aberto.toLowerCase().trim();
      if (valor == 'true' || valor == '1') return true;
      if (valor == 'false' || valor == '0') return false;
    }

    final texto = diaInfo['texto']?.toString().trim() ?? '';
    if (texto.toLowerCase() == 'fechado') return false;

    final abertura = diaInfo['abertura']?.toString().trim() ?? '';
    final fechamento = diaInfo['fechamento']?.toString().trim() ?? '';
    if (abertura.isNotEmpty && fechamento.isNotEmpty) return true;

    // horarios_funcionamento costuma ter só "texto": "08:30 às 12:00"
    if (texto.isNotEmpty && extrairHorariosDoTexto(texto) != null) return true;

    return false;
  }

  static HorarioIntervalo _resolverIntervalo(Map<String, dynamic> diaInfo) {
    var abertura = diaInfo['abertura']?.toString().trim() ?? '';
    var fechamento = diaInfo['fechamento']?.toString().trim() ?? '';
    final texto = diaInfo['texto']?.toString().trim() ?? '';

    if (abertura.isEmpty || fechamento.isEmpty) {
      final doTexto = extrairHorariosDoTexto(texto);
      if (doTexto != null) {
        if (abertura.isEmpty) abertura = doTexto.abertura;
        if (fechamento.isEmpty) fechamento = doTexto.fechamento;
      }
    }

    if (abertura.isEmpty) abertura = '09:00';
    if (fechamento.isEmpty) fechamento = '19:00';

    return HorarioIntervalo(
      abertura: _normalizarHora(abertura),
      fechamento: _normalizarHora(fechamento),
    );
  }

  static String _normalizarHora(String valor) {
    if (valor.contains('h')) {
      final partes = valor.split('h');
      final hora = partes[0].padLeft(2, '0');
      final minuto = (partes.length > 1 ? partes[1] : '00').padLeft(2, '0');
      return '$hora:$minuto';
    }
    return valor;
  }

  static int _horaParaMinutos(String hora) {
    final normalizada = _normalizarHora(hora);
    final partes = normalizada.split(':');
    if (partes.length < 2) return 0;
    final h = int.tryParse(partes[0]) ?? 0;
    final m = int.tryParse(partes[1]) ?? 0;
    return (h * 60) + m;
  }

  static String _minutosParaHora(int minutos) {
    final hora = minutos ~/ 60;
    final minuto = minutos % 60;
    return '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // 3. GERAÇÃO DE SLOTS (30 em 30 minutos)
  // ---------------------------------------------------------------------------

  static List<String> _gerarSlotsLoop({
    required String abertura,
    required String fechamento,
  }) {
    final minutosAbertura = _horaParaMinutos(abertura);
    final minutosFechamento = _horaParaMinutos(fechamento);

    debugPrint(
      '$_tag Loop: $abertura ($minutosAbertura min) → '
      '$fechamento ($minutosFechamento min), passo $_slotStepMinutes',
    );

    if (minutosFechamento <= minutosAbertura) {
      debugPrint('$_tag FALHA: fechamento <= abertura.');
      return [];
    }

    final slots = <String>[];
    for (
      var min = minutosAbertura;
      min < minutosFechamento;
      min += _slotStepMinutes
    ) {
      slots.add(_minutosParaHora(min));
    }

    debugPrint('$_tag Slots gerados (${slots.length}): $slots');
    return slots;
  }

  static List<String> _gerarSlotsDoDia(
    Map<String, dynamic> diaInfo,
    HorarioIntervalo intervalo,
  ) {
    final texto = diaInfo['texto']?.toString().trim() ?? '';
    final intervalos = extrairIntervalosDoTexto(texto);
    if (intervalos.length > 1) {
      final slots = <String>{};
      for (final bloco in intervalos) {
        slots.addAll(
          _gerarSlotsLoop(
            abertura: bloco.abertura,
            fechamento: bloco.fechamento,
          ),
        );
      }
      final ordered = slots.toList()
        ..sort(
          (a, b) => _horaParaMinutos(a).compareTo(_horaParaMinutos(b)),
        );
      debugPrint('$_tag Slots multi-intervalo (${ordered.length}): $ordered');
      return ordered;
    }

    return _gerarSlotsLoop(
      abertura: intervalo.abertura,
      fechamento: intervalo.fechamento,
    );
  }

  // ---------------------------------------------------------------------------
  // API PÚBLICA
  // ---------------------------------------------------------------------------

  static GerarSlotsResult gerarSlotsDisponiveis({
    required Map<String, dynamic>? horarios,
    required DateTime selectedDay,
    DateTime? now,
  }) {
    debugPrint('$_tag ── Início geração ──');
    debugPrint('$_tag Data: ${selectedDay.toIso8601String()}');

    if (horarios == null || horarios.isEmpty) {
      debugPrint('$_tag FALHA: mapa nulo ou vazio.');
      return const GerarSlotsResult(
        allSlots: [],
        isClosed: true,
        closedMessage: 'A barbearia está fechada neste dia',
      );
    }

    final diaInfo = _buscarNoDia(horarios, selectedDay);
    if (diaInfo == null) {
      return const GerarSlotsResult(
        allSlots: [],
        isClosed: true,
        closedMessage: 'A barbearia está fechada neste dia',
      );
    }

    final estaAberto = lerAberto(diaInfo);
    final intervalo = _resolverIntervalo(diaInfo);

    debugPrint(
      '$_tag aberto=$estaAberto, '
      'abertura=${intervalo.abertura}, fechamento=${intervalo.fechamento}, '
      'texto=${diaInfo['texto']}',
    );

    if (!estaAberto) {
      debugPrint('$_tag Dia fechado.');
      return const GerarSlotsResult(
        allSlots: [],
        isClosed: true,
        closedMessage: 'A barbearia está fechada neste dia',
      );
    }

    final todosSlots = _gerarSlotsDoDia(diaInfo, intervalo);

    if (todosSlots.isEmpty) {
      return const GerarSlotsResult(
        allSlots: [],
        isClosed: true,
        closedMessage: 'A barbearia está fechada neste dia',
      );
    }

    return GerarSlotsResult(allSlots: todosSlots, isClosed: false);
  }

  // ---------------------------------------------------------------------------
  // 4. VALIDAÇÃO DE HOJE (fuso local)
  // ---------------------------------------------------------------------------

  static bool _mesmoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static int _minutosAgora(DateTime agora) {
    return (agora.hour * 60) + agora.minute;
  }

  static bool isSlotAvailableForDay(
    String slot,
    DateTime selectedDay, {
    DateTime? now,
  }) {
    final agora = now ?? DateTime.now();
    final diaSelecionado = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );
    final hoje = DateTime(agora.year, agora.month, agora.day);

    if (!_mesmoDia(diaSelecionado, hoje)) return true;

    return _horaParaMinutos(slot) > _minutosAgora(agora);
  }

  static List<String> filterSlotsForDay({
    required List<String> allSlots,
    required DateTime selectedDay,
    DateTime? now,
  }) {
    return allSlots
        .where((slot) => isSlotAvailableForDay(slot, selectedDay, now: now))
        .toList();
  }

  static Set<String> pastSlotsForDay({
    required List<String> allSlots,
    required DateTime selectedDay,
    DateTime? now,
  }) {
    return allSlots
        .where((slot) => !isSlotAvailableForDay(slot, selectedDay, now: now))
        .toSet();
  }

  static Set<String> unavailableSlots({
    required List<String> allSlots,
    required Set<String> occupiedSlots,
    required DateTime selectedDay,
    DateTime? now,
  }) {
    return {
      ...pastSlotsForDay(
        allSlots: allSlots,
        selectedDay: selectedDay,
        now: now,
      ),
      ...occupiedSlots,
    };
  }

  static int timeToMinutes(String time) => _horaParaMinutos(time);

  static String minutesToTime(int minutes) => _minutosParaHora(minutes);
}
