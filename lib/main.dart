import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/barbershop_runtime_config.dart';
import 'core/config/barbershop_resolver.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'data/supabase_service.dart';
import 'login_page.dart';
import 'screens/home/home_screen.dart';
import 'screens/subscription/sucesso_assinatura_page.dart';
import 'views/admin/admin_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  if (kIsWeb) {
    final uri = Uri.base;
    final hasOAuthCallback =
        uri.fragment.contains('access_token') ||
        uri.queryParameters.containsKey('code');
    if (hasOAuthCallback) {
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      } catch (error) {
        debugPrint('[App] Falha ao recuperar sessão OAuth: $error');
      }
    }
  }

  final barbershopConfig = await _loadBarbershopConfig();
  BarbershopRuntimeConfig.current = barbershopConfig;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(BarbeariaMouraApp(config: barbershopConfig));
}

Future<BarbershopRuntimeConfig?> _loadBarbershopConfig() async {
  if (!kIsWeb) return null;
  final slug = BarbershopResolver.slugFromCurrentUrl();
  if (slug == null || slug.isEmpty) return null;

  try {
    return await BarbershopResolver.resolveBySlug(slug);
  } catch (error) {
    debugPrint('[App] Não foi possível carregar a barbearia "$slug": $error');
    return null;
  }
}

String _resolveInitialRoute() {
  if (kIsWeb) {
    final path = Uri.base.path;
    if (path.isNotEmpty && path != '/') return path;
  }
  return '/';
}

class BarbeariaMouraApp extends StatelessWidget {
  const BarbeariaMouraApp({super.key, required this.config});

  final BarbershopRuntimeConfig? config;

  @override
  Widget build(BuildContext context) {
    // MaterialApp fica estável; só o Scope reconstrói quando o VIP muda.
    return ValueListenableBuilder<BarbershopRuntimeConfig?>(
      valueListenable: BarbershopRuntimeConfig.listenable,
      builder: (context, liveConfig, child) {
        return BarbershopScope(
          config: liveConfig ?? config,
          child: child!,
        );
      },
      child: MaterialApp(
        title: 'Barbearia Moura',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: _resolveInitialRoute(),
        onGenerateRoute: _generateRoute,
        onUnknownRoute: (_) =>
            MaterialPageRoute(builder: (_) => const _RouteNotFoundPage()),
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final segments = uri.pathSegments
        .map(Uri.decodeComponent)
        .where((segment) => segment.isNotEmpty)
        .toList();

    if (segments.isEmpty) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(),
      );
    }
    if (segments.length == 1 && segments.first == 'sucesso-assinatura') {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const SucessoAssinaturaPage(),
      );
    }
    if (segments.first == 'admin') {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const _AdminSlugRequiredPage(),
      );
    }

    final slug = segments.first.trim().toLowerCase();
    if (segments.length == 1) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(),
      );
    }
    if (segments.length == 2 && segments[1] == 'login') {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => _TenantLoginGate(slug: slug),
      );
    }
    if (segments.length >= 2 && segments[1] == 'admin') {
      final section = segments.length > 2 ? segments[2] : 'dashboard';
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => AdminShell(slug: slug, initialSection: section),
      );
    }
    return null;
  }
}

class _TenantLoginGate extends StatefulWidget {
  const _TenantLoginGate({required this.slug});

  final String slug;

  @override
  State<_TenantLoginGate> createState() => _TenantLoginGateState();
}

class _TenantLoginGateState extends State<_TenantLoginGate> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (data.session != null) {
        _redirectAfterLogin();
      }
    });
    if (Supabase.instance.client.auth.currentSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _redirectAfterLogin();
      });
    }
  }

  Future<void> _redirectAfterLogin() async {
    if (!mounted) return;

    try {
      await SupabaseService.ensureUserProfile();
    } catch (error) {
      debugPrint('[TenantLoginGate] ensureUserProfile: $error');
    }

    if (!mounted) return;
    final role = await SupabaseService.fetchCurrentUserRole();
    if (!mounted) return;

    final destination = role == 'admin'
        ? '/${widget.slug}/admin'
        : '/${widget.slug}';
    Navigator.pushReplacementNamed(context, destination);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const LoginPage();
}

class _AdminSlugRequiredPage extends StatelessWidget {
  const _AdminSlugRequiredPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '403 - Acesso Negado\nA rota administrativa deve informar a barbearia.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _RouteNotFoundPage extends StatelessWidget {
  const _RouteNotFoundPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(child: Text('Página não encontrada.')),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _syncProfileIfNeeded();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (data.session != null) {
        await SupabaseService.ensureUserProfile();
        if (mounted) setState(() {});
      } else if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _syncProfileIfNeeded() async {
    if (Supabase.instance.client.auth.currentSession != null) {
      await SupabaseService.ensureUserProfile();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      return const LoginPage();
    }

    return const HomeScreen();
  }
}
