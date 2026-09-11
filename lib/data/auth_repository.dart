import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  /// [name] and [weightKg] travel as user metadata so the database trigger
  /// handle_new_user() can copy them into the profiles row it creates.
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required double weightKg,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'weight_kg': weightKg},
    );
  }

  Future<void> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  /// Deletes the signed-in account for good, then clears the local session.
  ///
  /// Removing an auth user needs the service role key, which must never ship
  /// inside the app, so the deletion happens in the Edge Function. It takes no
  /// arguments on purpose: the account to delete is the one the access token
  /// identifies, so the client cannot name anybody else's.
  ///
  /// The sign-out runs whatever the outcome. If the account is gone, the local
  /// session is now worthless; if the call failed, signing out is the safe
  /// place to leave someone who just asked to be deleted.
  Future<void> deleteAccount() async {
    try {
      await _client.functions.invoke(_deleteAccountFunction);
    } finally {
      await signOut();
    }
  }

  static const String _deleteAccountFunction = 'delete-account';
}
