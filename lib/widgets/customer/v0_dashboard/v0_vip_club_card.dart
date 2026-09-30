import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../atelier_shell.dart';
import 'v0_motion.dart';

/// Card Clube VIP no estilo v0 — apresentação pura; lógica fica no caller.
class V0VipClubCard extends StatelessWidget {
  const V0VipClubCard({
    super.key,
    required this.badge,
    required this.badgeColor,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.loading = false,
  });

  final String badge;
  final Color badgeColor;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final reduce = V0Motion.reduced(context);

    return V0HoverShell(
      borderRadius: 24,
      builder: (context, hovered) {
        return AnimatedContainer(
          duration: reduce ? Duration.zero : V0Motion.fast,
          curve: V0Motion.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(
                alpha: hovered ? 0.45 : 0.28,
              ),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: hovered ? 0.18 : 0.14),
                AppColors.card,
                AppColors.card,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Clube VIP',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (badge.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  badge,
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.8),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              V0PressScale(
                enabled: !loading,
                child: SizedBox(
                  width: double.infinity,
                  child: AtelierGoldButton(
                    label: loading ? '...' : actionLabel,
                    onPressed: loading ? null : onAction,
                    height: 48,
                    fontSize: 14,
                    expand: true,
                    weight: AtelierButtonWeight.peak,
                    isLoading: loading,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
