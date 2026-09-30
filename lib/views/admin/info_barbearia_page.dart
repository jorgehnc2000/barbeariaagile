import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/barbershop_runtime_config.dart';
import '../../core/theme/app_colors.dart';
import '../../models/admin_dashboard.dart';
import '../../models/barbearia_info.dart';
import '../../widgets/image_picker_tile.dart';
import '../../widgets/responsive_page.dart';
import 'widgets/admin_ui.dart';

class InfoBarbeariaPage extends StatefulWidget {
  const InfoBarbeariaPage({super.key, this.onVipEnabledChanged});

  final ValueChanged<bool>? onVipEnabledChanged;

  @override
  State<InfoBarbeariaPage> createState() => _InfoBarbeariaPageState();
}

class _InfoBarbeariaPageState extends State<InfoBarbeariaPage> {
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _instagramController = TextEditingController();
  final _fotoUrlController = TextEditingController();

  dynamic _barbeariaId;
  bool _existeRegistro = false;
  List<DayHourInput> _hours = DayHourInput.fromHorariosMap(null);
  final List<TextEditingController> _textoControllers = [];
  final List<TextEditingController> _aberturaControllers = [];
  final List<TextEditingController> _fechamentoControllers = [];

  bool _loading = true;
  bool _saving = false;
  bool _vipEnabled = false;
  bool _savingVip = false;
  String? _loadError;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _initHourControllers();
    _loadAll();
  }

  void _initHourControllers() {
    for (final controller in _textoControllers) {
      controller.dispose();
    }
    for (final controller in _aberturaControllers) {
      controller.dispose();
    }
    for (final controller in _fechamentoControllers) {
      controller.dispose();
    }

    _textoControllers
      ..clear()
      ..addAll(_hours.map((h) => TextEditingController(text: h.text)));
    _aberturaControllers
      ..clear()
      ..addAll(_hours.map((h) => TextEditingController(text: h.abertura)));
    _fechamentoControllers
      ..clear()
      ..addAll(_hours.map((h) => TextEditingController(text: h.fechamento)));
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _instagramController.dispose();
    _fotoUrlController.dispose();
    for (final controller in _textoControllers) {
      controller.dispose();
    }
    for (final controller in _aberturaControllers) {
      controller.dispose();
    }
    for (final controller in _fechamentoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      await Future.wait([_loadBarbeariaInfo(), _loadVipFlag()]);
    } catch (error) {
      _loadError = error.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadBarbeariaInfo() async {
    final barbershopId = BarbershopRuntimeConfig.requireCurrentId();
    final response = await _client
        .from('barbearia_info')
        .select()
        .eq('barbershop_id', barbershopId)
        .limit(1);

    final rows = response as List<dynamic>;
    if (rows.isEmpty) {
      _barbeariaId = null;
      _existeRegistro = false;
      _nomeController.clear();
      _telefoneController.clear();
      _enderecoController.clear();
      _instagramController.clear();
      _fotoUrlController.clear();
      _hours = DayHourInput.fromHorariosMap(null);
      _initHourControllers();
      return;
    }

    final data = rows.first as Map<String, dynamic>;
    _barbeariaId = data['id'];
    _existeRegistro = true;
    _nomeController.text = data['nome'] as String? ?? '';
    _telefoneController.text = data['telefone'] as String? ?? '';
    _enderecoController.text = data['endereco'] as String? ?? '';
    _instagramController.text =
        data['instagram'] as String? ?? data['instagram_url'] as String? ?? '';
    _fotoUrlController.text = data['foto_url'] as String? ?? '';
    _hours = DayHourInput.fromHorariosMap(
      BarbeariaInfo.extractHorariosMap(data),
    );
    _initHourControllers();
  }

  Future<void> _loadVipFlag() async {
    final barbershopId = BarbershopRuntimeConfig.requireCurrentId();
    final row = await _client
        .from('barbershops')
        .select('vip_enabled')
        .eq('id', barbershopId)
        .maybeSingle();
    _vipEnabled = row?['vip_enabled'] == true;
    _syncRuntimeVipFlag();
  }

  void _syncRuntimeVipFlag() {
    final current = BarbershopRuntimeConfig.current;
    if (current == null) return;
    BarbershopRuntimeConfig.current = BarbershopRuntimeConfig(
      id: current.id,
      slug: current.slug,
      mpPublicKey: current.mpPublicKey,
      mpPlanId: current.mpPlanId,
      planAmount: current.planAmount,
      vipEnabled: _vipEnabled,
    );
  }

  Future<bool> _persistVipEnabled(bool value) async {
    try {
      // RPC security definer: persiste mesmo com RLS restritiva em barbershops.
      final confirmed = await _client.rpc(
        'set_barbershop_vip_enabled',
        params: {'p_enabled': value},
      );
      return confirmed == true;
    } catch (_) {
      // Fallback até a migration da RPC ser aplicada no projeto.
      final barbershopId = BarbershopRuntimeConfig.requireCurrentId();
      final updated = await _client
          .from('barbershops')
          .update({'vip_enabled': value})
          .eq('id', barbershopId)
          .select('vip_enabled')
          .maybeSingle();
      if (updated == null) {
        throw StateError('Não foi possível persistir vip_enabled.');
      }
      return updated['vip_enabled'] == true;
    }
  }

  Future<void> _toggleVipEnabled(bool value) async {
    if (_savingVip) return;
    setState(() => _savingVip = true);
    try {
      final enabled = await _persistVipEnabled(value);
      if (!mounted) return;
      setState(() {
        _vipEnabled = enabled;
        _syncRuntimeVipFlag();
      });
      widget.onVipEnabledChanged?.call(enabled);
      showAdminSnack(
        context,
        enabled
            ? 'Clube VIP ativado. Configure planos e Mercado Pago no menu Clube VIP.'
            : 'Clube VIP desativado. Clientes verão a aba Barbearia.',
      );
    } catch (error) {
      if (!mounted) return;
      showAdminSnack(
        context,
        adminOpError('atualizar o Clube VIP'),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _savingVip = false);
    }
  }

  List<DayHourInput> _buildHoursFromControllers() {
    return List.generate(_hours.length, (index) {
      final hour = _hours[index];
      final isOpen = hour.isOpen;
      final abertura = _aberturaControllers[index].text.trim();
      final fechamento = _fechamentoControllers[index].text.trim();
      final texto = _textoControllers[index].text.trim();

      return hour.copyWith(
        abertura: abertura,
        fechamento: fechamento,
        text: isOpen
            ? (texto.isNotEmpty
                  ? texto
                  : '${DayHourInput.formatHour(abertura)} às ${DayHourInput.formatHour(fechamento)}')
            : 'Fechado',
      );
    });
  }

  Future<void> _salvarAlteracoes() async {
    final barbershopId = BarbershopRuntimeConfig.requireCurrentId();
    setState(() => _saving = true);

    try {
      final horariosAtualizados = DayHourInput.toHorariosJson(
        _buildHoursFromControllers(),
      );

      final payload = {
        'nome': _nomeController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'endereco': _enderecoController.text.trim(),
        'instagram': _instagramController.text.trim(),
        'foto_url': _fotoUrlController.text.trim(),
        'horarios': horariosAtualizados,
        'horarios_funcionamento': horariosAtualizados,
        'barbershop_id': barbershopId,
      };

      if (_existeRegistro && _barbeariaId != null) {
        await _client
            .from('barbearia_info')
            .update(payload)
            .eq('id', _barbeariaId)
            .eq('barbershop_id', barbershopId);
      } else {
        final inserted = await _client
            .from('barbearia_info')
            .insert(payload)
            .select('id')
            .single();
        _barbeariaId = inserted['id'];
        _existeRegistro = true;
      }

      if (!mounted) return;
      showAdminSnack(context, 'Alterações salvas com sucesso!');
      await _loadBarbeariaInfo();
    } catch (error) {
      if (!mounted) return;
      showAdminSnack(
        context,
        adminOpError('salvar as alterações'),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdminBreakpoints.isDesktop(context);

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentGold),
      );
    }

    if (_loadError != null && _barbeariaId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 40),
              const SizedBox(height: 12),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              AdminPrimaryButton(
                label: 'Tentar novamente',
                onPressed: _loadAll,
              ),
            ],
          ),
        ),
      );
    }

    return ResponsivePage(
      maxWidth: AppLayout.adminMaxWidth,
      padding: AppLayout.pagePadding(context, admin: true),
      expand: true,
      child: Stack(
        children: [
          ListView(
            children: [
              AdminPageHeader(
                title: 'A casa',
                subtitle: 'Nome, contato, horários e integrações.',
                trailing: AdminPrimaryButton(
                  label: _saving ? 'Salvando...' : 'Salvar',
                  icon: Icons.save_rounded,
                  isLoading: _saving,
                  onPressed: _saving ? null : _salvarAlteracoes,
                ),
              ),
              const SizedBox(height: 18),
              _SettingsCard(
                title: 'Dados da barbearia',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdminCardGrid(
                      gap: 16,
                      columnsForWidth: (width) => width >= 700 ? 2 : 1,
                      children: [
                        TextField(
                          controller: _nomeController,
                          decoration: adminInputDecoration(
                            label: 'Nome da Barbearia',
                            icon: Icons.store_rounded,
                          ),
                        ),
                        TextField(
                          controller: _telefoneController,
                          decoration: adminInputDecoration(
                            label: 'Telefone / WhatsApp',
                            icon: Icons.phone_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _enderecoController,
                      decoration: const InputDecoration(
                        labelText: 'Endereço',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _instagramController,
                      decoration: adminInputDecoration(
                        label: 'Instagram',
                        icon: Icons.camera_alt_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ImagePickerTile(
                      imageUrl: _fotoUrlController.text,
                      height: 160,
                      label: 'Logo / foto da casa',
                      hint: 'Toque para enviar o logo',
                      onImageUploaded: (url) {
                        setState(() => _fotoUrlController.text = url);
                      },
                      onError: (message) =>
                          showAdminSnack(context, message, error: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                title: 'Horário de funcionamento',
                child: Column(
                  children: [
                    ...List.generate(_hours.length, (index) {
                      final hour = _hours[index];
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: isDesktop
                            ? Row(
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      hour.day,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: hour.isOpen,
                                    activeThumbColor: AppColors.accentGold,
                                    onChanged: (value) => setState(() {
                                      _hours[index] = hour.copyWith(
                                        isOpen: value,
                                      );
                                    }),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _HourFields(
                                      enabled: hour.isOpen,
                                      textoController: _textoControllers[index],
                                      aberturaController:
                                          _aberturaControllers[index],
                                      fechamentoController:
                                          _fechamentoControllers[index],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        hour.day,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Switch(
                                        value: hour.isOpen,
                                        activeThumbColor: AppColors.accentGold,
                                        onChanged: (value) => setState(() {
                                          _hours[index] = hour.copyWith(
                                            isOpen: value,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                  if (hour.isOpen) ...[
                                    const SizedBox(height: 8),
                                    _HourFields(
                                      enabled: true,
                                      textoController: _textoControllers[index],
                                      aberturaController:
                                          _aberturaControllers[index],
                                      fechamentoController:
                                          _fechamentoControllers[index],
                                    ),
                                  ],
                                ],
                              ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                title: 'Clube VIP',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ative para oferecer assinatura mensal com cortes a R\$ 0,00. '
                      'Desativado, os clientes veem a aba Barbearia no lugar do VIP. '
                      'Planos e credenciais do Mercado Pago ficam no menu Clube VIP.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Ativar Clube VIP nesta barbearia',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      value: _vipEnabled,
                      activeThumbColor: AppColors.accentGold,
                      onChanged: _savingVip ? null : _toggleVipEnabled,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
          if (_saving || _savingVip)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: AdminVisuals.surface(context, radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AdminVisuals.sectionLabel(context),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _HourFields extends StatelessWidget {
  const _HourFields({
    required this.enabled,
    required this.textoController,
    required this.aberturaController,
    required this.fechamentoController,
  });

  final bool enabled;
  final TextEditingController textoController;
  final TextEditingController aberturaController;
  final TextEditingController fechamentoController;

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdminBreakpoints.isDesktop(context);

    if (isDesktop) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              enabled: enabled,
              controller: textoController,
              decoration: const InputDecoration(
                labelText: 'Texto exibido',
                hintText: '09h às 20h',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              enabled: enabled,
              controller: aberturaController,
              decoration: const InputDecoration(
                labelText: 'Abertura',
                hintText: '09:00',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              enabled: enabled,
              controller: fechamentoController,
              decoration: const InputDecoration(
                labelText: 'Fechamento',
                hintText: '20:00',
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        TextField(
          enabled: enabled,
          controller: textoController,
          decoration: const InputDecoration(
            labelText: 'Texto exibido',
            hintText: '09h às 20h',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                enabled: enabled,
                controller: aberturaController,
                decoration: const InputDecoration(
                  labelText: 'Abertura',
                  hintText: '09:00',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                enabled: enabled,
                controller: fechamentoController,
                decoration: const InputDecoration(
                  labelText: 'Fechamento',
                  hintText: '20:00',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
