import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/domain/body_weight_range.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  static double? _parseWeightKg(String? rawValue) {
    if (rawValue == null) return null;
    return double.tryParse(rawValue.trim().replaceAll(',', '.'));
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nom obligatoire';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || !value.contains('@')) return 'Email invalide';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) return '6 caractères minimum';
    return null;
  }

  String? _validateWeightKg(String? value) {
    if (value == null || value.trim().isEmpty) return 'Poids obligatoire';
    final weightKg = _parseWeightKg(value);
    if (weightKg == null) return 'Poids invalide';
    if (!BodyWeightRange.contains(weightKg)) {
      return BodyWeightRange.invalidMessage;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final weightKg = _parseWeightKg(_weightController.text);
    if (weightKg == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            weightKg: weightKg,
          );
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = "La création du compte a échoué.");
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: Center(
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
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    validator: _validateName,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Mot de passe'),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Poids (kg)',
                      helperText:
                          'Utilisé pour estimer les calories de vos séances',
                    ),
                    validator: _validateWeightKg,
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
                        : const Text("S'inscrire"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
