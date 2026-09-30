import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/barbershop_runtime_config.dart';
import '../core/config/barbershop_resolver.dart';
import '../core/config/oauth_config.dart';
import '../models/barber.dart';
import '../models/barbearia_info.dart';
import '../models/booking.dart';
import '../models/booking_status.dart';
import '../models/service.dart';
import '../models/user.dart';
import '../utils/horarios_mapper.dart';

abstract final class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;
  static String get _barbershopId => BarbershopRuntimeConfig.requireCurrentId();

  static Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: OAuthConfig.redirectUrl,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  static Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: OAuthConfig.redirectUrl,
    );

    final identities = response.user?.identities;
    if (identities == null || identities.isEmpty) {
      throw AuthException(
        'Este e-mail já está cadastrado. Use "Entrar" com sua senha.',
      );
    }

    if (response.session == null) {
      return;
    }
  }

  static Future<String?> fetchCurrentUserRole() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await _client
        .from('users')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    return row?['role']?.toString().trim().toLowerCase();
  }

  static Future<void> ensureUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final barbershopId =
        BarbershopRuntimeConfig.current?.id ??
        await BarbershopResolver.resolveClientIdForInsert();

    final existing = await _client
        .from('users')
        .select('id, role, barbershop_id')
        .eq('id', user.id)
        .maybeSingle();

    if (existing != null) {
      final role = existing['role']?.toString().trim().toLowerCase();
      final existingBarbershopId =
          existing['barbershop_id']?.toString().trim() ?? '';
      // Cliente precisa estar vinculado ao tenant da URL atual para o RPC
      // create_vip_booking aceitar o insert.
      final shouldBindTenant = existingBarbershopId != barbershopId &&
          (role == 'cliente' ||
              role == null ||
              role.isEmpty ||
              existingBarbershopId.isEmpty);
      if (shouldBindTenant) {
        await _client
            .from('users')
            .update({'barbershop_id': barbershopId})
            .eq('id', user.id);
      }
      return;
    }

    final metadata = user.userMetadata ?? {};
    final name =
        metadata['full_name'] ??
        metadata['name'] ??
        user.email?.split('@').first ??
        'Cliente';

    await _client.from('users').insert({
      'id': user.id,
      'nome': name,
      'role': 'cliente',
      'barbershop_id': barbershopId,
    });
  }

  static Future<List<Barber>> fetchBarbers() async {
    const baseColumns = 'id, nome, foto_url, especialidades';

    try {
      final response = await _client
          .from('barbeiros')
          .select('$baseColumns, disponivel')
          .eq('barbershop_id', _barbershopId)
          .order('nome');

      return _mapBarbers(response);
    } catch (_) {
      final response = await _client
          .from('barbeiros')
          .select(baseColumns)
          .eq('barbershop_id', _barbershopId)
          .order('nome');

      return _mapBarbers(response);
    }
  }

  static List<Barber> _mapBarbers(dynamic response) {
    return (response as List<dynamic>)
        .map((row) => Barber.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Service>> fetchServices() async {
    final response = await _client
        .from('servicos')
        .select('id, nome, preco, duracao_minutos, descricao, imagem_url')
        .eq('barbershop_id', _barbershopId)
        .order('nome');

    return _mapServices(response);
  }

  static List<Service> _mapServices(dynamic response) {
    return (response as List<dynamic>)
        .map((row) => Service.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Booking>> fetchUserBookings({
    int limit = 50,
    int lookbackDays = 90,
  }) async {
    final clientId = _client.auth.currentUser?.id;
    if (clientId == null) {
      throw Exception('Usuário não autenticado.');
    }

    final lookbackStart = DateTime.now()
        .subtract(Duration(days: lookbackDays))
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

    try {
      final response = await _client
          .from('agendamentos')
          .select('''
            id,
            barbeiro_id,
            data_inicio,
            status,
            charged_price,
            covered_by_plan,
            barbeiros (nome, foto_url),
            servicos (nome, preco)
          ''')
          .eq('cliente_id', clientId)
          .eq('barbershop_id', _barbershopId)
          .gte('data_inicio', lookbackStart.toUtc().toIso8601String())
          .order('data_inicio', ascending: false)
          .limit(limit);

      return (response as List<dynamic>)
          .map((row) => Booking.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _fetchUserBookingsFlat(
        clientId,
        lookbackStart: lookbackStart,
        limit: limit,
      );
    }
  }

  static Future<List<Booking>> _fetchUserBookingsFlat(
    String clientId, {
    required DateTime lookbackStart,
    required int limit,
  }) async {
    final response = await _client
        .from('agendamentos')
        .select('''
          id,
          barbeiro_id,
          servico_id,
          data_inicio,
          status,
          charged_price,
          covered_by_plan
        ''')
        .eq('cliente_id', clientId)
        .eq('barbershop_id', _barbershopId)
        .gte('data_inicio', lookbackStart.toUtc().toIso8601String())
        .order('data_inicio', ascending: false)
        .limit(limit);

    final rows = response as List<dynamic>;
    if (rows.isEmpty) return [];

    final barberIds = rows
        .map((row) => row['barbeiro_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final serviceIds = rows
        .map((row) => row['servico_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final barbersResponse = await _client
        .from('barbeiros')
        .select('id, nome, foto_url')
        .eq('barbershop_id', _barbershopId)
        .inFilter('id', barberIds);

    final servicesResponse = await _client
        .from('servicos')
        .select('id, nome, preco')
        .eq('barbershop_id', _barbershopId)
        .inFilter('id', serviceIds);

    final barbersById = {
      for (final row in barbersResponse as List<dynamic>)
        row['id']?.toString() ?? '': row as Map<String, dynamic>,
    };
    final servicesById = {
      for (final row in servicesResponse as List<dynamic>)
        row['id']?.toString() ?? '': row as Map<String, dynamic>,
    };

    return rows.map((row) {
      final map = row as Map<String, dynamic>;
      final barber = barbersById[map['barbeiro_id']?.toString() ?? ''];
      final service = servicesById[map['servico_id']?.toString() ?? ''];

      return Booking(
        id: map['id']?.toString() ?? '',
        barberId: map['barbeiro_id']?.toString() ?? '',
        barberName: barber?['nome'] as String? ?? 'Barbeiro',
        barberPhotoUrl: barber?['foto_url'] as String? ?? '',
        serviceName: service?['nome'] as String? ?? 'Serviço',
        dateTime: DateTime.parse(map['data_inicio'] as String).toLocal(),
        status: BookingStatus.fromDb(map['status'] as String? ?? 'pendente'),
        price:
            (map['charged_price'] as num?)?.toDouble() ??
            (service?['preco'] as num?)?.toDouble() ??
            0,
        coveredByPlan: map['covered_by_plan'] as bool? ?? false,
      );
    }).toList();
  }

  static Future<UserProfile> fetchUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    final metadata = user.userMetadata ?? {};
    final fallback = UserProfile(
      id: user.id,
      name:
          metadata['full_name'] ??
          metadata['name'] ??
          user.email?.split('@').first ??
          'Cliente',
      email: user.email ?? '',
      avatarUrl:
          metadata['avatar_url'] as String? ?? metadata['picture'] as String?,
    );

    try {
      final response = await _client
          .from('users')
          .select('id, nome, email, telefone, foto_url')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        return UserProfile.fromJson({
          ...response,
          'email': response['email'] ?? user.email ?? '',
        });
      }
    } catch (_) {
      try {
        final response = await _client
            .from('users')
            .select('id, nome')
            .eq('id', user.id)
            .maybeSingle();

        if (response != null) {
          return UserProfile(
            id: response['id']?.toString() ?? user.id,
            name: response['nome'] as String? ?? fallback.name,
            email: user.email ?? '',
            avatarUrl: fallback.avatarUrl,
          );
        }
      } catch (_) {}
    }

    return fallback;
  }

  static Future<void> updateUserProfile(UserProfile profile) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    try {
      await _client.from('users').upsert({
        'id': user.id,
        'nome': profile.name,
        'telefone': profile.phone,
        'foto_url': profile.avatarUrl,
      });
    } catch (_) {
      await _client
          .from('users')
          .update({'nome': profile.name})
          .eq('id', user.id);
    }
  }

  static Future<Map<String, dynamic>?> fetchBarbeariaHorarios() async {
    try {
      final response = await _client
          .from('barbearia_info')
          .select(
            'id, nome, endereco, telefone, instagram_url, instagram, '
            'foto_url, foto_capa_url, horarios, horarios_funcionamento',
          )
          .eq('barbershop_id', _barbershopId)
          .limit(1);
      final rows = response as List<dynamic>;
      if (rows.isEmpty) {
        debugPrint('[SupabaseService] barbearia_info vazio.');
        return null;
      }

      final data = rows.first as Map<String, dynamic>;
      final map = BarbeariaInfo.extractHorariosMap(data);
      debugPrint(
        '[SupabaseService] Horários carregados: ${map?.keys.toList() ?? 'null'}',
      );
      return map;
    } catch (error) {
      debugPrint('[SupabaseService] Erro ao buscar horários: $error');
      try {
        final response = await _client
            .from('barbearia_info')
            .select('horarios, horarios_funcionamento')
            .eq('barbershop_id', _barbershopId)
            .limit(1);
        final rows = response as List<dynamic>;
        if (rows.isEmpty) return null;
        return BarbeariaInfo.extractHorariosMap(
          rows.first as Map<String, dynamic>,
        );
      } catch (fallbackError) {
        debugPrint(
          '[SupabaseService] Fallback horários falhou: $fallbackError',
        );
        return null;
      }
    }
  }

  static Future<BarbeariaInfo> fetchBarbeariaInfo() async {
    final response = await _client
        .from('barbearia_info')
        .select(
          'id, nome, endereco, telefone, instagram_url, instagram, '
          'foto_url, foto_capa_url, horarios, horarios_funcionamento',
        )
        .eq('barbershop_id', _barbershopId)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return _fallbackBarbeariaInfo();
    }

    return BarbeariaInfo.fromJson(response);
  }

  static BarbeariaInfo _fallbackBarbeariaInfo() {
    return const BarbeariaInfo(
      id: 'fallback',
      name: 'Barbearia',
      address: 'Centro',
      phone: '',
      instagramUrl: '',
      photoUrl: '',
      openingHours: [],
    );
  }

  static Future<Set<String>> fetchOccupiedSlots({
    required String barberId,
    required DateTime day,
  }) async {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final response = await _client
          .from('agendamentos')
          .select('data_inicio, status')
          .eq('barbeiro_id', barberId)
          .eq('barbershop_id', _barbershopId)
          .gte('data_inicio', startOfDay.toUtc().toIso8601String())
          .lt('data_inicio', endOfDay.toUtc().toIso8601String());

      return _mapOccupiedSlots(response);
    } catch (error) {
      debugPrint(
        '[SupabaseService] Query agendamentos com status falhou: $error',
      );
    }

    try {
      final response = await _client
          .from('agendamentos')
          .select('data_inicio')
          .eq('barbeiro_id', barberId)
          .eq('barbershop_id', _barbershopId)
          .gte('data_inicio', startOfDay.toUtc().toIso8601String())
          .lt('data_inicio', endOfDay.toUtc().toIso8601String());

      return _mapOccupiedSlots(response);
    } catch (error) {
      debugPrint('[SupabaseService] Fallback agendamentos falhou: $error');
      return {};
    }
  }

  static Set<String> _mapOccupiedSlots(dynamic response) {
    return (response as List<dynamic>)
        .where((row) {
          final status = (row as Map<String, dynamic>)['status'] as String?;
          if (status == null) return true;
          final lower = status.toLowerCase();
          return lower != 'cancelado' && lower != 'cancelled';
        })
        .map((row) {
          final map = row as Map<String, dynamic>;
          final raw = map['data_inicio'] as String;
          final dateTime = DateTime.parse(raw).toLocal();
          return HorariosMapper.minutesToTime(
            (dateTime.hour * 60) + dateTime.minute,
          );
        })
        .toSet();
  }

  static Future<BookingCreationResult> createBooking({
    required String barberId,
    required String serviceId,
    required DateTime startAt,
    required int durationMinutes,
  }) async {
    if (_client.auth.currentUser?.id == null) {
      throw Exception('Usuário não autenticado.');
    }
    if (barberId.trim().isEmpty || serviceId.trim().isEmpty) {
      throw StateError('Barbeiro ou serviço inválido para agendar.');
    }
    if (durationMinutes <= 0) {
      throw StateError('Duração do serviço inválida.');
    }

    // Garante vínculo do cliente com o tenant antes do RPC validar.
    await ensureUserProfile();

    final endAt = startAt.add(Duration(minutes: durationMinutes));
    final resolvedBarbershopId =
        BarbershopRuntimeConfig.current?.id.trim().isNotEmpty == true
            ? BarbershopRuntimeConfig.current!.id
            : await BarbershopResolver.resolveClientIdForInsert();

    try {
      final response = await _client.rpc(
        'create_vip_booking',
        params: {
          'p_barbershop_id': resolvedBarbershopId,
          'p_barber_id': barberId,
          'p_service_id': serviceId,
          'p_start_at': startAt.toUtc().toIso8601String(),
          'p_end_at': endAt.toUtc().toIso8601String(),
          'p_status': 'confirmado',
        },
      );

      final rows = response is List
          ? response
          : response is Map
              ? [response]
              : const <dynamic>[];
      if (rows.isEmpty) {
        throw StateError('O agendamento não foi criado.');
      }
      final booking = Map<String, dynamic>.from(rows.first as Map);
      return BookingCreationResult(
        coveredByPlan: booking['covered_by_plan'] as bool? ?? false,
        chargedPrice: (booking['charged_price'] as num?)?.toDouble() ?? 0,
      );
    } on PostgrestException catch (error) {
      debugPrint(
        '[SupabaseService] create_vip_booking falhou: '
        '${error.code} ${error.message} ${error.details}',
      );
      rethrow;
    }
  }

  static Future<void> cancelUserBooking(String bookingId) async {
    if (_client.auth.currentUser?.id == null) {
      throw Exception('Usuário não autenticado.');
    }
    await _client.rpc(
      'cancel_user_booking',
      params: {'p_booking_id': bookingId},
    );
  }
}

class BookingCreationResult {
  const BookingCreationResult({
    required this.coveredByPlan,
    required this.chargedPrice,
  });

  final bool coveredByPlan;
  final double chargedPrice;
}
