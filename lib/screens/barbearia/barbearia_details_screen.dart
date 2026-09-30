import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/supabase_service.dart';
import '../../models/barbearia_info.dart';
import '../../widgets/customer/atelier_shell.dart';
import '../../widgets/customer/customer_scaffold.dart';
import '../../widgets/responsive_page.dart';
import '../../widgets/screen_background.dart';

class BarbeariaDetailsScreen extends StatefulWidget {
  const BarbeariaDetailsScreen({super.key});

  @override
  State<BarbeariaDetailsScreen> createState() => _BarbeariaDetailsScreenState();
}

class _BarbeariaDetailsScreenState extends State<BarbeariaDetailsScreen> {
  late Future<BarbeariaInfo> _infoFuture = SupabaseService.fetchBarbeariaInfo();

  void _reload() {
    setState(() {
      _infoFuture = SupabaseService.fetchBarbeariaInfo();
    });
  }

  Future<void> _openInstagram(String value) async {
    final url = _normalizeInstagramUrl(value);
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _normalizeInstagramUrl(String value) {
    if (value.isEmpty) return value;
    if (value.startsWith('http')) return value;

    final handle = value.startsWith('@') ? value.substring(1) : value;
    return 'https://instagram.com/$handle';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<BarbeariaInfo>(
        future: _infoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomerScaffold(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return CustomerScaffold(
              showBack: true,
              child: ErrorView(
                message: 'Não foi possível carregar as informações.',
                onRetry: _reload,
              ),
            );
          }

          final info = snapshot.data!;
          return _BarbeariaContent(
            info: info,
            onInstagramTap: () => _openInstagram(info.instagramUrl),
          );
        },
      ),
    );
  }
}

class _BarbeariaContent extends StatelessWidget {
  const _BarbeariaContent({required this.info, required this.onInstagramTap});

  final BarbeariaInfo info;
  final VoidCallback onInstagramTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AtelierShellBackdrop(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: AppColors.background,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    _CoverImage(photoUrl: info.photoUrl),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0xCC121212),
                            Color(0xFF121212),
                          ],
                          stops: [0.3, 0.75, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ResponsivePage(
                padding: AppLayout.pagePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AtelierVisuals.isShowcase(context) ? 30 : 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _InfoSection(
                      title: 'Contato',
                      children: [
                        _InfoRow(
                          icon: Icons.location_on_rounded,
                          label: 'Endereço',
                          value: info.address,
                        ),
                    if (info.phone.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _PhoneRow(phone: info.phone),
                    ],
                        if (info.instagramUrl.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _InstagramRow(
                            url: info.instagramUrl,
                            onTap: onInstagramTap,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    _InfoSection(
                      title: 'Horários de Funcionamento',
                      children: [_OpeningHoursList(entries: info.openingHours)],
                    ),
                    SizedBox(height: AppLayout.clientBottomInset(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpeningHoursList extends StatelessWidget {
  const _OpeningHoursList({required this.entries});

  final List<OpeningHourEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text(
        'Horários não informados.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.day,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                entry.schedule,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: entry.schedule == 'Fechado'
                      ? AppColors.textMuted
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isEmpty) {
      return _CoverFallback();
    }

    return ClipRRect(
      child: Image.network(
        photoUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _CoverFallback(),
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.storefront_rounded,
        size: 64,
        color: AppColors.accentGold,
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AtelierVisuals.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryBright,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _PhoneRow extends StatelessWidget {
  const _PhoneRow({required this.phone});

  final String phone;

  Future<void> _call() async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _call,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.phone_rounded, size: 20, color: AppColors.primaryBright),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Telefone',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryBright,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.call_rounded, size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryBright),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InstagramRow extends StatelessWidget {
  const _InstagramRow({required this.url, required this.onTap});

  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            size: 20,
            color: AppColors.accentGold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instagram',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  url,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryBright,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.open_in_new_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
