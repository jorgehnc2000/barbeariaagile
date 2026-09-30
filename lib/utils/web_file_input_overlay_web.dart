import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

import 'pick_web_image_stub.dart';

export 'pick_web_image_stub.dart' show PickedWebImage;

/// Input de arquivo HTML real cobrindo o tile — o clique do usuário aciona o
/// seletor nativo sem depender de `input.click()` assíncrono (bloqueado no browser).
class WebFileInputOverlay extends StatefulWidget {
  const WebFileInputOverlay({
    super.key,
    required this.onPicked,
    this.onCancel,
    this.enabled = true,
  });

  final ValueChanged<PickedWebImage> onPicked;
  final VoidCallback? onCancel;
  final bool enabled;

  @override
  State<WebFileInputOverlay> createState() => _WebFileInputOverlayState();
}

class _WebFileInputOverlayState extends State<WebFileInputOverlay> {
  static int _seq = 0;

  late final String _viewType;
  html.FileUploadInputElement? _input;

  @override
  void initState() {
    super.initState();
    _viewType = 'barbearia-img-pick-${_seq++}-${identityHashCode(this)}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final input = html.FileUploadInputElement()
        ..accept = 'image/*'
        ..multiple = false
        ..title = 'Selecionar imagem';

      input.style
        ..border = 'none'
        ..margin = '0'
        ..padding = '0'
        ..width = '100%'
        ..height = '100%'
        ..opacity = '0'
        ..cursor = 'pointer'
        ..display = 'block'
        ..position = 'absolute'
        ..left = '0'
        ..top = '0'
        ..zIndex = '10';

      input.onChange.listen((_) => unawaited(_handleChange(input)));
      _input = input;
      _syncEnabled();
      return input;
    });
  }

  @override
  void didUpdateWidget(covariant WebFileInputOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _syncEnabled();
    }
  }

  void _syncEnabled() {
    final input = _input;
    if (input == null) return;
    input.style.pointerEvents = widget.enabled ? 'auto' : 'none';
    input.disabled = !widget.enabled;
  }

  Future<void> _handleChange(html.FileUploadInputElement input) async {
    final files = input.files;
    if (files == null || files.isEmpty) {
      widget.onCancel?.call();
      return;
    }

    final file = files.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoadEnd.first;

    // Permite selecionar o mesmo arquivo de novo.
    input.value = '';

    final data = reader.result;
    if (data is! ByteBuffer) {
      widget.onCancel?.call();
      return;
    }

    final bytes = data.asUint8List();
    if (bytes.isEmpty) {
      widget.onCancel?.call();
      return;
    }

    if (!mounted) return;
    widget.onPicked(
      PickedWebImage(
        bytes: bytes,
        fileName: file.name,
        mimeType: file.type.isEmpty ? null : file.type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
