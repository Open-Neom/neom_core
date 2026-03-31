/// Raw session data for fan segmentation input
class FanSessionData {
  final String itemId;
  final int engagement; // pages or seconds
  final String monthKey; // "2026-03" for month grouping

  const FanSessionData({
    required this.itemId,
    required this.engagement,
    required this.monthKey,
  });
}
