/// Result of a vector index job
class VectorIndexJobResult {
  final bool success;
  final String message;
  final int totalItems;
  final int newIndexes;
  final int skipped;
  final int errors;

  const VectorIndexJobResult({
    required this.success,
    required this.message,
    required this.totalItems,
    required this.newIndexes,
    required this.skipped,
    required this.errors,
  });

  @override
  String toString() =>
      'VectorIndexJobResult(success: $success, total: $totalItems, new: $newIndexes, skipped: $skipped, errors: $errors)';
}
