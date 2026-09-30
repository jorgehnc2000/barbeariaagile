import 'package:flutter/material.dart';

import '../../core/config/barbershop_runtime_config.dart';
import '../../data/supabase_service.dart';
import '../../models/barbearia_info.dart';
import '../../widgets/customer/customer_dialog.dart';
import '../../widgets/customer/customer_scaffold.dart';

class SucessoAssinaturaPage extends StatelessWidget {
  const SucessoAssinaturaPage({super.key});

  void _goHome(BuildContext context) {
    final slug = BarbershopRuntimeConfig.current?.slug.trim();
    final route = (slug != null && slug.isNotEmpty) ? '/$slug' : '/';
    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      center: true,
      maxWidth: 430,
      child: FutureBuilder<BarbeariaInfo>(
        future: SupabaseService.fetchBarbeariaInfo(),
        builder: (context, snapshot) {
          final name = snapshot.data?.name.trim();
          final brandName =
              (name == null || name.isEmpty) ? 'sua barbearia' : name;

          return CustomerSuccessCard(
            title: 'Assinatura confirmada!',
            message:
                'Agora você faz parte do Clube VIP de $brandName. '
                'Aproveite seus benefícios exclusivos.',
            actionLabel: 'Voltar para o início',
            onAction: () => _goHome(context),
          );
        },
      ),
    );
  }
}
