abstract class GoogleAuthService {
  bool get isAuthenticated;

  String? get email;
  String? get displayName;
  String? get photoUrl;
  String? get idToken;

  Future<bool> signIn({List<String>? scopes});
  Future<void> signOut();
  Future<bool> refreshToken({List<String>? scopes});
  Future<String?> getValidAccessToken({List<String>? scopes, bool forceRefresh = false});
}
