import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'pick_web_image_stub.dart';

export 'pick_web_image_stub.dart' show PickedWebImage, PickWebImageException;

/// Abre o seletor nativo (`<input type="file">`).
///
/// Deve ser chamado de forma **síncrona** a partir de um gesto do usuário
/// (ex.: `onPointerDown`), sem `await`/`setState` antes.
///
/// Retorna `null` só quando o usuário cancela. Falha de leitura lança
/// [PickWebImageException].
Future<PickedWebImage?> pickWebImage() {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/*'
    ..multiple = false;

  input.style
    ..setProperty('position', 'fixed')
    ..setProperty('left', '0')
    ..setProperty('top', '0')
    ..setProperty('width', '1px')
    ..setProperty('height', '1px')
    ..setProperty('opacity', '0')
    ..setProperty('pointer-events', 'none');

  web.document.body?.append(input);

  final completer = Completer<PickedWebImage?>();

  void finishOk(PickedWebImage? value) {
    if (completer.isCompleted) return;
    input.remove();
    completer.complete(value);
  }

  void finishError(String message) {
    if (completer.isCompleted) return;
    input.remove();
    completer.completeError(PickWebImageException(message));
  }

  input.onchange = (web.Event _) {
    final files = input.files;
    if (files == null || files.length == 0) {
      finishOk(null);
      return;
    }

    final file = files.item(0);
    if (file == null) {
      finishOk(null);
      return;
    }

    final reader = web.FileReader();
    reader.onloadend = (web.Event _) {
      try {
        final bytes = _bytesFromReaderResult(reader.result);
        if (bytes == null || bytes.isEmpty) {
          finishError('Não foi possível ler a imagem selecionada.');
          return;
        }
        finishOk(
          PickedWebImage(
            bytes: bytes,
            fileName: file.name,
            mimeType: file.type.isEmpty ? null : file.type,
          ),
        );
      } catch (error) {
        finishError('Não foi possível ler a imagem selecionada.');
      }
    }.toJS;

    reader.onerror = (web.Event _) {
      finishError('Falha ao ler o arquivo selecionado.');
    }.toJS;

    reader.readAsArrayBuffer(file);
  }.toJS;

  input.oncancel = (web.Event _) {
    finishOk(null);
  }.toJS;

  // Clique síncrono — ainda dentro do gesto do usuário.
  input.click();
  return completer.future;
}

/// Converte o resultado do FileReader (JS ArrayBuffer) em [Uint8List].
Uint8List? _bytesFromReaderResult(JSAny? result) {
  if (result == null) return null;

  // Padrão usado pelo file_picker web: JSArrayBuffer → ByteBuffer Dart.
  final jsBuffer = result as JSArrayBuffer?;
  final byteBuffer = jsBuffer?.toDart;
  if (byteBuffer != null) {
    return byteBuffer.asUint8List();
  }

  return null;
}
