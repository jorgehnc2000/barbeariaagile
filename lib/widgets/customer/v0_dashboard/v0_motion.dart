import 'package:flutter/material.dart';

/// Curvas alinhadas ao v0 (`duration-200` / `duration-700` + ease-out).
abstract final class V0Motion {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration hero = Duration(milliseconds: 700);
  static const Curve easeOut = Curves.easeOutCubic;

  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}

/// Superfície com hover de desktop (borda / fundo). Não engole cliques do filho.
class V0HoverShell extends StatefulWidget {
  const V0HoverShell({
    super.key,
    required this.builder,
    this.onTap,
    this.borderRadius = 16,
  });

  final Widget Function(BuildContext context, bool hovered) builder;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  State<V0HoverShell> createState() => _V0HoverShellState();
}

class _V0HoverShellState extends State<V0HoverShell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final child = widget.builder(context, _hovered);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: widget.onTap == null
          ? child
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: child,
              ),
            ),
    );
  }
}

/// Escala visual de press/hover — **não** captura o clique.
/// O filho (botão / InkWell) continua responsável pelo `onPressed`/`onTap`.
class V0PressScale extends StatefulWidget {
  const V0PressScale({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<V0PressScale> createState() => _V0PressScaleState();
}

class _V0PressScaleState extends State<V0PressScale> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final reduce = V0Motion.reduced(context);
    final scale = !widget.enabled || reduce
        ? 1.0
        : _pressed
        ? 0.98
        : _hovered
        ? 1.01
        : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: widget.enabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onPointerUp: widget.enabled
            ? (_) => setState(() => _pressed = false)
            : null,
        onPointerCancel: widget.enabled
            ? (_) => setState(() => _pressed = false)
            : null,
        child: AnimatedScale(
          scale: scale,
          duration: reduce ? Duration.zero : V0Motion.fast,
          curve: V0Motion.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
