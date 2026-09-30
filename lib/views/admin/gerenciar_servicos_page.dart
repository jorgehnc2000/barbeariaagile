import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/admin_service.dart';
import '../../data/supabase_service.dart';
import '../../models/service.dart';
import '../../widgets/image_picker_tile.dart';
import '../../widgets/responsive_page.dart';
import 'widgets/admin_ui.dart';

class GerenciarServicosPage extends StatefulWidget {
  const GerenciarServicosPage({super.key});

  @override
  State<GerenciarServicosPage> createState() => _GerenciarServicosPageState();
}

class _GerenciarServicosPageState extends State<GerenciarServicosPage> {
  late Future<List<Service>> _servicesFuture = SupabaseService.fetchServices();

  void _reload() {
    setState(() => _servicesFuture = SupabaseService.fetchServices());
  }

  Future<void> _openForm({Service? service}) async {
    final nameCtrl = TextEditingController(text: service?.name ?? '');
    final descCtrl = TextEditingController(text: service?.description ?? '');
    final priceCtrl = TextEditingController(
      text: service != null ? service.price.toStringAsFixed(2) : '',
    );
    final durationCtrl = TextEditingController(
      text: service?.durationMinutes.toString() ?? '',
    );
    var imageUrl = service?.imageUrl?.trim() ?? '';

    await showAdminForm(
      context: context,
      title: service == null ? 'Novo Serviço' : 'Editar Serviço',
      onSave: () async {
        final price = double.tryParse(priceCtrl.text.replaceAll(',', '.'));
        final duration = int.tryParse(durationCtrl.text);
        if (nameCtrl.text.trim().isEmpty) {
          showAdminSnack(context, 'Informe o nome do serviço.');
          return;
        }
        if (price == null) {
          showAdminSnack(context, 'Informe um preço válido (ex.: 45,00).');
          return;
        }
        if (duration == null || duration <= 0) {
          showAdminSnack(context, 'Informe a duração em minutos.');
          return;
        }

        try {
          if (service == null) {
            await AdminService.createService(
              name: nameCtrl.text.trim(),
              price: price,
              durationMinutes: duration,
              imageUrl: imageUrl.isEmpty ? null : imageUrl,
              description: descCtrl.text.trim(),
            );
          } else {
            await AdminService.updateService(
              id: service.id,
              name: nameCtrl.text.trim(),
              price: price,
              durationMinutes: duration,
              imageUrl: imageUrl.isEmpty ? null : imageUrl,
              description: descCtrl.text.trim(),
            );
          }
          if (!mounted) return;
          Navigator.pop(context);
          _reload();
        } catch (e) {
          if (!mounted) return;
          showAdminSnack(context, adminOpError('salvar o serviço'), error: true);
        }
      },
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ImagePickerTile(
                imageUrl: imageUrl,
                height: 140,
                label: 'Imagem do serviço',
                hint: 'Toque para enviar a imagem',
                onImageUploaded: (url) {
                  setModalState(() => imageUrl = url);
                },
                onError: (message) =>
                    showAdminSnack(context, message, error: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: adminInputDecoration(
                  label: 'Nome',
                  icon: Icons.design_services_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: adminInputDecoration(
                  label: 'Descrição',
                  icon: Icons.notes_rounded,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: adminInputDecoration(
                  label: 'Preço (R\$)',
                  icon: Icons.payments_outlined,
                  hint: '45,00',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationCtrl,
                keyboardType: TextInputType.number,
                decoration: adminInputDecoration(
                  label: 'Duração (min)',
                  icon: Icons.schedule_rounded,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteService(Service service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Excluir serviço?'),
        content: Text('Remover ${service.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          AdminDangerButton(
            label: 'Excluir',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AdminService.deleteService(service.id);
      _reload();
    } catch (e) {
      if (!mounted) return;
      showAdminSnack(context, adminOpError('excluir o serviço'), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      maxWidth: AppLayout.adminMaxWidth,
      padding: AppLayout.pagePadding(context, admin: true),
      expand: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Serviços',
            subtitle: 'Preços, duração e catálogo.',
            trailing: AdminPrimaryButton(
              label: 'Novo serviço',
              icon: Icons.add_rounded,
              onPressed: () => _openForm(),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: FutureBuilder<List<Service>>(
              future: _servicesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentGold,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      adminOpError('carregar os serviços'),
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }

                final services = snapshot.data ?? [];
                if (services.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum serviço cadastrado.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: services.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return _ServiceRow(
                      service: service,
                      onEdit: () => _openForm(service: service),
                      onDelete: () => _deleteService(service),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  final Service service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        service.imageUrl != null && service.imageUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AdminVisuals.glass(context, radius: 14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: hasImage
                ? Image.network(
                    service.imageUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _ServiceThumb(),
                  )
                : const _ServiceThumb(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: formatAdminCurrency(service.price),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: '  ·  ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: '${service.durationMinutes} min',
                        style: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          AdminIconGhostAction(
            icon: Icons.edit_rounded,
            tooltip: 'Editar',
            onPressed: onEdit,
          ),
          AdminIconGhostAction(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Remover',
            onPressed: onDelete,
            destructive: true,
          ),
        ],
      ),
    );
  }
}

class _ServiceThumb extends StatelessWidget {
  const _ServiceThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AdminVisuals.deepFill(context),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.content_cut_rounded,
        size: 20,
        color: AppColors.primary,
      ),
    );
  }
}
