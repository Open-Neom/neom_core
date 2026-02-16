/// Progress information for vector indexing
class VectorIndexProgress {
  final int totalItems;
  final int processedItems;
  final int newIndexes;
  final int skippedItems;
  final int errorItems;
  final String currentStatus;
  final bool isComplete;
  final double progress;

  const VectorIndexProgress({
    required this.totalItems,
    required this.processedItems,
    required this.newIndexes,
    required this.skippedItems,
    required this.errorItems,
    required this.currentStatus,
    required this.isComplete,
    required this.progress,
  });
}