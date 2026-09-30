import 'package:flutter/material.dart';

import '../operate/operate_kit.dart';

/// Cabeçalho padrão das telas do cliente — kit Operate compartilhado.
class CustomerPageHeader extends StatelessWidget {
  const CustomerPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.showBack = false,
    this.showBrandGreeting = false,
    this.greetingName,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool showBack;
  final bool showBrandGreeting;
  final String? greetingName;

  @override
  Widget build(BuildContext context) {
    return OperatePageHeader(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      showBack: showBack,
      showBrandGreeting: showBrandGreeting,
      greetingName: greetingName,
    );
  }
}
