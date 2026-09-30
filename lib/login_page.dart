import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_colors.dart';
import 'data/supabase_service.dart';
import 'models/barbearia_info.dart';
import 'widgets/customer/atelier_shell.dart';
import 'widgets/customer/customer_form.dart';
import 'widgets/customer/customer_scaffold.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  late final Future<BarbeariaInfo> _barbeariaFuture =
      SupabaseService.fetchBarbeariaInfo();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.signInWithGoogle();
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage = 'Não foi possível iniciar o login com Google.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (_isSignUp) {
        await SupabaseService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;

        if (Supabase.instance.client.auth.currentSession != null) {
          await SupabaseService.ensureUserProfile();
          return;
        }

        setState(() {
          _successMessage =
              'Enviamos um link de confirmação para ${_emailController.text.trim()}. '
              'Abra seu e-mail e clique no link para ativar a conta.';
          _isSignUp = false;
        });
        return;
      }

      await SupabaseService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await SupabaseService.ensureUserProfile();
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Login ok, mas não foi possível criar o perfil: ${error.message}',
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      setState(
        () => _errorMessage = message.isEmpty
            ? 'Erro ao autenticar. Tente novamente.'
            : message,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      center: true,
      maxWidth: 440,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          FutureBuilder<BarbeariaInfo>(
            future: _barbeariaFuture,
            builder: (context, snapshot) {
              final name = snapshot.data?.name.trim();
              return _BrandHeader(
                isSignUp: _isSignUp,
                brandName: (name == null || name.isEmpty)
                    ? 'Barbearia'
                    : name,
                photoUrl: snapshot.data?.photoUrl,
              );
            },
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomerGoogleButton(
                  isLoading: _isLoading,
                  onPressed: _handleGoogleSignIn,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'ou',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: customerInputDecoration(
                          label: 'E-mail',
                          icon: Icons.mail_outline_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe seu e-mail';
                          }
                          if (!value.contains('@')) {
                            return 'E-mail inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleEmailAuth(),
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: customerInputDecoration(
                          label: 'Senha',
                          icon: Icons.lock_outline_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe sua senha';
                          }
                          if (value.length < 6) {
                            return 'Mínimo de 6 caracteres';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (_successMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.mark_email_read_outlined,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                AtelierGoldButton(
                  expand: true,
                  label: _isSignUp ? 'Criar conta' : 'Entrar',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _handleEmailAuth,
                  weight: AtelierButtonWeight.peak,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isLoading
                ? null
                : () => setState(() {
                    _isSignUp = !_isSignUp;
                    _errorMessage = null;
                    _successMessage = null;
                  }),
            child: Text(
              _isSignUp
                  ? 'Já tem conta? Entrar'
                  : 'Novo por aqui? Criar conta',
              style: GoogleFonts.inter(
                color: AppColors.primaryBright,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ao continuar, você aceita os termos de uso desta barbearia.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.isSignUp,
    required this.brandName,
    this.photoUrl,
  });

  final bool isSignUp;
  final String brandName;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;
    final desktop = AtelierVisuals.isShowcase(context);

    final avatar = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: hasPhoto ? null : AppColors.primaryGradient,
        color: hasPhoto ? AppColors.card : null,
        borderRadius: BorderRadius.circular(22),
        image: hasPhoto
            ? DecorationImage(
                image: NetworkImage(photoUrl!),
                fit: BoxFit.cover,
              )
            : null,
        boxShadow: desktop ? AppColors.spotlight(dy: 8, blur: 24) : null,
      ),
      child: hasPhoto
          ? null
          : const Icon(
              Icons.content_cut_rounded,
              color: AppColors.background,
              size: 34,
            ),
    );

    return Column(
      children: [
        desktop ? AtelierGoldRing(glow: true, child: avatar) : avatar,
        const SizedBox(height: 20),
        Text(
          brandName,
          textAlign: TextAlign.center,
          style: GoogleFonts.sora(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isSignUp
              ? 'Crie sua conta e agende com estilo'
              : 'Entre para reservar seu horário',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
