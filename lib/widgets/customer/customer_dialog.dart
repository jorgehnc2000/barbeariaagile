import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'atelier_shell.dart';

/// Diálogo padrão do cliente — Midnight Atelier.
Future<bool?> showCustomerDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelLabel = 'Cancelar',
  String? confirmLabel,
  bool barrierDismissible = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          color: AppColors.textSecondary,
          height: 1.45,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            cancelLabel,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        if (confirmLabel != null)
          AtelierGoldButton(
            label: confirmLabel,
            height: 48,
            fontSize: 13,
            weight: AtelierButtonWeight.compact,
            onPressed: () => Navigator.pop(context, true),
          ),
      ],
    ),
  );
}

/// Card de sucesso reutilizável — assinatura, agendamento, etc.
class CustomerSuccessCard extends StatelessWidget {
  const CustomerSuccessCard({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.actionIcon = Icons.home_rounded,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    final desktop = AtelierVisuals.isShowcase(context);

    return Container(
      padding: EdgeInsets.fromLTRB(28, desktop ? 40 : 32, 28, 28),
      decoration: AtelierVisuals.card(
        context,
        goldRim: true,
        elevated: desktop,
        peak: true,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 54,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: desktop ? 26 : 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          AtelierGoldButton(
            expand: true,
            weight: AtelierButtonWeight.peak,
            label: actionLabel,
            leading: Icon(actionIcon, size: 18, color: AppColors.background),
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}
