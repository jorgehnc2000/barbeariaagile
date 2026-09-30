import 'package:flutter/widgets.dart';

class BarbershopRuntimeConfig {
  const BarbershopRuntimeConfig({
    required this.id,
    required this.slug,
    required this.mpPublicKey,
    required this.mpPlanId,
    this.planAmount,
    this.vipEnabled = false,
  });

  final String id;
  final String slug;
  final String mpPublicKey;
  final String mpPlanId;
  final double? planAmount;
  final bool vipEnabled;

  /// Fonte reativa da barbearia ativa — atualiza o [BarbershopScope].
  static final ValueNotifier<BarbershopRuntimeConfig?> listenable =
      ValueNotifier<BarbershopRuntimeConfig?>(null);

  static BarbershopRuntimeConfig? get current => listenable.value;

  static set current(BarbershopRuntimeConfig? value) {
    final previous = listenable.value;
    if (identical(previous, value)) return;
    if (previous != null &&
        value != null &&
        previous.id == value.id &&
        previous.slug == value.slug &&
        previous.mpPublicKey == value.mpPublicKey &&
        previous.mpPlanId == value.mpPlanId &&
        previous.planAmount == value.planAmount &&
        previous.vipEnabled == value.vipEnabled) {
      return;
    }
    listenable.value = value;
  }

  static String requireCurrentId() {
    final id = current?.id;
    if (id == null || id.isEmpty) {
      throw StateError('Nenhuma barbearia foi selecionada.');
    }
    return id;
  }
}

class BarbershopScope extends InheritedWidget {
  const BarbershopScope({
    super.key,
    required this.config,
    required super.child,
  });

  final BarbershopRuntimeConfig? config;

  static BarbershopRuntimeConfig? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BarbershopScope>()
        ?.config;
  }

  @override
  bool updateShouldNotify(BarbershopScope oldWidget) =>
      config?.id != oldWidget.config?.id ||
      config?.mpPublicKey != oldWidget.config?.mpPublicKey ||
      config?.mpPlanId != oldWidget.config?.mpPlanId ||
      config?.planAmount != oldWidget.config?.planAmount ||
      config?.vipEnabled != oldWidget.config?.vipEnabled;
}
