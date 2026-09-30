import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/imgbb_config.dart';

/// Erro legível para falhas de upload ImgBB.
class ImgBBException implements Exception {
  ImgBBException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Upload de imagens via proxy autenticado do Supabase.
///
/// A API key do ImgBB fica exclusivamente no secret da Edge Function. O
/// cliente envia apenas os bytes e recebe a URL pública resultante.
abstract final class ImgBBService {
  /// Valida bytes e metadados antes do envio.
  static void validateImage({
    required Uint8List bytes,
    String? fileName,
    String? mimeType,
  }) {
    if (bytes.isEmpty) {
      throw ImgBBException('Selecione uma imagem válida.');
    }
    if (bytes.lengthInBytes > ImgBBConfig.maxBytes) {
      throw ImgBBException(
        'A imagem ultrapassa 5 MB. Escolha um arquivo menor.',
      );
    }
    if (!_hasImageMagicBytes(bytes)) {
      throw ImgBBException('Arquivo inválido. Use JPG, PNG, GIF ou WEBP.');
    }
  }

  /// Valida o tamanho antes de carregar o arquivo inteiro em memória.
  static void validateFileSize(int lengthInBytes) {
    if (lengthInBytes <= 0) {
      throw ImgBBException('Selecione uma imagem válida.');
    }
    if (lengthInBytes > ImgBBConfig.maxBytes) {
      throw ImgBBException(
        'A imagem ultrapassa 5 MB. Escolha um arquivo menor.',
      );
    }
  }

  /// Envia [bytes] para a Edge Function e retorna a URL pública (`data.url`).
  static Future<String?> uploadImageBytes({
    required Uint8List bytes,
    String? fileName,
    String? mimeType,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw ImgBBException(
        'Sua sessão expirou. Entre novamente para enviar uma imagem.',
      );
    }

    validateImage(bytes: bytes, fileName: fileName, mimeType: mimeType);

    try {
      final response = await Supabase.instance.client.functions
          .invoke(
            ImgBBConfig.uploadFunctionName,
            body: {
              'image_base64': base64Encode(bytes),
              'file_name': fileName?.trim(),
              'mime_type': mimeType?.trim(),
            },
          )
          .timeout(const Duration(seconds: 45));

      final data = response.data;
      if (data is Map && data['error'] != null) {
        final serverError = data['error'].toString().trim();
        throw ImgBBException(
          serverError.isEmpty
              ? 'Não foi possível enviar a imagem. Tente novamente.'
              : serverError,
        );
      }
      final url = data is Map ? data['url']?.toString().trim() : null;
      if (url == null || url.isEmpty) {
        throw ImgBBException(
          'Não foi possível obter a URL da imagem. Tente novamente.',
        );
      }
      return url;
    } on ImgBBException {
      rethrow;
    } on FunctionException catch (error) {
      final status = error.status;
      final details = _functionErrorMessage(error);
      if (status == 401 || status == 403) {
        throw ImgBBException(
          details ??
              'Você não tem permissão para enviar imagens neste painel.',
        );
      }
      if (status == 413) {
        throw ImgBBException(
          details ?? 'A imagem ultrapassa 5 MB. Escolha um arquivo menor.',
        );
      }
      throw ImgBBException(
        details ?? 'Não foi possível enviar a imagem. Tente novamente.',
      );
    } catch (error) {
      debugPrint('[ImgBBService] upload failed: $error');
      throw ImgBBException(
        'Falha de rede ao enviar a imagem. Verifique a conexão e tente de novo.',
      );
    }
  }

  static String? _functionErrorMessage(FunctionException error) {
    final details = error.details;
    if (details is Map) {
      final message = details['error'] ?? details['message'];
      final text = message?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    if (details is String) {
      final text = details.trim();
      if (text.isNotEmpty) return text;
    }
    final reason = error.reasonPhrase?.trim();
    if (reason != null && reason.isNotEmpty) return reason;
    return null;
  }

  static bool _hasImageMagicBytes(Uint8List bytes) {
    if (bytes.length < 4) return false;
    // JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    // PNG
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }
    // GIF
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return true;
    // WEBP (RIFF....WEBP)
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }
    // BMP
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) return true;
    return false;
  }
}
