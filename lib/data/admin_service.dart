import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/barbershop_runtime_config.dart';
import '../models/admin_agenda_booking.dart';
import '../models/admin_dashboard.dart';
import '../models/admin_reports.dart';
import '../models/barber.dart';
import '../models/booking_status.dart';
import '../models/vip_plan.dart';

abstract final class AdminService {
  static SupabaseClient get _client => Supabase.instance.client;
  static String get _barbershopId => BarbershopRuntimeConfig.requireCurrentId();

  static const _agendamentoSelectRich = '''
    id,
    status,
    data_inicio,
    data_fim,
    cliente_id,
    barbeiro_id,
    servico_id,
    barbeiros!barbeiro_id (nome, foto_url),
    users!cliente_id (nome, telefone),
    servicos!servico_id (nome, preco, duracao_minutos)
  ''';

  static Future<AdminDashboardData> fetchDashboardMetrics() async {
    final tenantId = _barbershopId;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday % 7));
    // Evita full table scan: métricas usam no máximo 12 meses de histórico.
    final lookbackStart = DateTime(now.year, now.month, 1).subtract(
      const Duration(days: 365),
    );

    List<dynamic> bookingRows;
    try {
      bookingRows =
          await _client
                  .from('agendamentos')
                  .select(_agendamentoSelectRich)
                  .eq('barbershop_id', tenantId)
                  .gte('data_inicio', lookbackStart.toUtc().toIso8601String())
                  .order('data_inicio', ascending: false)
                  .limit(1500)
              as List<dynamic>;
    } catch (_) {
      final response = await _client
          .from('agendamentos')
          .select(
            'id, status, data_inicio, data_fim, cliente_id, barbeiro_id, servico_id',
          )
          .eq('barbershop_id', tenantId)
          .gte('data_inicio', lookbackStart.toUtc().toIso8601String())
          .order('data_inicio', ascending: false)
          .limit(1500);
      bookingRows = response as List<dynamic>;
    }

    final enriched = await _enrichAgendamentoRows(bookingRows, tenantId);

    int activeBarbers = 0;
    try {
      final counted = await _client
          .from('barbeiros')
          .select('id')
          .eq('barbershop_id', tenantId)
          .eq('disponivel', true);
      activeBarbers = (counted as List<dynamic>).length;
    } catch (_) {
      activeBarbers = 0;
    }

    int vipSubscribers = 0;
    try {
      final subs = await _client
          .from('subscriptions')
          .select('id')
          .eq('barbershop_id', tenantId)
          .eq('status', 'authorized');
      vipSubscribers = (subs as List<dynamic>).length;
    } catch (_) {
      vipSubscribers = 0;
    }

    return _buildDashboard(
      enriched,
      monthStart: monthStart,
      weekStart: weekStart,
      activeBarbers: activeBarbers,
      vipSubscribers: vipSubscribers,
    );
  }

  static AdminDashboardData _buildDashboard(
    List<dynamic> rows, {
    required DateTime monthStart,
    required DateTime weekStart,
    required int activeBarbers,
    required int vipSubscribers,
  }) {
    final confirmed = rows.where((row) {
      final status = (row['status'] as String? ?? '').toLowerCase();
      return status == 'confirmado' ||
          status == 'confirmed' ||
          status == 'finalizado' ||
          status == 'concluido' ||
          status == 'concluído';
    });

    var totalRevenue = 0.0;
    var monthRevenue = 0.0;
    final serviceStats = <String, TopServiceEntry>{};
    final barberStats = <String, TopBarberEntry>{};
    final weekly = List<double>.filled(7, 0);
    final today = DateTime.now();
    final todayBookings = <AdminAgendaBooking>[];

    for (final row in rows) {
      final map = row is Map<String, dynamic>
          ? row
          : Map<String, dynamic>.from(row as Map);
      final status = (map['status'] as String? ?? '').toLowerCase();
      final cancelled = status == 'cancelado' || status == 'cancelled';
      final startRaw = map['data_inicio'] as String?;
      final startAt = startRaw == null
          ? null
          : DateTime.tryParse(startRaw)?.toLocal();
      final service = map['servicos'];
      final price = service is Map
          ? (service['preco'] as num?)?.toDouble() ?? 0
          : 0.0;

      if (!cancelled &&
          startAt != null &&
          startAt.year == today.year &&
          startAt.month == today.month &&
          startAt.day == today.day) {
        final barber = _nestedMap(map['barbeiros']);
        final customer = _nestedMap(map['users']);
        final serviceMap = _nestedMap(map['servicos']);
        todayBookings.add(
          AdminAgendaBooking(
            id: map['id']?.toString() ?? '',
            clientName: customer?['nome']?.toString() ?? 'Cliente',
            clientPhotoUrl: customer?['foto_url']?.toString() ?? '',
            clientPhone: customer?['telefone']?.toString() ?? '',
            clientEmail: customer?['email']?.toString() ?? '',
            barberId: map['barbeiro_id']?.toString() ?? '',
            barberName: barber?['nome']?.toString() ?? 'Barbeiro',
            barberPhotoUrl: barber?['foto_url']?.toString() ?? '',
            serviceName: serviceMap?['nome']?.toString() ?? 'Atendimento',
            price: price,
            dateTime: startAt,
            durationMinutes:
                (serviceMap?['duracao_minutos'] as num?)?.toInt() ?? 0,
            status: BookingStatus.fromDb(status),
          ),
        );
      }
    }

    todayBookings.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    for (final row in confirmed) {
      final map = row is Map<String, dynamic>
          ? row
          : Map<String, dynamic>.from(row as Map);
      final service = map['servicos'];
      final name = service is Map
          ? service['nome'] as String? ?? 'Serviço'
          : 'Serviço';
      final price = service is Map
          ? (service['preco'] as num?)?.toDouble() ?? 0
          : 0.0;
      final startRaw = map['data_inicio'] as String?;
      final startAt = startRaw == null
          ? null
          : DateTime.tryParse(startRaw)?.toLocal();
      final barber = _nestedMap(map['barbeiros']);
      final barberKey =
          map['barbeiro_id']?.toString() ??
          barber?['nome']?.toString() ??
          'unknown';
      final barberName = barber?['nome']?.toString() ?? 'Barbeiro';
      final photoUrl = barber?['foto_url']?.toString() ?? '';

      totalRevenue += price;
      if (startAt != null && !startAt.isBefore(monthStart)) {
        monthRevenue += price;
      }
      if (startAt != null && !startAt.isBefore(weekStart)) {
        final index = startAt.difference(weekStart).inDays.clamp(0, 6);
        weekly[index] += price;
      }

      final current = serviceStats[name];
      serviceStats[name] = TopServiceEntry(
        name: name,
        count: (current?.count ?? 0) + 1,
        revenue: (current?.revenue ?? 0) + price,
      );

      final currentBarber = barberStats[barberKey];
      barberStats[barberKey] = TopBarberEntry(
        name: barberName,
        photoUrl: photoUrl,
        attendances: (currentBarber?.attendances ?? 0) + 1,
        revenue: (currentBarber?.revenue ?? 0) + price,
      );
    }

    final totalBookings = confirmed.length;
    final topServices = serviceStats.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    final topBarbers = barberStats.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    const labels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    final weeklyRevenue = [
      for (var i = 0; i < 7; i++)
        WeeklyRevenuePoint(label: labels[i], amount: weekly[i]),
    ];

    return AdminDashboardData(
      totalRevenue: totalRevenue,
      monthRevenue: monthRevenue,
      totalBookings: totalBookings,
      averageTicket: totalBookings == 0 ? 0 : totalRevenue / totalBookings,
      activeBarbers: activeBarbers,
      vipSubscribers: vipSubscribers,
      topServices: topServices,
      topBarbers: topBarbers,
      weeklyRevenue: weeklyRevenue,
      todayBookings: todayBookings,
    );
  }

  static Future<void> createBarber({
    required String name,
    required String photoUrl,
    required String specialty,
    required bool isAvailable,
  }) async {
    await _client.from('barbeiros').insert({
      'barbershop_id': _barbershopId,
      'nome': name,
      'foto_url': photoUrl,
      'especialidades': [specialty],
      'disponivel': isAvailable,
    });
  }

  static Future<void> updateBarber({
    required String id,
    required String name,
    required String photoUrl,
    required String specialty,
    required bool isAvailable,
  }) async {
    await _client
        .from('barbeiros')
        .update({
          'nome': name,
          'foto_url': photoUrl,
          'especialidades': [specialty],
          'disponivel': isAvailable,
        })
        .eq('id', id)
        .eq('barbershop_id', _barbershopId);
  }

  static Future<void> deleteBarber(String id) async {
    await _client
        .from('barbeiros')
        .delete()
        .eq('id', id)
        .eq('barbershop_id', _barbershopId);
  }

  static Future<void> createService({
    required String name,
    required double price,
    required int durationMinutes,
    String? imageUrl,
    String description = '',
  }) async {
    final payload = <String, dynamic>{
      'barbershop_id': _barbershopId,
      'nome': name,
      'preco': price,
      'duracao_minutos': durationMinutes,
      'descricao': description,
    };
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      payload['imagem_url'] = imageUrl.trim();
    }
    await _client.from('servicos').insert(payload);
  }

  static Future<void> updateService({
    required String id,
    required String name,
    required double price,
    required int durationMinutes,
    String? imageUrl,
    String description = '',
  }) async {
    final payload = <String, dynamic>{
      'nome': name,
      'preco': price,
      'duracao_minutos': durationMinutes,
      'descricao': description,
      'imagem_url': imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
    };
    await _client
        .from('servicos')
        .update(payload)
        .eq('id', id)
        .eq('barbershop_id', _barbershopId);
  }

  static Future<void> deleteService(String id) async {
    await _client
        .from('servicos')
        .delete()
        .eq('id', id)
        .eq('barbershop_id', _barbershopId);
  }

  static Future<void> updateBarbeariaInfo({
    required String id,
    required String name,
    required String address,
    required String phone,
    required String instagram,
    required String photoUrl,
    required Map<String, dynamic> openingHours,
  }) async {
    try {
      await _client
          .from('barbearia_info')
          .update({
            'nome': name,
            'endereco': address,
            'telefone': phone,
            'instagram': instagram,
            'foto_url': photoUrl,
            'horarios': openingHours,
            'horarios_funcionamento': openingHours,
          })
          .eq('id', id)
          .eq('barbershop_id', _barbershopId);
    } catch (_) {
      await _client
          .from('barbearia_info')
          .update({
            'nome': name,
            'endereco': address,
            'telefone': phone,
            'instagram': instagram,
            'foto_url': photoUrl,
          })
          .eq('id', id)
          .eq('barbershop_id', _barbershopId);
    }
  }

  static Future<Map<String, dynamic>?> fetchBarbeariaRaw() async {
    return _client
        .from('barbearia_info')
        .select(
          'id, nome, endereco, telefone, instagram_url, instagram, '
          'foto_url, foto_capa_url, horarios, horarios_funcionamento',
        )
        .eq('barbershop_id', _barbershopId)
        .limit(1)
        .maybeSingle();
  }

  static Future<List<AdminAgendaBooking>> fetchAdminAgenda({
    required DateTime day,
  }) async {
    final activeBarbershopId = _barbershopId;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    dynamic response;

    try {
      debugPrint(
        '[AgendaAdmin] Buscando agenda do tenant $activeBarbershopId '
        'em ${start.toIso8601String()}',
      );
      response = await _client
          .from('agendamentos')
          .select(_agendamentoSelectRich)
          .eq('barbershop_id', activeBarbershopId)
          .not('barbershop_id', 'is', null)
          .neq('status', 'cancelado')
          .gte('data_inicio', start.toUtc().toIso8601String())
          .lt('data_inicio', end.toUtc().toIso8601String())
          .order('data_inicio');
    } catch (error, stackTrace) {
      debugPrint('[AgendaAdmin] JOIN enriquecido falhou: $error');
      debugPrintStack(
        label: '[AgendaAdmin] Stack trace',
        stackTrace: stackTrace,
      );

      try {
        response = await _client
            .from('agendamentos')
            .select(
              'id, cliente_id, barbeiro_id, servico_id, data_inicio, data_fim, status',
            )
            .eq('barbershop_id', activeBarbershopId)
            .not('barbershop_id', 'is', null)
            .neq('status', 'cancelado')
            .gte('data_inicio', start.toUtc().toIso8601String())
            .lt('data_inicio', end.toUtc().toIso8601String())
            .order('data_inicio');
        debugPrint(
          '[AgendaAdmin] Agenda carregada pelo JOIN de compatibilidade.',
        );
      } catch (fallbackError, fallbackStackTrace) {
        debugPrint(
          '[AgendaAdmin] Falha definitiva ao buscar agenda: $fallbackError',
        );
        debugPrintStack(
          label: '[AgendaAdmin] Stack trace do fallback',
          stackTrace: fallbackStackTrace,
        );
        rethrow;
      }
    }

    final enriched = await _enrichAgendamentoRows(
      response as List<dynamic>,
      activeBarbershopId,
    );

    return enriched.map((row) {
      final barber = _nestedMap(row['barbeiros']);
      final customer = _nestedMap(row['users']);
      final service = _nestedMap(row['servicos']);
      final startAt = DateTime.parse(row['data_inicio'] as String).toLocal();
      final endAt = row['data_fim'] == null
          ? null
          : DateTime.parse(row['data_fim'] as String).toLocal();
      final serviceDuration = (service?['duracao_minutos'] as num?)?.toInt();
      final calculatedDuration = endAt?.difference(startAt).inMinutes;
      return AdminAgendaBooking(
        id: row['id']?.toString() ?? '',
        clientName: customer?['nome']?.toString() ?? 'Cliente',
        clientPhotoUrl: customer?['foto_url']?.toString() ?? '',
        clientPhone: customer?['telefone']?.toString() ?? '',
        clientEmail: customer?['email']?.toString() ?? '',
        barberId: row['barbeiro_id']?.toString() ?? '',
        barberName: barber?['nome']?.toString() ?? 'Barbeiro',
        barberPhotoUrl: barber?['foto_url']?.toString() ?? '',
        serviceName: service?['nome']?.toString() ?? 'Atendimento',
        price: (service?['preco'] as num?)?.toDouble() ?? 0,
        dateTime: startAt,
        durationMinutes:
            serviceDuration ??
            (calculatedDuration != null && calculatedDuration > 0
                ? calculatedDuration
                : 0),
        status: BookingStatus.fromDb(row['status']?.toString() ?? 'pendente'),
      );
    }).toList();
  }

  static Future<void> updateAdminBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    final activeBarbershopId = _barbershopId;
    try {
      final updated = await _client
          .from('agendamentos')
          .update({'status': status})
          .eq('id', bookingId)
          .eq('barbershop_id', activeBarbershopId)
          .not('barbershop_id', 'is', null)
          .select('id')
          .maybeSingle();

      if (updated == null) {
        throw StateError('Agendamento não encontrado na barbearia ativa.');
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[AgendaAdmin] Falha ao atualizar $bookingId para $status: $error',
      );
      debugPrintStack(
        label: '[AgendaAdmin] Stack trace da atualização',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static Future<List<Barber>> fetchAdminBarbers() async {
    final response = await _client
        .from('barbeiros')
        .select('id, nome, foto_url, especialidades, disponivel')
        .eq('barbershop_id', _barbershopId)
        .order('nome');
    return (response as List<dynamic>)
        .map((row) => Barber.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  static Future<List<AdminAgendaCustomer>> fetchAdminCustomers() async {
    final response = await _client
        .from('users')
        .select('id, nome')
        .eq('barbershop_id', _barbershopId)
        .order('nome');
    return (response as List<dynamic>)
        .map((row) {
          final map = Map<String, dynamic>.from(row as Map);
          return AdminAgendaCustomer(
            id: map['id']?.toString() ?? '',
            name: map['nome']?.toString() ?? 'Cliente',
          );
        })
        .where((customer) => customer.id.isNotEmpty)
        .toList();
  }

  static Future<void> createCounterBooking({
    required String customerId,
    required String barberId,
    required DateTime startAt,
  }) async {
    final activeBarbershopId = _barbershopId;
    final results = await Future.wait([
      _client
          .from('users')
          .select('id')
          .eq('id', customerId)
          .eq('barbershop_id', activeBarbershopId)
          .maybeSingle(),
      _client
          .from('barbeiros')
          .select('id')
          .eq('id', barberId)
          .eq('barbershop_id', activeBarbershopId)
          .maybeSingle(),
    ]);
    if (results[0] == null || results[1] == null) {
      throw StateError('Cliente ou barbeiro não pertence à barbearia ativa.');
    }

    final endAt = startAt.add(const Duration(minutes: 60));
    await _client.from('agendamentos').insert({
      'barbershop_id': activeBarbershopId,
      'cliente_id': customerId,
      'barbeiro_id': barberId,
      'data_inicio': startAt.toUtc().toIso8601String(),
      'data_fim': endAt.toUtc().toIso8601String(),
      'status': 'pendente',
    });
  }

  /// Relatórios e desempenho do mês atual (tenant ativo).
  static Future<AdminReportsData> fetchReportsMetrics() async {
    final tenantId = _barbershopId;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);

    List<dynamic> bookingRows;
    try {
      bookingRows =
          await _client
                  .from('agendamentos')
                  .select('''
            id,
            status,
            data_inicio,
            barbeiro_id,
            barbeiros (id, nome, foto_url),
            servicos (nome, preco)
          ''')
                  .eq('barbershop_id', tenantId)
                  .gte('data_inicio', monthStart.toUtc().toIso8601String())
                  .lt('data_inicio', nextMonth.toUtc().toIso8601String())
              as List<dynamic>;
    } catch (_) {
      final response = await _client
          .from('agendamentos')
          .select('id, status, data_inicio, barbeiro_id, servico_id')
          .eq('barbershop_id', tenantId)
          .gte('data_inicio', monthStart.toUtc().toIso8601String())
          .lt('data_inicio', nextMonth.toUtc().toIso8601String());
      final rows = response as List<dynamic>;
      if (rows.isEmpty) {
        bookingRows = const [];
      } else {
        final serviceIds = rows
            .map((r) => (r as Map)['servico_id']?.toString())
            .whereType<String>()
            .toSet()
            .toList();
        final barberIds = rows
            .map((r) => (r as Map)['barbeiro_id']?.toString())
            .whereType<String>()
            .toSet()
            .toList();
        final servicesResponse = serviceIds.isEmpty
            ? <dynamic>[]
            : await _client
                  .from('servicos')
                  .select('id, nome, preco')
                  .eq('barbershop_id', tenantId)
                  .inFilter('id', serviceIds);
        final barbersResponse = barberIds.isEmpty
            ? <dynamic>[]
            : await _client
                  .from('barbeiros')
                  .select('id, nome, foto_url')
                  .eq('barbershop_id', tenantId)
                  .inFilter('id', barberIds);
        final servicesById = {
          for (final row in servicesResponse)
            (row as Map)['id'].toString(): Map<String, dynamic>.from(row),
        };
        final barbersById = {
          for (final row in barbersResponse)
            (row as Map)['id'].toString(): Map<String, dynamic>.from(row),
        };
        bookingRows = rows.map((row) {
          final map = Map<String, dynamic>.from(row as Map);
          return {
            ...map,
            'servicos': servicesById[map['servico_id']?.toString()],
            'barbeiros': barbersById[map['barbeiro_id']?.toString()],
          };
        }).toList();
      }
    }

    final completed = bookingRows.where(_isCompletedBooking).toList();
    final barberStats = <String, BarberPerformanceRow>{};
    var monthRevenue = 0.0;

    for (final raw in completed) {
      final map = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw as Map);
      final barber = _nestedMap(map['barbeiros']);
      final service = _nestedMap(map['servicos']);
      final barberId =
          map['barbeiro_id']?.toString() ??
          barber?['id']?.toString() ??
          'unknown';
      final barberName = barber?['nome']?.toString() ?? 'Barbeiro';
      final photoUrl = barber?['foto_url']?.toString() ?? '';
      final price = (service?['preco'] as num?)?.toDouble() ?? 0;
      monthRevenue += price;

      final current = barberStats[barberId];
      final attendances = (current?.attendances ?? 0) + 1;
      final revenue = (current?.revenue ?? 0) + price;
      barberStats[barberId] = BarberPerformanceRow(
        barberId: barberId,
        barberName: barberName,
        photoUrl: photoUrl,
        attendances: attendances,
        revenue: revenue,
        averageTicket: revenue / attendances,
      );
    }

    final performance = barberStats.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    // Volume (todos não cancelados do mês) para horários / dias
    final weekdayTotals = List<int>.filled(7, 0);
    final weekdayOccurrences = List<int>.filled(7, 0);
    for (
      var day = monthStart;
      !day.isAfter(DateTime(now.year, now.month, now.day));
      day = day.add(const Duration(days: 1))
    ) {
      weekdayOccurrences[day.weekday % 7] += 1;
    }

    final hourTotals = <int, int>{};
    for (final raw in bookingRows) {
      final map = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw as Map);
      final status = (map['status'] as String? ?? '').toLowerCase();
      if (status == 'cancelado' || status == 'cancelled') continue;
      final startRaw = map['data_inicio'] as String?;
      final startAt = startRaw == null
          ? null
          : DateTime.tryParse(startRaw)?.toLocal();
      if (startAt == null) continue;
      weekdayTotals[startAt.weekday % 7] += 1;
      hourTotals[startAt.hour] = (hourTotals[startAt.hour] ?? 0) + 1;
    }

    const weekdayLabels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    final weekdayAverages = [
      for (var i = 0; i < 7; i++)
        WeekdayVolumePoint(
          label: weekdayLabels[i],
          total: weekdayTotals[i],
          average: weekdayOccurrences[i] == 0
              ? 0
              : weekdayTotals[i] / weekdayOccurrences[i],
        ),
    ];

    final peakHours =
        hourTotals.entries
            .map(
              (e) => PeakHourPoint(
                hourLabel: '${e.key.toString().padLeft(2, '0')}:00',
                count: e.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    // Clube VIP
    var vipActive = 0;
    var vipCancelled = 0;
    var vipMrr = 0.0;
    try {
      final subs = await _client
          .from('subscriptions')
          .select('id, status, plan_id')
          .eq('barbershop_id', tenantId);
      final subscriptionRows = (subs as List<dynamic>)
          .map((raw) => Map<String, dynamic>.from(raw as Map))
          .toList();
      final planIds = subscriptionRows
          .map((row) => row['plan_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
      final plansResponse = planIds.isEmpty
          ? <dynamic>[]
          : await _client
                .from('plans')
                .select(
                  'id, barbershop_id, name, description, benefits, '
                  'monthly_amount, frequency, monthly_limit, active, '
                  'mp_plan_id, mp_status, created_at, updated_at',
                )
                .eq('barbershop_id', tenantId)
                .inFilter('id', planIds);
      final plansById = {
        for (final raw in plansResponse)
          (raw as Map)['id'].toString(): VipPlan.fromJson(
            Map<String, dynamic>.from(raw),
          ),
      };

      for (final row in subscriptionRows) {
        final status = (row['status']?.toString() ?? '').toLowerCase();
        if (status == 'authorized') {
          vipActive += 1;
          final plan = plansById[row['plan_id']?.toString()];
          if (plan != null) {
            vipMrr += plan.monthlyAmount;
          }
        } else if (status == 'cancelled' ||
            status == 'canceled' ||
            status == 'cancelada' ||
            status == 'expired') {
          vipCancelled += 1;
        }
      }
    } catch (_) {
      // VIP opcional — mantém zeros
    }

    final topBarberName = performance.isEmpty
        ? '—'
        : performance.first.barberName;

    return AdminReportsData(
      monthRevenue: monthRevenue,
      monthBookings: completed.length,
      vipMrr: vipMrr,
      vipActive: vipActive,
      vipCancelled: vipCancelled,
      topBarberName: topBarberName,
      barberPerformance: performance,
      weekdayAverages: weekdayAverages,
      peakHours: peakHours.take(5).toList(growable: false),
      hasFinancialData: completed.isNotEmpty || vipActive > 0 || vipMrr > 0,
    );
  }

  static bool _isCompletedBooking(dynamic raw) {
    final map = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw as Map);
    final status = (map['status'] as String? ?? '').toLowerCase();
    return status == 'confirmado' ||
        status == 'confirmed' ||
        status == 'finalizado' ||
        status == 'concluido' ||
        status == 'concluído' ||
        status == 'completed';
  }

  static Map<String, dynamic>? _nestedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static Future<List<Map<String, dynamic>>> _enrichAgendamentoRows(
    List<dynamic> rows,
    String tenantId,
  ) async {
    final list = rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    if (list.isEmpty) return list;

    final barberIds = <String>{};
    final clientIds = <String>{};
    final serviceIds = <String>{};

    for (final map in list) {
      if (_nestedMap(map['barbeiros']) == null) {
        final id = map['barbeiro_id']?.toString();
        if (id != null && id.isNotEmpty) barberIds.add(id);
      }
      if (_nestedMap(map['users']) == null) {
        final id = map['cliente_id']?.toString();
        if (id != null && id.isNotEmpty) clientIds.add(id);
      }
      if (_nestedMap(map['servicos']) == null) {
        final id = map['servico_id']?.toString();
        if (id != null && id.isNotEmpty) serviceIds.add(id);
      }
    }

    if (barberIds.isEmpty && clientIds.isEmpty && serviceIds.isEmpty) {
      return list;
    }

    final results = await Future.wait([
      barberIds.isEmpty
          ? Future<List<dynamic>>.value(const [])
          : _client
                .from('barbeiros')
                .select('id, nome, foto_url')
                .eq('barbershop_id', tenantId)
                .inFilter('id', barberIds.toList()),
      clientIds.isEmpty
          ? Future<List<dynamic>>.value(const [])
          : _fetchUsersByIds(clientIds.toList(), tenantId),
      serviceIds.isEmpty
          ? Future<List<dynamic>>.value(const [])
          : _client
                .from('servicos')
                .select('id, nome, preco, duracao_minutos')
                .eq('barbershop_id', tenantId)
                .inFilter('id', serviceIds.toList()),
    ]);

    final barbersById = {
      for (final row in results[0])
        row['id'].toString(): Map<String, dynamic>.from(row),
    };
    final clientsById = {
      for (final row in results[1])
        row['id'].toString(): Map<String, dynamic>.from(row),
    };
    final servicesById = {
      for (final row in results[2])
        row['id'].toString(): Map<String, dynamic>.from(row),
    };

    for (final map in list) {
      map['barbeiros'] ??= barbersById[map['barbeiro_id']?.toString()];
      map['users'] ??= clientsById[map['cliente_id']?.toString()];
      map['servicos'] ??= servicesById[map['servico_id']?.toString()];
    }

    return list;
  }

  static Future<List<dynamic>> _fetchUsersByIds(
    List<String> ids,
    String tenantId,
  ) async {
    if (ids.isEmpty) return const [];

    try {
      return await _client
          .from('users')
          .select('id, nome, telefone')
          .eq('barbershop_id', tenantId)
          .inFilter('id', ids);
    } catch (_) {
      try {
        return await _client
            .from('users')
            .select('id, nome, telefone')
            .inFilter('id', ids);
      } catch (_) {
        return const [];
      }
    }
  }
}
