
import '../model/vector_index/vector_index_job_result.dart';
import '../model/vector_index/vector_index_progress.dart';

/// Admin service for batch vector indexing operations
///
/// Designed to be run from the admin panel to:
/// 1. Scan all AppReleaseItems in Firestore
/// 2. Find items not yet in neomVectors collection
/// 3. Download PDF and extract text (if available)
/// 4. Generate embeddings via Gemini API
/// 5. Save vectors to Firestore
abstract class VectorIndexAdminService {

  bool get isGeminiEnabled;
  void Function(VectorIndexProgress)? onProgressUpdate;

  void initialize({required String geminiApiKey, extractContent = true});

  /// Run the full vector index update job
  ///
  /// 1. Fetch all AppReleaseItems IDs
  /// 2. Check which are missing from neomVectors
  /// 3. Generate vectors for missing items
  /// 4. Save to Firestore
  Future<VectorIndexJobResult> runIndexJob({int batchSize = 20, bool forceReindex = false,});

  /// Cancel the running job
  void cancelJob();
  /// Get current job status
  VectorIndexProgress getCurrentProgress();
}
