import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/customer/customer_form.dart';
import 'admin_visuals.dart';

export 'admin_visuals.dart'
    show
        AdminBreakpoints,
        AdminPageHeader,
        AdminPanel,
        AdminPrimaryButton,
        AdminOutlineButton,
        AdminDangerButton,
        AdminStatusBadge,
        AdminStatusToggle,
        AdminGhostAction,
        AdminIconGhostAction,
        AdminVisuals,
        AdminStatsRail,
        BrandScope,
        operateGreeting;
export 'admin_elite_kit.dart'
    show
        EliteInkEdgeButton,
        EliteOutlineButton,
        EliteDangerButton,
        EliteGhostAction,
        EliteIconGhostAction,
        EliteStatusBadge,
        EliteStatusToggle;

/// Grid alinhado: evita o Wrap quebrado por arredondamento de largura.
class AdminCardGrid extends StatelessWidget {
  const AdminCardGrid({
    super.key,
    required this.children,
    this.gap = 16,
    this.columnsForWidth,
  });

  final List<Widget> children;
  final double gap;
  final int Function(double width)? columnsForWidth;

  static int defaultMetricColumns(double width) {
    if (width >= 900) return 4;
    if (width >= 640) return 2;
    return 1;
  }

  static int defaultCardColumns(double width) {
    if (width >= 1000) return 3;
    if (width >= 680) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final columns = math.max(
          1,
          (columnsForWidth ?? defaultCardColumns)(width),
        );
        final rows = <Widget>[];

        for (var i = 0; i < children.length; i += columns) {
          final slice = children.sublist(
            i,
            math.min(i + columns, children.length),
          );
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) SizedBox(width: gap),
                    Expanded(
                      child: j < slice.length
                          ? slice[j]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
          if (i + columns < children.length) {
            rows.add(SizedBox(height: gap));
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}

/// Dois painéis lado a lado no desktop, empilhados no mobile — mesma altura.
class AdminSplitRow extends StatelessWidget {
  const AdminSplitRow({
    super.key,
    required this.left,
    required this.right,
    this.breakpoint = 900,
    this.gap = 20,
    this.leftFlex = 1,
    this.rightFlex = 1,
  });

  final Widget left;
  final Widget right;
  final double breakpoint;
  final double gap;
  final int leftFlex;
  final int rightFlex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, SizedBox(height: gap), right],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: leftFlex, child: left),
              SizedBox(width: gap),
              Expanded(flex: rightFlex, child: right),
            ],
          ),
        );
      },
    );
  }
}

Future<T?> showAdminForm<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  required VoidCallback onSave,
  bool isSaving = false,
}) {
  final isDesktop = AdminBreakpoints.isDesktop(context);

  if (isDesktop) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        content: SizedBox(
          width: 480,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.7,
            ),
            child: SingleChildScrollView(child: child),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          AdminPrimaryButton(
            label: isSaving ? 'Salvando...' : 'Salvar',
            icon: Icons.save_rounded,
            isLoading: isSaving,
            onPressed: isSaving ? null : onSave,
          ),
        ],
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      side: BorderSide(color: AppColors.border),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.92,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: child,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: AdminPrimaryButton(
                expand: true,
                label: isSaving ? 'Salvando...' : 'Salvar',
                icon: Icons.save_rounded,
                isLoading: isSaving,
                onPressed: isSaving ? null : onSave,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Decoração de input padrão do admin — reutiliza o kit do cliente.
InputDecoration adminInputDecoration({
  required String label,
  IconData? icon,
  String? hint,
}) =>
    customerInputDecoration(label: label, icon: icon, hint: hint);

String formatAdminCurrency(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  return 'R\$ ${parts[0]},${parts[1]}';
}

/// Feedback operacional — validação e erros legíveis (nunca falhar em silêncio).
void showAdminSnack(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  // Prefer o messenger da árvore raiz — SnackBars de dialogos ficam
  // atrás do barrier e parecem "não ter acontecido".
  final rootContext = Navigator.maybeOf(context, rootNavigator: true)?.context;
  final messenger = rootContext != null
      ? ScaffoldMessenger.maybeOf(rootContext) ?? ScaffoldMessenger.of(context)
      : ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? AppColors.error : AppColors.card,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    ),
  );
}

/// Copy humana para falhas de rede/API — sem dump de Exception.
String adminOpError(String action) =>
    'Não foi possível $action. Tente novamente.';

