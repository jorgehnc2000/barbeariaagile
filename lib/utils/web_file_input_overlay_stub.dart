import 'package:flutter/widgets.dart';

import 'pick_web_image_stub.dart';

export 'pick_web_image_stub.dart' show PickedWebImage;

/// Stub: overlay HTML só existe na Web.
class WebFileInputOverlay extends StatelessWidget {
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
  Widget build(BuildContext context) => const SizedBox.shrink();
}
