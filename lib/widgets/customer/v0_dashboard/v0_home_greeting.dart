import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Cabeçalho da home no estilo v0 — saudação + título + subtítulo.
class V0HomeGreeting extends StatelessWidget {
  const V0HomeGreeting({
    super.key,
    required this.userName,
    required this.subtitle,
  });

  final String userName;
  final String subtitle;

  static String timeOfDayLabel([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final first = userName.trim().split(RegExp(r'\s+')).first;
    final greetingName = first.isEmpty ? 'Cliente' : first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${timeOfDayLabel()}, $greetingName',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sua central de estilo',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: MediaQuery.sizeOf(context).width >= 900 ? 30 : 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
