import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'barbershop_runtime_config.dart';

abstract final class BarbershopResolver {
  static SupabaseClient get _client => Supabase.instance.client;
  static DateTime? _lastRefreshAt;
  static const _refreshTtl = Duration(minutes: 5);

  static String? slugFromCurrentUrl() {
    if (!kIsWeb) return BarbershopRuntimeConfig.current?.slug;

    final uri = Uri.base;
    final querySlug = uri.queryParameters['slug']?.trim().toLowerCase();
    if (querySlug != null && querySlug.isNotEmpty) return querySlug;

    final segments = uri.pathSegments
        .map(Uri.decodeComponent)
        .map((segment) => segment.trim().toLowerCase())
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.isEmpty) return null;

    if (segments.first == 'admin') {
      return segments.length > 1 ? segments[1] : null;
    }
    if (segments.first == 'sucesso-assinatura') return null;
    return segments.first;
  }

  static Future<BarbershopRuntimeConfig?> resolveBySlug(String slug) async {
    final normalizedSlug = slug.trim().toLowerCase();
    if (normalizedSlug.isEmpty) return null;

    final row = await _client
        .from('barbershops')
        .select('id, slug, mp_public_key, mp_plan_id, plan_amount, vip_enabled')
        .eq('slug', normalizedSlug)
        .maybeSingle();
    return row == null ? null : _fromRow(row);
  }

  static Future<BarbershopRuntimeConfig?> resolveById(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return null;

    final row = await _client
        .from('barbershops')
        .select('id, slug, mp_public_key, mp_plan_id, plan_amount, vip_enabled')
        .eq('id', normalizedId)
        .maybeSingle();
    return row == null ? null : _fromRow(row);
  }

  static Future<String> resolveClientIdForInsert() async {
    final slug = slugFromCurrentUrl();
    if (slug == null || slug.isEmpty) {
      throw StateError(
        'Não foi possível identificar a barbearia pela URL atual.',
      );
    }
    final config = await resolveBySlug(slug);
    if (config == null) {
      throw StateError('Nenhuma barbearia encontrada para o slug "$slug".');
    }
    BarbershopRuntimeConfig.current = config;
    return config.id;
  }

  static BarbershopRuntimeConfig _fromRow(Map<String, dynamic> row) {
    final id = row['id']?.toString().trim() ?? '';
    final slug = row['slug']?.toString().trim().toLowerCase() ?? '';
    if (id.isEmpty || slug.isEmpty) {
      throw StateError('Barbearia sem id ou slug válido.');
    }
    return BarbershopRuntimeConfig(
      id: id,
      slug: slug,
      mpPublicKey: row['mp_public_key']?.toString().trim() ?? '',
      mpPlanId: row['mp_plan_id']?.toString().trim() ?? '',
      planAmount: (row['plan_amount'] as num?)?.toDouble(),
      vipEnabled: row['vip_enabled'] == true,
    );
  }

  /// Recarrega a config remota (inclui `vip_enabled`) e atualiza o Scope.
  /// Evita bater no banco a cada resume do app — TTL de 5 minutos.
  static Future<BarbershopRuntimeConfig?> refreshCurrent({
    bool force = false,
  }) async {
    final now = DateTime.now();
    if (!force &&
        _lastRefreshAt != null &&
        now.difference(_lastRefreshAt!) < _refreshTtl &&
        BarbershopRuntimeConfig.current != null) {
      return BarbershopRuntimeConfig.current;
    }

    final existing = BarbershopRuntimeConfig.current;
    final slug = existing?.slug ?? slugFromCurrentUrl();
    try {
      final config = (slug != null && slug.isNotEmpty)
          ? await resolveBySlug(slug)
          : (existing?.id.isNotEmpty ?? false)
          ? await resolveById(existing!.id)
          : null;
      if (config != null) {
        BarbershopRuntimeConfig.current = config;
        _lastRefreshAt = now;
      }
      return config;
    } catch (error) {
      debugPrint('[BarbershopResolver] refreshCurrent: $error');
      return BarbershopRuntimeConfig.current;
    }
  }
}
