
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDatabaseHelper {
  SupabaseDatabaseHelper._();

  static final instance = SupabaseDatabaseHelper._();

  final SupabaseClient _client = Supabase.instance.client;

  String get currentUserId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('Pengguna belum login.');
    }

    return user.id;
  }

  Future<List<Map<String, dynamic>>> getAssets(
      String userId,
      ) async {
    final rows = await _client
        .from('assets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<String>> getCustomCategories(
      String userId,
      ) async {
    final rows = await _client
        .from('custom_categories')
        .select('name')
        .eq('user_id', userId)
        .order('name');

    return rows.map((row) => row['name'] as String).toList();
  }

  Future<Map<String, dynamic>?> getUserProfile(
      String userId,
      ) async {
    return await _client
        .from('users')
        .select('id, name, email, profile_image_path')
        .eq('id', userId)
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> getAssetHistory(
      String userId,
      ) async {
    final rows = await _client
        .from('asset_history')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> addCustomCategory(
      String userId,
      String categoryName,
      ) async {
    await _client.from('custom_categories').insert({
      'user_id': userId,
      'name': categoryName.trim(),
    });
  }

  Future<int> addAsset(Map<String, dynamic> asset) async {
    final row = await _client
        .from('assets')
        .insert(asset)
        .select('id')
        .single();

    return (row['id'] as num).toInt();
  }

  Future<int> updateAsset(
      int assetId,
      String userId,
      Map<String, dynamic> changes,
      ) async {
    final rows = await _client
        .from('assets')
        .update(changes)
        .eq('id', assetId)
        .eq('user_id', userId)
        .select('id');

    return rows.length;
  }

  Future<int> deleteAsset(
      int assetId,
      String userId,
      ) async {
    final rows = await _client
        .from('assets')
        .delete()
        .eq('id', assetId)
        .eq('user_id', userId)
        .select('id');

    return rows.length;
  }

  Future<int> updateUserProfile({
    required String userId,
    required String name,
    String? imagePath,
  }) async {
    final changes = <String, dynamic>{
      'name': name.trim(),
    };

    if (imagePath != null) {
      changes['profile_image_path'] = imagePath;
    }

    final rows = await _client
        .from('users')
        .update(changes)
        .eq('id', userId)
        .select('id');

    return rows.length;
  }
}
