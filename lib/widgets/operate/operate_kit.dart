import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/barbearia_info.dart';
import '../customer/atelier_shell.dart';

/// Breakpoints compartilhados — admin e cliente Operate.
abstract final class OperateBreakpoints {
  static const double desktop = 900;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;
}

/// Superfícies flat Operate — ouro raro, escaneável.
abstract final class OperateVisuals {
  OperateVisuals._();

  static BoxDecoration surface({
    Color? background,
    double radius = 16,
  }) {
    return BoxDecoration(
      color: background ?? AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.border),
    );
  }

  static BoxDecoration insetSurface({double radius = 14}) {
    return BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.border),
    );
  }

  static BoxDecoration navItem({required bool selected}) {
    if (!selected) return const BoxDecoration();
    return BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(12),
    );
  }

  static Widget navAccent({required bool selected}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 3,
      height: 20,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Marca da barbearia ativa — admin e cliente.
class BrandScope extends InheritedWidget {
  const BrandScope({
    super.key,
    required this.brand,
    required super.child,
  });

  final BarbeariaInfo? brand;

  static BarbeariaInfo? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BrandScope>()?.brand;
  }

  static String shopName(BuildContext context, {String fallback = 'Barbearia'}) {
    final name = maybeOf(context)?.name.trim();
    if (name != null && name.isNotEmpty) return name;
    return fallback;
  }

  @override
  bool updateShouldNotify(BrandScope oldWidget) =>
      brand?.id != oldWidget.brand?.id ||
      brand?.name != oldWidget.brand?.name ||
      brand?.photoUrl != oldWidget.brand?.photoUrl;
}

/// Avatar + nome da loja.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.brand,
    this.compact = false,
    this.subtitle,
  });

  final BarbeariaInfo? brand;
  final bool compact;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final resolved = brand ?? BrandScope.maybeOf(context);
    final name = resolved?.name.trim().isNotEmpty == true
        ? resolved!.name.trim()
        : 'Sua barbearia';
    final photo = resolved?.photoUrl.trim() ?? '';

    return Row(
      children: [
        _ShopAvatar(photoUrl: photo, size: compact ? 36 : 42),
        if (!compact) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ShopAvatar extends StatelessWidget {
  const _ShopAvatar({required this.photoUrl, required this.size});

  final String photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
        image: hasPhoto
            ? DecorationImage(
                image: NetworkImage(photoUrl),
                fit: BoxFit.cover,
              )
            : null,
        color: hasPhoto ? null : AppColors.background,
      ),
      child: hasPhoto
          ? null
          : Icon(
              Icons.content_cut_rounded,
              size: size * 0.45,
              color: AppColors.primary,
            ),
    );
  }
}

/// Cabeçalho Operate — admin e cliente.
class OperatePageHeader extends StatelessWidget {
  const OperatePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showBack = false,
    this.padding = EdgeInsets.zero,
    this.showBrandGreeting = false,
    this.showBrandMark = false,
    this.greetingName,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showBack;
  final EdgeInsetsGeometry padding;
  final bool showBrandGreeting;
  final bool showBrandMark;
  final String? greetingName;

  @override
  Widget build(BuildContext context) {
    final desktop = OperateBreakpoints.isDesktop(context);
    final brand = BrandScope.maybeOf(context);
    final greetingTarget = greetingName ??
        (showBrandGreeting ? BrandScope.shopName(context) : null);

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (greetingTarget != null) ...[
                  Text(
                    '${operateGreeting()}, $greetingTarget',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: desktop ? 24 : 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: desktop ? -0.4 : -0.25,
                    height: 1.15,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
                if (brand != null && showBrandMark) ...[
                  const SizedBox(height: 10),
                  BrandMark(
                    brand: brand,
                    compact: true,
                    subtitle: brand.address.trim().isNotEmpty
                        ? brand.address.trim()
                        : null,
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Painel de conteúdo Operate.
class OperatePanel extends StatelessWidget {
  const OperatePanel({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: OperateVisuals.surface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class StatItem {
  const StatItem({
    required this.label,
    required this.value,
    this.hint,
  });

  final String label;
  final String value;
  final String? hint;
}

class StatsRail extends StatelessWidget {
  const StatsRail({super.key, required this.items});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: OperateVisuals.surface(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 560;
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: AppColors.border, height: 1),
                    ),
                  _StatCell(
                    item: items[i],
                    align: CrossAxisAlignment.start,
                    compact: true,
                  ),
                ],
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    const VerticalDivider(
                      color: AppColors.border,
                      width: 1,
                      indent: 4,
                      endIndent: 4,
                    ),
                  Expanded(child: _StatCell(item: items[i])),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.item,
    this.align = CrossAxisAlignment.center,
    this.compact = false,
  });

  final StatItem item;
  final CrossAxisAlignment align;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textAlign = align == CrossAxisAlignment.start
        ? TextAlign.left
        : TextAlign.center;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 14),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            item.label,
            textAlign: textAlign,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            textAlign: textAlign,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              height: 1.1,
            ),
          ),
          if (item.hint != null) ...[
            const SizedBox(height: 4),
            Text(
              item.hint!,
              textAlign: textAlign,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom nav Operate — mesma estrutura do admin.
class OperateBottomNav extends StatelessWidget {
  const OperateBottomNav({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onSelect,
    this.onOpenMenu,
  });

  final int selectedIndex;
  final List<({int? index, IconData icon, String label})> items;
  final ValueChanged<int> onSelect;
  final VoidCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: OperateVisuals.surface(radius: 18),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: items.map((item) {
          final active = item.index != null && selectedIndex == item.index;
          return Expanded(
            child: InkWell(
              onTap: () {
                if (item.index == null) {
                  onOpenMenu?.call();
                } else {
                  onSelect(item.index!);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: active
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w500,
                        color: active
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

String operateGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Bom dia';
  if (hour < 18) return 'Boa tarde';
  return 'Boa noite';
}

/// CTA primário — ouro compacto (admin + cliente).
class OperatePrimaryButton extends StatelessWidget {
  const OperatePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AtelierGoldButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      height: 48,
      fontSize: 13,
      weight: AtelierButtonWeight.compact,
      leading: icon == null
          ? null
          : Icon(icon, size: 18, color: AppColors.background),
    );
  }
}
