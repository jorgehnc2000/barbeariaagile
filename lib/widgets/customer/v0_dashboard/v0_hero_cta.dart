import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/barbearia_info.dart';
import '../atelier_shell.dart';
import 'v0_motion.dart';

/// Hero CTA estilo v0 — foto da casa + “Agendar agora” com hover/scale.
class V0HeroCta extends StatefulWidget {
  const V0HeroCta({
    super.key,
    required this.barbearia,
    required this.onAgendar,
    this.tall = false,
    this.maxHeight,
    this.onOpenBarbearia,
  });

  final BarbeariaInfo barbearia;
  final VoidCallback onAgendar;
  final bool tall;
  /// Limita altura no desktop (ex.: vitrine sem scroll excessivo).
  final double? maxHeight;
  final VoidCallback? onOpenBarbearia;

  @override
  State<V0HeroCta> createState() => _V0HeroCtaState();
}

class _V0HeroCtaState extends State<V0HeroCta> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final brand = widget.barbearia.name.trim().isNotEmpty
        ? widget.barbearia.name
        : "Barbearia Moura's";
    final photo = widget.barbearia.photoUrl.trim();
    final viewport = MediaQuery.sizeOf(context).height;
    final height = widget.tall
        ? (widget.maxHeight ?? (viewport * 0.36).clamp(300.0, 380.0))
        : 360.0;
    final reduce = V0Motion.reduced(context);
    final imageScale = reduce ? 1.0 : (_hovered ? 1.05 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedScale(
                scale: imageScale,
                duration: reduce ? Duration.zero : V0Motion.hero,
                curve: V0Motion.easeOut,
                child: photo.isNotEmpty
                    ? Image.network(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const DecoratedBox(
                          decoration:
                              BoxDecoration(gradient: AppColors.heroWarm),
                        ),
                      )
                    : const DecoratedBox(
                        decoration: BoxDecoration(gradient: AppColors.heroWarm),
                      ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.background.withValues(alpha: 0.12),
                      AppColors.background.withValues(alpha: 0.72),
                      AppColors.background.withValues(alpha: 0.96),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.background.withValues(alpha: 0.78),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              IgnorePointer(
                child: AnimatedContainer(
                  duration: reduce ? Duration.zero : V0Motion.fast,
                  curve: V0Motion.easeOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _hovered
                          ? AppColors.primary.withValues(alpha: 0.35)
                          : AppColors.border,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(widget.tall ? 28 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: widget.onOpenBarbearia,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          brand,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: widget.tall ? 18 : 14),
                    Text(
                      'Pronto para elevar seu estilo?',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: widget.tall ? 34 : 28,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: const Text(
                        'Reserve seu horário em segundos e viva a experiência premium que você merece.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                    SizedBox(height: widget.tall ? 20 : 22),
                    V0PressScale(
                      child: AtelierGoldButton(
                        label: 'Agendar agora →',
                        onPressed: widget.onAgendar,
                        height: widget.tall ? 50 : 50,
                        fontSize: 14,
                        weight: AtelierButtonWeight.peak,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
