import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/app_colors.dart';
import '../services/imgbb_service.dart';
import '../utils/pick_web_image.dart';

/// Tile reutilizável: preview + pick + upload ImgBB.
///
/// Na Web o seletor abre em [Listener.onPointerDown] (gesto preservado, funciona
/// dentro de modais). Em mobile usa [ImagePicker].
class ImagePickerTile extends StatefulWidget {
  const ImagePickerTile({
    super.key,
    this.imageUrl,
    required this.onImageUploaded,
    this.onError,
    this.label = 'Foto',
    this.hint = 'Toque para enviar uma imagem',
    this.circular = false,
    this.enabled = true,
    this.height = 148,
  });

  final String? imageUrl;
  final ValueChanged<String> onImageUploaded;
  final ValueChanged<String>? onError;
  final String label;
  final String hint;
  final bool circular;
  final bool enabled;
  final double height;

  @override
  State<ImagePickerTile> createState() => _ImagePickerTileState();
}

class _ImagePickerTileState extends State<ImagePickerTile> {
  final _picker = ImagePicker();
  bool _uploading = false;
  bool _webPickOpen = false;
  String? _localPreviewUrl;
  Uint8List? _localBytes;
  String? _inlineError;

  String get _displayUrl {
    final local = _localPreviewUrl?.trim() ?? '';
    if (local.isNotEmpty) return local;
    return widget.imageUrl?.trim() ?? '';
  }

  bool get _canPick => widget.enabled && !_uploading && !_webPickOpen;

  void _onWebPointerDown(PointerDownEvent _) {
    if (!kIsWeb || !_canPick) return;

    // CRÍTICO: iniciar o pick de forma síncrona no pointer down.
    // Qualquer await/setState antes do input.click() faz o browser bloquear.
    late final Future<PickedWebImage?> pickFuture;
    try {
      _webPickOpen = true;
      pickFuture = pickWebImage();
    } catch (error) {
      _webPickOpen = false;
      debugPrint('[ImagePickerTile] web pick start failed: $error');
      _fail('Não foi possível abrir o seletor de imagem.');
      return;
    }

    unawaited(_completeWebPick(pickFuture));
  }

  Future<void> _completeWebPick(Future<PickedWebImage?> pickFuture) async {
    try {
      final picked = await pickFuture;
      if (!mounted) return;
      _webPickOpen = false;
      if (picked == null) return; // usuário cancelou
      await _uploadPicked(
        bytes: picked.bytes,
        fileName: picked.fileName,
        mimeType: picked.mimeType,
      );
    } on PickWebImageException catch (error) {
      _webPickOpen = false;
      debugPrint('[ImagePickerTile] web read failed: $error');
      _fail(error.message);
    } on ImgBBException catch (error) {
      _webPickOpen = false;
      _fail(error.message);
    } catch (error) {
      _webPickOpen = false;
      debugPrint('[ImagePickerTile] web pick failed: $error');
      _fail('Não foi possível enviar a imagem. Tente novamente.');
    }
  }

  Future<void> _uploadPicked({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) async {
    if (!widget.enabled || _uploading) return;

    try {
      ImgBBService.validateFileSize(bytes.lengthInBytes);
      if (!mounted) return;

      setState(() {
        _localBytes = bytes;
        _uploading = true;
        _inlineError = null;
      });

      final url = await ImgBBService.uploadImageBytes(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );

      if (!mounted) return;
      if (url == null || url.isEmpty) {
        _fail('Não foi possível obter a URL da imagem.');
        return;
      }

      setState(() {
        _localPreviewUrl = url;
        _localBytes = null;
        _uploading = false;
      });
      widget.onImageUploaded(url);
    } on ImgBBException catch (error) {
      _fail(error.message);
    } catch (error) {
      debugPrint('[ImagePickerTile] upload failed: $error');
      _fail('Não foi possível enviar a imagem. Tente novamente.');
    }
  }

  Future<void> _pickAndUploadMobile() async {
    if (!_canPick) return;

    setState(() => _inlineError = null);

    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      await _uploadPicked(
        bytes: bytes,
        fileName: file.name,
        mimeType: file.mimeType,
      );
    } on ImgBBException catch (error) {
      _fail(error.message);
    } catch (error) {
      debugPrint('[ImagePickerTile] upload failed: $error');
      _fail('Não foi possível enviar a imagem. Tente novamente.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _uploading = false;
      _webPickOpen = false;
      _localBytes = null;
      _inlineError = message;
    });
    widget.onError?.call(message);
  }

  @override
  Widget build(BuildContext context) {
    final url = _displayUrl;
    final hasRemote = url.isNotEmpty;
    final hasLocal = _localBytes != null && _localBytes!.isNotEmpty;
    final hasImage = hasLocal || hasRemote;
    final radius = widget.circular ? widget.height / 2 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final content = ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasLocal)
                    Image.memory(_localBytes!, fit: BoxFit.cover)
                  else if (hasRemote)
                    Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _Placeholder(
                        hint: widget.hint,
                        circular: widget.circular,
                      ),
                    )
                  else
                    _Placeholder(
                      hint: widget.hint,
                      circular: widget.circular,
                    ),
                  if (_uploading)
                    ColoredBox(
                      color: Colors.black.withValues(alpha: 0.55),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Enviando…',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!_uploading && widget.enabled)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.card.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(
                            hasImage
                                ? Icons.cameraswitch_rounded
                                : Icons.photo_camera_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );

            final decorated = DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: _inlineError != null
                      ? AppColors.error.withValues(alpha: 0.7)
                      : AppColors.border,
                ),
              ),
              child: content,
            );

            final tile = SizedBox(
              width: widget.circular ? widget.height : double.infinity,
              height: widget.height,
              child: kIsWeb
                  ? Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: _onWebPointerDown,
                      child: decorated,
                    )
                  : Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _canPick ? _pickAndUploadMobile : null,
                        borderRadius: BorderRadius.circular(radius),
                        child: decorated,
                      ),
                    ),
            );

            if (widget.circular) {
              return Align(alignment: Alignment.centerLeft, child: tile);
            }
            return tile;
          },
        ),
        if (_inlineError != null) ...[
          const SizedBox(height: 8),
          Text(
            _inlineError!,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.hint, required this.circular});

  final String hint;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.backgroundElevated,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            circular ? Icons.person_rounded : Icons.add_photo_alternate_rounded,
            size: 36,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              hint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
