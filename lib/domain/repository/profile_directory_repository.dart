import '../model/app_profile.dart';
import 'profile_repository.dart';

/// Existing directory helpers without exposing Firestore QuerySnapshot types.
abstract class ProfileDirectoryRepository implements ProfileRepository {
  Future<AppProfile?> getBySlug(String slug);
  Future<List<AppProfile>> searchByName(String query, {int limit = 20});
}
