/// Abstract interface for cloud drive operations (SAIA-facing).
///
/// Simplified interface for AI assistant consumption.
/// Implemented by neom_cloud's GoogleDriveController.
/// Consumed by neom_ia (SAIA) via Sint DI.
abstract class CloudDriveService {
  bool get isAuthenticated;

  /// List files from the user's cloud drive.
  Future<List<Map<String, dynamic>>> listDriveFiles({int limit = 20});

  /// Get a shareable link for a file.
  Future<String> getDriveShareableLink(String fileId);
}
