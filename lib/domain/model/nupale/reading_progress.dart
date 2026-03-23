import 'nupale_session.dart';

class ReadingProgress {

  final String itemId;
  final String itemName;
  final String itemImgUrl;
  final String itemOwnerName;
  final int maxPageReached;
  final int totalPages;
  final int sessionCount;
  final int totalReadingTime;
  final int totalPagesRead;
  final Set<int> pagesViewed;
  final int lastReadTime;

  ReadingProgress({
    required this.itemId,
    required this.itemName,
    this.itemImgUrl = '',
    this.itemOwnerName = '',
    this.maxPageReached = 0,
    this.totalPages = 0,
    this.sessionCount = 0,
    this.totalReadingTime = 0,
    this.totalPagesRead = 0,
    this.pagesViewed = const {},
    this.lastReadTime = 0,
  });

  double get completionPercent => totalPages > 0
      ? (maxPageReached / totalPages).clamp(0.0, 1.0)
      : 0.0;

  bool get hasReReads => sessionCount > 1;

  bool get isComplete => completionPercent >= 0.9;

  factory ReadingProgress.fromSessions(String itemId, List<NupaleSession> sessions) {
    if (sessions.isEmpty) {
      return ReadingProgress(itemId: itemId, itemName: '');
    }

    String itemName = '';
    int maxPage = 0;
    int totalPages = 0;
    int totalTime = 0;
    int totalPagesRead = 0;
    int lastRead = 0;
    Set<int> allPagesViewed = {};

    for (final session in sessions) {
      if (session.itemName.isNotEmpty) itemName = session.itemName;
      if (session.totalPages > totalPages) totalPages = session.totalPages;
      if (session.createdTime > lastRead) lastRead = session.createdTime;

      totalPagesRead += session.nupale;

      for (final entry in session.pagesDuration.entries) {
        totalTime += entry.value;
        allPagesViewed.add(entry.key);
        if (entry.key > maxPage) maxPage = entry.key;
      }

      for (final pageKey in session.pageViews.keys) {
        allPagesViewed.add(pageKey);
        if (pageKey > maxPage) maxPage = pageKey;
      }
    }

    return ReadingProgress(
      itemId: itemId,
      itemName: itemName,
      maxPageReached: maxPage,
      totalPages: totalPages,
      sessionCount: sessions.length,
      totalReadingTime: totalTime,
      totalPagesRead: totalPagesRead,
      pagesViewed: allPagesViewed,
      lastReadTime: lastRead,
    );
  }

  ReadingProgress copyWith({
    String? itemImgUrl,
    String? itemOwnerName,
  }) {
    return ReadingProgress(
      itemId: itemId,
      itemName: itemName,
      itemImgUrl: itemImgUrl ?? this.itemImgUrl,
      itemOwnerName: itemOwnerName ?? this.itemOwnerName,
      maxPageReached: maxPageReached,
      totalPages: totalPages,
      sessionCount: sessionCount,
      totalReadingTime: totalReadingTime,
      totalPagesRead: totalPagesRead,
      pagesViewed: pagesViewed,
      lastReadTime: lastReadTime,
    );
  }

  @override
  String toString() {
    return 'ReadingProgress{itemId: $itemId, itemName: $itemName, maxPage: $maxPageReached/$totalPages, sessions: $sessionCount, percent: ${(completionPercent * 100).toStringAsFixed(0)}%}';
  }
}
