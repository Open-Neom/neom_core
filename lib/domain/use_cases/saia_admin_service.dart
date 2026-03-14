import '../model/saia/saia_job_progress.dart';

/// Abstract admin service for SAIA data-building jobs.
///
/// Restricted to superAdmin role. Implementation lives in neom_corpus.
/// Registered via DI in root_binding and consumed by SettingsController.
abstract class SaiaAdminService {

  /// Callback for real-time progress updates
  void Function(SaiaJobProgress)? onProgressUpdate;

  /// Whether any job is currently running
  bool get hasRunningJob;

  /// Cancel the currently running job
  void cancelJob();

  /// Build dashboard summary showing pending work
  Future<SaiaJobDashboard> buildDashboard();

  /// Build and cache the platform domain context
  Future<SaiaJobResult> runDomainContextJob();

  /// Build aggregated transparency stats
  Future<SaiaJobResult> runTransparencyStatsJob();

  /// Build and cache user contexts for all users
  Future<SaiaJobResult> runUserContextsJob({int batchSize = 20, bool forceRebuild = false});

  /// Scan for vectors missing enrichment data
  Future<SaiaJobResult> runVectorEnrichmentScan();

  /// Clean up expired SAIA caches
  Future<SaiaJobResult> runCacheCleanup();

  /// Run all jobs in sequence
  Future<SaiaJobResult> runFullPipeline({int batchSize = 20});
}
