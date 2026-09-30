import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/supabase_service.dart';
import '../../models/barbearia_info.dart';
import '../../widgets/customer/atelier_shell.dart';
import '../../widgets/customer/customer_page_header.dart';
import '../../widgets/screen_background.dart';
import '../../widgets/responsive_page.dart';

/// Conteúdo da aba "Barbearia" (slot 3 quando VIP está desligado).
class BarbeariaTabPanel extends StatefulWidget {
  const BarbeariaTabPanel({super.key, this.onOpenAgendar});

  final VoidCallback? onOpenAgendar;

  @override
  State<BarbeariaTabPanel> createState() => _BarbeariaTabPanelState();
}

class _BarbeariaTabPanelState extends State<BarbeariaTabPanel> {
  late Future<BarbeariaInfo> _future = SupabaseService.fetchBarbeariaInfo();

  void _reload() {
    setState(() => _future = SupabaseService.fetchBarbeariaInfo());
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
    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: ResponsivePage(
          expand: true,
          maxWidth: AppLayout.clientMaxWidth,
          padding: AppLayout.pagePadding(context),
          child: FutureBuilder<BarbeariaInfo>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView();
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return ErrorView(
                  message: 'Não foi possível carregar a barbearia.',
                  onRetry: _reload,
                );
              }

              final info = snapshot.data!;
              return ListView(
                children: [
                  CustomerPageHeader(
                    title: 'Barbearia',
                    subtitle: info.name.isNotEmpty
                        ? info.name
                        : 'Conheça a casa e como chegar.',
                  ),
                  const SizedBox(height: 18),
                  if (info.photoUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          info.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _PhotoFallback(),
                        ),
                      ),
                    )
                  else
                    _PhotoFallback(),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Contato',
                    children: [
                      if (info.address.isNotEmpty)
                        _InfoLine(
                          icon: Icons.location_on_rounded,
                          label: 'Endereço',
                          value: info.address,
                        ),
                      if (info.phone.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _PhoneLine(phone: info.phone),
                      ],
                      if (info.instagramUrl.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _InstagramLine(
                          url: info.instagramUrl,
                          onTap: () => _openInstagram(info.instagramUrl),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Horários de funcionamento',
                    children: [
                      if (info.openingHours.isEmpty)
                        Text(
                          'Horários não informados.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textMuted),
                        )
                      else
                        ...info.openingHours.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.day,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    entry.schedule,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: entry.schedule == 'Fechado'
                                          ? AppColors.textMuted
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (widget.onOpenAgendar != null) ...[
                    const SizedBox(height: 22),
                    AtelierGoldButton(
                      expand: true,
                      label: 'Agendar agora',
                      leading: const Icon(
                        Icons.calendar_month_rounded,
                        size: 18,
                        color: AppColors.background,
                      ),
                      onPressed: widget.onOpenAgendar,
                    ),
                  ],
                  SizedBox(height: AppLayout.clientBottomInset(context)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class BarbeariaSpotlightCard extends StatelessWidget {
  const BarbeariaSpotlightCard({
    super.key,
    required this.barbearia,
    required this.onOpenBarbearia,
  });

  final BarbeariaInfo barbearia;
  final VoidCallback onOpenBarbearia;

  String get _todaySchedule {
    const weekdays = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo',
    ];
    final today = weekdays[DateTime.now().weekday - 1];
    for (final entry in barbearia.openingHours) {
      if (entry.day.toLowerCase().startsWith(today.toLowerCase())) {
        return entry.schedule;
      }
    }
    if (barbearia.openingHours.isNotEmpty) {
      return barbearia.openingHours.first.schedule;
    }
    return 'Consulte os horários';
  }

  @override
  Widget build(BuildContext context) {
    final name = barbearia.name.trim().isNotEmpty
        ? barbearia.name.trim()
        : 'Nossa barbearia';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenBarbearia,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: AtelierVisuals.vipCard(context),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hoje: $_todaySchedule',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onOpenBarbearia,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBright,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text(
                  'Conhecer',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.storefront_rounded,
          size: 48,
          color: AppColors.accentGold,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

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

class _InfoLine extends StatelessWidget {
  const _InfoLine({
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhoneLine extends StatelessWidget {
  const _PhoneLine({required this.phone});

  final String phone;

  Future<void> _call() async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$digits');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _call,
      borderRadius: BorderRadius.circular(8),
      child: _InfoLine(
        icon: Icons.phone_rounded,
        label: 'Telefone',
        value: phone,
      ),
    );
  }
}

class _InstagramLine extends StatelessWidget {
  const _InstagramLine({required this.url, required this.onTap});

  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: _InfoLine(
        icon: Icons.camera_alt_outlined,
        label: 'Instagram',
        value: url,
      ),
    );
  }
}
