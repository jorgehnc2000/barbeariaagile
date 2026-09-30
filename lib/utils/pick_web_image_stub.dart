import 'dart:typed_data';

/// Resultado de uma imagem escolhida no browser.
class PickedWebImage {
  const PickedWebImage({
    required this.bytes,
    required this.fileName,
    this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String? mimeType;
}

/// Erro de leitura do arquivo escolhido (não é cancelamento).
class PickWebImageException implements Exception {
  PickWebImageException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Stub para plataformas sem `dart:html`.
Future<PickedWebImage?> pickWebImage() async {
  throw UnsupportedError('pickWebImage só está disponível na Web.');
}
