import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns a GoTrue failure into something a French-speaking user can act on.
///
/// [AuthException.message] is written in English by the auth server and leaks
/// implementation vocabulary ("Invalid login credentials"), so it is never shown
/// as-is. Matching happens on [AuthException.code] first, which is stable, and
/// falls back to the message text for the servers that do not send one yet.
String describeAuthException(AuthException error) {
  final code = error.code;
  if (code != null) {
    final knownMessage = _messagesByCode[code];
    if (knownMessage != null) {
      return knownMessage;
    }
  }

  final message = error.message.toLowerCase();
  for (final entry in _messagesByMessageFragment.entries) {
    if (message.contains(entry.key)) {
      return entry.value;
    }
  }

  return _fallbackMessage;
}

const String _fallbackMessage =
    "Une erreur est survenue, réessayez dans un instant.";

const Map<String, String> _messagesByCode = {
  'invalid_credentials': 'Email ou mot de passe incorrect.',
  'email_not_confirmed':
      "Votre email n'est pas encore confirmé. Cliquez sur le lien reçu par mail.",
  'user_already_exists': 'Un compte existe déjà avec cet email.',
  'email_exists': 'Un compte existe déjà avec cet email.',
  'weak_password': 'Mot de passe trop faible : 6 caractères minimum.',
  'over_request_rate_limit':
      'Trop de tentatives. Patientez une minute avant de réessayer.',
  'over_email_send_rate_limit':
      "Trop d'emails envoyés. Patientez avant de réessayer.",
  'validation_failed': 'Email ou mot de passe invalide.',
  'user_not_found': 'Aucun compte ne correspond à cet email.',
  'signup_disabled': "Les inscriptions sont désactivées pour le moment.",
};

const Map<String, String> _messagesByMessageFragment = {
  'invalid login credentials': 'Email ou mot de passe incorrect.',
  'email not confirmed':
      "Votre email n'est pas encore confirmé. Cliquez sur le lien reçu par mail.",
  'already registered': 'Un compte existe déjà avec cet email.',
  'already been registered': 'Un compte existe déjà avec cet email.',
  'password should be at least':
      'Mot de passe trop faible : 6 caractères minimum.',
  'unable to validate email address': "Le format de l'email est invalide.",
  'rate limit': 'Trop de tentatives. Patientez une minute avant de réessayer.',
  'for security purposes':
      'Trop de tentatives. Patientez une minute avant de réessayer.',
};
