import 'package:flutter/widgets.dart';

class AdminSession {
  const AdminSession({required this.barbershopId});

  final String barbershopId;
}

class AdminSessionScope extends InheritedWidget {
  const AdminSessionScope({
    super.key,
    required this.session,
    required super.child,
  });

  final AdminSession session;

  static AdminSession of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AdminSessionScope>();
    assert(scope != null, 'AdminSessionScope não encontrado.');
    return scope!.session;
  }

  @override
  bool updateShouldNotify(AdminSessionScope oldWidget) =>
      session.barbershopId != oldWidget.session.barbershopId;
}
