import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/localization/auth_error_messages.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/motion.dart';
import '../../widgets/xefi_backdrop.dart';
import '../../widgets/xefi_logo.dart';
import 'sign_up_screen.dart';

/// A populated demo account, spelled out on the screen rather than left in the
/// README. The repository is public and read by people who have no account, and
/// for them the login form is otherwise a wall with nothing behind it.
///
/// These open nothing private: the colleague is invented, the address is on a
/// domain that cannot receive mail, and row level security still decides what
/// the session may read once signed in.
const String _demoAccountEmail = 'camille.roussel@demo.xefi.local';
const String _demoAccountPassword = 'DemoXefi!2026';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  void _fillDemoAccount() {
    setState(() {
      _emailController.text = _demoAccountEmail;
      _passwordController.text = _demoAccountPassword;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } on AuthException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = describeAuthException(error));
      }
    } catch (error) {
      // gotrue only wraps what it recognises: a timeout, a malformed 2xx body or a
      // failure in the session listener escapes as something else, and without this
      // the button would just stop spinning with no message at all.
      if (mounted) {
        setState(() => _errorMessage = 'La connexion a échoué, réessayez.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dropping the app bar put the form under the status bar, and left its
    // icons in their light-on-dark style over a white screen.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: XefiBackdrop(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ScaleIn(
                          child: Center(child: XefiLockup(logoHeight: 30)),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          'Connexion',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (value) =>
                              (value == null || !value.contains('@'))
                              ? 'Email invalide'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Mot de passe',
                          ),
                          validator: (value) =>
                              (value == null || value.length < 6)
                              ? '6 caractères minimum'
                              : null,
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Text('Se connecter'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SignUpScreen(),
                                  ),
                                ),
                          child: const Text('Créer un compte'),
                        ),
                        const SizedBox(height: 28),
                        _DemoAccountCard(
                          onFill: _isSubmitting ? null : _fillDemoAccount,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoAccountCard extends StatelessWidget {
  const _DemoAccountCard({required this.onFill});

  final VoidCallback? onFill;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = textTheme.bodySmall?.copyWith(
      fontSize: 11,
      letterSpacing: 0.8,
      fontWeight: FontWeight.w600,
      color: AppColors.secondaryText.withValues(alpha: 0.75),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.black.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMPTE DE DÉMONSTRATION', style: labelStyle),
          const SizedBox(height: 10),
          // Selectable so the address can be copied rather than retyped, which
          // on a phone keyboard is where a demo login usually goes wrong.
          SelectableText(
            _demoAccountEmail,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            _demoAccountPassword,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Séances, parcours GPS, lieux et classement déjà remplis.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onFill,
              child: const Text('Remplir'),
            ),
          ),
        ],
      ),
    );
  }
}
