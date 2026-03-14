/// SAIA job types that can be executed from the admin center.
enum SaiaJobType {
  domainContext('Contexto de Dominio', 'Genera snapshots de catálogo y creadores'),
  transparencyStats('Estadísticas de Transparencia', 'Calcula métricas agregadas de la plataforma'),
  userContexts('Contextos de Usuario', 'Genera contexto SAIA para cada usuario'),
  vectorEnrichment('Enriquecimiento de Vectores', 'Escanea releases sin sinopsis/resumen'),
  cacheCleanup('Limpieza de Caché', 'Elimina snapshots y contextos expirados'),
  fullPipeline('Pipeline Completo', 'Ejecuta todos los jobs en secuencia');

  final String displayName;
  final String description;
  const SaiaJobType(this.displayName, this.description);
}

/// Status of a SAIA job.
enum SaiaJobStatus {
  idle,
  running,
  completed,
  failed,
  cancelled,
}

/// Real-time progress for a running SAIA job.
class SaiaJobProgress {
  final SaiaJobType jobType;
  final SaiaJobStatus status;
  final int totalItems;
  final int processedItems;
  final int successItems;
  final int errorItems;
  final int skippedItems;
  final String currentStep;

  const SaiaJobProgress({
    required this.jobType,
    this.status = SaiaJobStatus.idle,
    this.totalItems = 0,
    this.processedItems = 0,
    this.successItems = 0,
    this.errorItems = 0,
    this.skippedItems = 0,
    this.currentStep = '',
  });

  double get progress => totalItems > 0 ? processedItems / totalItems : 0.0;
  int get pendingItems => totalItems - processedItems;
  bool get isRunning => status == SaiaJobStatus.running;
  bool get isComplete => status == SaiaJobStatus.completed || status == SaiaJobStatus.failed;
}

/// Final result of a completed SAIA job.
class SaiaJobResult {
  final SaiaJobType jobType;
  final bool success;
  final String message;
  final int totalItems;
  final int successItems;
  final int errorItems;
  final int skippedItems;

  const SaiaJobResult({
    required this.jobType,
    required this.success,
    required this.message,
    this.totalItems = 0,
    this.successItems = 0,
    this.errorItems = 0,
    this.skippedItems = 0,
  });

  String get summary => '${jobType.displayName}: $message '
      '($successItems OK, $errorItems errores, $skippedItems omitidos)';
}

/// Dashboard overview for the admin center.
class SaiaJobDashboard {
  final int pendingVectors;
  final int totalUsers;
  final int totalReleases;
  final int cachedUserContexts;
  final bool hasCachedDomain;

  const SaiaJobDashboard({
    this.pendingVectors = 0,
    this.totalUsers = 0,
    this.totalReleases = 0,
    this.cachedUserContexts = 0,
    this.hasCachedDomain = false,
  });
}
