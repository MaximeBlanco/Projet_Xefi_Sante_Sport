import 'package:cross_file/cross_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  static const _avatarBucket = 'avatars';

  final SupabaseClient _client;

  Future<Profile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return Profile.fromJson(row);
  }

  Future<void> updateName({
    required String userId,
    required String name,
  }) {
    return _client
        .from('profiles')
        .update({'name': name})
        .eq('id', userId);
  }

  Future<void> updateWeight({
    required String userId,
    required double weightKg,
  }) {
    return _client
        .from('profiles')
        .update({'weight_kg': weightKg})
        .eq('id', userId);
  }

  /// Uploads the picture and stores its public URL on the profile, returning
  /// that URL.
  ///
  /// The object always lives at the same path so a user keeps exactly one
  /// avatar instead of accumulating every picture they ever picked. That makes
  /// the URL stable, which would serve a stale image from cache, so a version
  /// query parameter is appended to break it.
  ///
  /// The picture travels as bytes rather than as a `dart:io` file: the web
  /// build has no filesystem, and an `XFile` is what the picker hands back on
  /// every platform anyway.
  Future<String> uploadAvatar({
    required String userId,
    required XFile file,
    required DateTime uploadedAt,
  }) async {
    final objectPath = '$userId/avatar${_extensionOf(file.name)}';

    await _client.storage.from(_avatarBucket).uploadBinary(
          objectPath,
          await file.readAsBytes(),
          fileOptions: FileOptions(
            upsert: true,
            // Storage guesses from the path otherwise, and a browser-picked
            // file carries a blob URL with no extension to guess from.
            contentType: file.mimeType,
          ),
        );

    final publicUrl = _client.storage.from(_avatarBucket).getPublicUrl(
          objectPath,
        );
    final versionedUrl =
        '$publicUrl?v=${uploadedAt.millisecondsSinceEpoch}';

    await _client
        .from('profiles')
        .update({'avatar_url': versionedUrl})
        .eq('id', userId);

    return versionedUrl;
  }

  String _extensionOf(String name) {
    final lastDot = name.lastIndexOf('.');
    if (lastDot == -1 || lastDot == name.length - 1) return '.jpg';
    return name.substring(lastDot).toLowerCase();
  }
}
