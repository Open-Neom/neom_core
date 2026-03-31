import '../../utils/enums/media_item_type.dart';

/// Common interface for anything that can be played, displayed in a queue,
/// or shown in a shelf/card.
///
/// Both [AppReleaseItem] (internal content) and [AppMediaItem] (external sources)
/// implement this. The audio player, queue, and UI components work with
/// [PlayableItem] instead of checking which concrete type they have.
///
/// This eliminates the need for AppMediaItemMapper for internal content
/// and removes all the `if (item is AppReleaseItem) ... else if (item is AppMediaItem)` checks.
abstract class PlayableItem {
  // ── Identity ──
  String get id;
  String get name;
  String? get description;
  String get slug;

  // ── Media ──
  String get streamUrl;         // URL for streaming/playback
  String get imgUrl;            // Cover image
  String get previewUrl;        // Short preview URL (30s clip, first pages, etc.)
  MediaItemType? get mediaType; // song, pdf, video, podcast, etc.
  int get duration;             // Seconds (audio/video) or pages (books)
  bool get isAudioContent;      // Can be played in audio player
  bool get isBookContent;       // Can be opened in PDF viewer

  // ── Ownership ──
  String get ownerName;
  String? get ownerId;

  // ── Metadata ──
  List<String>? get categories;
  List<String>? get galleryUrls;
  String? get language;
  int? get publishedYear;
  int get state;                // 0-5 user state (saved, etc.)

  // ── Display helpers ──
  String get displayDuration {
    if (isBookContent) return '$duration pág.';
    final min = duration ~/ 60;
    final sec = duration % 60;
    if (min == 0) return '${sec}s';
    return sec == 0 ? '${min}m' : '${min}:${sec.toString().padLeft(2, '0')}';
  }

  /// Whether this item is from the platform (AppReleaseItem)
  /// or from an external source (AppMediaItem from Spotify, YouTube, etc.)
  bool get isInternal;
}
