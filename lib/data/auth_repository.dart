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
}
