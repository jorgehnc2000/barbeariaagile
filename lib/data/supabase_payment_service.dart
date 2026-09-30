import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/barbershop_runtime_config.dart';
import '../core/config/supabase_config.dart';

class SupabasePaymentService {
  SupabasePaymentService({http.Client? client, SupabaseClient? supabaseClient})
    : _client = client ?? http.Client(),
      _supabaseClient = supabaseClient ?? Supabase.instance.client;

  static final _endpoint = Uri.parse(
    '${SupabaseConfig.url}/functions/v1/create-subscription',
  );

  final http.Client _client;
  final SupabaseClient _supabaseClient;

  /// Nova assinatura via Edge Function `create-subscription` (Mercado Pago).
  Future<Map<String, dynamic>> createSubscription({
    required String planId,
    required String cardTokenId,
    String? userId,
    String? barbershopId,
    String? email,
  }) {
    return _invokeCreateSubscription(
      planId: planId,
      cardTokenId: cardTokenId,
      userId: userId,
      barbershopId: barbershopId,
      email: email,
    );
  }

  /// Troca/upgrade de plano: a Edge Function cria novo preapproval no MP,
  /// cancela o anterior e atualiza `subscriptions`.
  Future<Map<String, dynamic>> changePlan({
    required String planId,
    required String cardTokenId,
    String? userId,
    String? barbershopId,
    String? email,
  }) {
    return _invokeCreateSubscription(
      planId: planId,
      cardTokenId: cardTokenId,
      userId: userId,
      barbershopId: barbershopId,
      email: email,
    );
  }

  Future<Map<String, dynamic>> _invokeCreateSubscription({
    required String planId,
    required String cardTokenId,
    String? userId,
    String? barbershopId,
    String? email,
  }) async {
    try {
      final session = _supabaseClient.auth.currentSession;
      if (session == null || session.accessToken.isEmpty) {
        throw const SupabasePaymentException(
          'É necessário estar autenticado para assinar um plano.',
          statusCode: 401,
        );
      }

      final activeBarbershopId = BarbershopRuntimeConfig.requireCurrentId();
      if (barbershopId != null &&
          barbershopId.isNotEmpty &&
          barbershopId != activeBarbershopId) {
        throw const SupabasePaymentException(
          'A barbearia informada não é a barbearia ativa.',
          statusCode: 403,
        );
      }

      final payload = {
        'plan_id': planId,
        'card_token_id': cardTokenId,
        'barbershop_id': activeBarbershopId,
        if (userId != null && userId.isNotEmpty) 'user_id': userId,
        if (email != null && email.isNotEmpty) 'email': email.trim(),
      };

      final response = await _client.post(
        _endpoint,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'apikey': SupabaseConfig.anonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final responseBody = _decodeResponse(response.body);

      if (response.statusCode != 200) {
        final message =
            responseBody['error'] ??
            responseBody['message'] ??
            'Não foi possível criar a assinatura.';
        throw SupabasePaymentException(
          'Erro ao criar assinatura (${response.statusCode}): $message',
          statusCode: response.statusCode,
        );
      }

      return responseBody;
    } on SupabasePaymentException {
      rethrow;
    } on http.ClientException catch (error) {
      throw SupabasePaymentException(
        'Não foi possível conectar à função de pagamento: ${error.message}',
      );
    } on FormatException {
      throw const SupabasePaymentException(
        'A resposta da função de pagamento não é um JSON válido.',
      );
    } catch (error) {
      throw SupabasePaymentException(
        'Erro inesperado ao criar assinatura: $error',
      );
    }
  }

  Map<String, dynamic> _decodeResponse(String body) {
    if (body.trim().isEmpty) return {};

    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('A resposta não é um objeto JSON.');
    }

    return Map<String, dynamic>.from(decoded);
  }
}

class SupabasePaymentException implements Exception {
  const SupabasePaymentException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
