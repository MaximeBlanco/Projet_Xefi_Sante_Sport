import 'package:flutter_test/flutter_test.dart';
import 'package:monapp/core/localization/auth_error_messages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('describeAuthException', () {
    test('translates the code GoTrue sends for a wrong password', () {
      final message = describeAuthException(
        const AuthException('Invalid login credentials',
            code: 'invalid_credentials'),
      );

      expect(message, 'Email ou mot de passe incorrect.');
    });

    test('translates a duplicate signup', () {
      final message = describeAuthException(
        const AuthException('User already registered',
            code: 'user_already_exists'),
      );

      expect(message, 'Un compte existe déjà avec cet email.');
    });

    // Older GoTrue releases answer without a code, and the hosted project may
    // not be on the same version as the local stack.
    test('falls back to the English text when no code is sent', () {
      final message = describeAuthException(
        const AuthException('Invalid login credentials'),
      );

      expect(message, 'Email ou mot de passe incorrect.');
    });

    test('recognises an unconfirmed email from its message alone', () {
      final message = describeAuthException(
        const AuthException('Email not confirmed'),
      );

      expect(message, contains("n'est pas encore confirmé"));
    });

    test('never leaks an untranslated server message to the user', () {
      final message = describeAuthException(
        const AuthException('Some brand new server-side wording',
            code: 'unheard_of_code'),
      );

      expect(message, 'Une erreur est survenue, réessayez dans un instant.');
    });
  });
}
