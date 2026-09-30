import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'atelier_shell.dart';

/// Hero VIP reutilizável — assinatura e promoções do Clube.
class CustomerVipPromoHeader extends StatelessWidget {
  const CustomerVipPromoHeader({
    super.key,
    required this.brandName,
    this.tagline = 'Seu estilo merece tratamento exclusivo.',
  });

  final String brandName;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final desktop = AtelierVisuals.isShowcase(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22, desktop ? 22 : 18, 22, desktop ? 26 : 22),
      decoration: AtelierVisuals.vipCard(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -8,
            top: -14,
            child: Icon(
              Icons.workspace_premium_rounded,
              size: desktop ? 94 : 72,
              color: AppColors.primary.withValues(alpha: 0.13),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primaryBright,
                size: desktop ? 26 : 22,
              ),
              SizedBox(height: desktop ? 18 : 14),
              Text(
                'CLUBE VIP',
                style: TextStyle(
                  color: AppColors.primaryBright,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                brandName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: desktop ? 30 : 26,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                tagline,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
