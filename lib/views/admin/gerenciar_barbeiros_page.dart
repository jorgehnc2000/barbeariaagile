import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/admin_service.dart';
import '../../data/supabase_service.dart';
import '../../models/barber.dart';
import '../../widgets/customer/customer_dialog.dart';
import '../../widgets/image_picker_tile.dart';
import '../../widgets/responsive_page.dart';
import 'widgets/admin_ui.dart';

class GerenciarBarbeirosPage extends StatefulWidget {
  const GerenciarBarbeirosPage({super.key});

  @override
  State<GerenciarBarbeirosPage> createState() => _GerenciarBarbeirosPageState();
}

class _GerenciarBarbeirosPageState extends State<GerenciarBarbeirosPage> {
  late Future<List<Barber>> _barbersFuture = SupabaseService.fetchBarbers();

  void _reload() {
    setState(() => _barbersFuture = SupabaseService.fetchBarbers());
  }

  Future<void> _toggleAvailability(Barber barber, bool value) async {
    try {
      await AdminService.updateBarber(
        id: barber.id,
        name: barber.name,
        photoUrl: barber.photoUrl,
        specialty: barber.specialty,
        isAvailable: value,
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      showAdminSnack(
        context,
        adminOpError('atualizar o status'),
        error: true,
      );
    }
  }

  Future<void> _openForm({Barber? barber}) async {
    final nameCtrl = TextEditingController(text: barber?.name ?? '');
    final specialtyCtrl = TextEditingController(text: barber?.specialty ?? '');
    var photoUrl = barber?.photoUrl.trim() ?? '';
    var isAvailable = barber?.isAvailable ?? true;

    await showAdminForm(
      context: context,
      title: barber == null ? 'Novo Barbeiro' : 'Editar Barbeiro',
      onSave: () async {
        if (nameCtrl.text.trim().isEmpty) {
          showAdminSnack(context, 'Informe o nome do barbeiro.');
          return;
        }
        try {
          if (barber == null) {
            await AdminService.createBarber(
              name: nameCtrl.text.trim(),
              photoUrl: photoUrl,
              specialty: specialtyCtrl.text.trim(),
              isAvailable: isAvailable,
            );
          } else {
            await AdminService.updateBarber(
              id: barber.id,
              name: nameCtrl.text.trim(),
              photoUrl: photoUrl,
              specialty: specialtyCtrl.text.trim(),
              isAvailable: isAvailable,
            );
          }
          if (!mounted) return;
          Navigator.pop(context);
          _reload();
        } catch (e) {
          if (!mounted) return;
          showAdminSnack(context, adminOpError('salvar o barbeiro'), error: true);
        }
      },
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ImagePickerTile(
                imageUrl: photoUrl,
                circular: true,
                height: 120,
                label: 'Foto do barbeiro',
                hint: 'Toque para enviar a foto',
                onImageUploaded: (url) {
                  setModalState(() => photoUrl = url);
                },
                onError: (message) =>
                    showAdminSnack(context, message, error: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: adminInputDecoration(
                  label: 'Nome',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: specialtyCtrl,
                decoration: adminInputDecoration(
                  label: 'Especialidade',
                  icon: Icons.content_cut_rounded,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Disponível',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AdminStatusToggle(
                    value: isAvailable,
                    onChanged: (value) =>
                        setModalState(() => isAvailable = value),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteBarber(Barber barber) async {
    final confirm = await showCustomerDialog(
      context: context,
      title: 'Excluir barbeiro?',
      message: 'Remover ${barber.name}? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
    );

    if (confirm != true) return;

    try {
      await AdminService.deleteBarber(barber.id);
      _reload();
    } catch (e) {
      if (!mounted) return;
      showAdminSnack(context, adminOpError('excluir o barbeiro'), error: true);
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
            title: 'Equipe',
            subtitle: 'Barbeiros, especialidades e disponibilidade.',
            trailing: AdminPrimaryButton(
              label: 'Novo barbeiro',
              icon: Icons.add_rounded,
              onPressed: () => _openForm(),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: FutureBuilder<List<Barber>>(
              future: _barbersFuture,
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
                      adminOpError('carregar a equipe'),
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }

                final barbers = snapshot.data ?? [];
                if (barbers.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum barbeiro cadastrado.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: AdminCardGrid(
                    gap: 12,
                    columnsForWidth: (width) {
                      if (width >= 980) return 3;
                      if (width >= 640) return 2;
                      return 1;
                    },
                    children: [
                      for (final barber in barbers)
                        _BarberCard(
                          barber: barber,
                          onEdit: () => _openForm(barber: barber),
                          onDelete: () => _deleteBarber(barber),
                          onToggle: (value) =>
                              _toggleAvailability(barber, value),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BarberCard extends StatelessWidget {
  const _BarberCard({
    required this.barber,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final Barber barber;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final specialty =
        barber.specialty.isEmpty ? 'Barbeiro' : barber.specialty;

    return Opacity(
      opacity: barber.isAvailable ? 1 : 0.78,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        decoration: AdminVisuals.glass(context, radius: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AdminVisuals.deepFill(context),
                  backgroundImage: barber.photoUrl.isNotEmpty
                      ? NetworkImage(barber.photoUrl)
                      : null,
                  child: barber.photoUrl.isEmpty
                      ? Text(
                          barber.name.isNotEmpty ? barber.name[0] : '?',
                          style: TextStyle(
                            color: barber.isAvailable
                                ? AppColors.primary
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              barber.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AdminStatusBadge(active: barber.isAvailable),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        specialty,
                        style: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AdminStatusToggle(
                  value: barber.isAvailable,
                  onChanged: onToggle,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.white.withValues(alpha: 0.06),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AdminGhostAction(
                  label: 'Editar',
                  icon: Icons.edit_rounded,
                  onPressed: onEdit,
                ),
                AdminGhostAction(
                  label: 'Remover',
                  icon: Icons.delete_outline_rounded,
                  onPressed: onDelete,
                  destructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
