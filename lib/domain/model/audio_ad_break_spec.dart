import 'dart:convert';

/// Self-contained specification for an audio ad break (with optional companion
/// video/artwork and VAST 4.x tracking beacons) played inside
/// `NeomAudioHandler` (ephemeral single-player queue item) or
/// `BookNarrationController` (Read-Aloud page break).
class AudioAdBreakSpec {
  static const String extraIsAdKey = 'isAd';
  static const String extraEphemeralKey = 'ephemeralPlayback';
  static const String extraSpecJsonKey = 'adBreakSpecJson';
  static const String extraSkipAfterSecondsKey = 'skipAfterSeconds';

  final String id;
  final String title;
  final String advertiser;
  final String subtitle;

  /// Direct MP3/AAC stream URL (from VAST `<MediaFile>`, Sponsor, or House Ad).
  final String audioUrl;

  bool get hasPlayableAudio => audioUrl.trim().isNotEmpty;

  /// Spoken narration fallback when [audioUrl] is empty (e.g. Read-Aloud TTS).
  final String narrationScript;

  /// Foreground companion creative (image or muted synced video).
  final String companionImgUrl;
  final String companionVideoUrl;

  /// Click-through destination (`ctaRoute` in-app or `ctaUrl` external).
  final String ctaRoute;
  final String ctaUrl;
  final String ctaLabel;

  final int durationSeconds;
  final int skipAfterSeconds;
  final int accentColorHex;
  final bool isHouseAd;

  /// VAST 4.x HTTP tracking pixel URLs fired automatically during playback.
  final List<String> vastImpressionUrls;
  final List<String> vastFirstQuartileUrls;
  final List<String> vastMidpointUrls;
  final List<String> vastThirdQuartileUrls;
  final List<String> vastCompleteUrls;
  final List<String> vastSkipUrls;
  final List<String> vastClickTrackingUrls;

  const AudioAdBreakSpec({
    required this.id,
    required this.title,
    required this.advertiser,
    this.subtitle = '',
    this.audioUrl = '',
    this.narrationScript = '',
    this.companionImgUrl = '',
    this.companionVideoUrl = '',
    this.ctaRoute = '',
    this.ctaUrl = '',
    this.ctaLabel = 'Conocer más',
    this.durationSeconds = 15,
    this.skipAfterSeconds = 10,
    this.accentColorHex = 0xFF00879E,
    this.isHouseAd = false,
    this.vastImpressionUrls = const [],
    this.vastFirstQuartileUrls = const [],
    this.vastMidpointUrls = const [],
    this.vastThirdQuartileUrls = const [],
    this.vastCompleteUrls = const [],
    this.vastSkipUrls = const [],
    this.vastClickTrackingUrls = const [],
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'advertiser': advertiser,
      'subtitle': subtitle,
      'audioUrl': audioUrl,
      'narrationScript': narrationScript,
      'companionImgUrl': companionImgUrl,
      'companionVideoUrl': companionVideoUrl,
      'ctaRoute': ctaRoute,
      'ctaUrl': ctaUrl,
      'ctaLabel': ctaLabel,
      'durationSeconds': durationSeconds,
      'skipAfterSeconds': skipAfterSeconds,
      'accentColorHex': accentColorHex,
      'isHouseAd': isHouseAd,
      'vastImpressionUrls': vastImpressionUrls,
      'vastFirstQuartileUrls': vastFirstQuartileUrls,
      'vastMidpointUrls': vastMidpointUrls,
      'vastThirdQuartileUrls': vastThirdQuartileUrls,
      'vastCompleteUrls': vastCompleteUrls,
      'vastSkipUrls': vastSkipUrls,
      'vastClickTrackingUrls': vastClickTrackingUrls,
    };
  }

  factory AudioAdBreakSpec.fromJson(Map<String, dynamic> json) {
    List<String> readList(String key) {
      final raw = json[key];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return const [];
    }

    return AudioAdBreakSpec(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      advertiser: (json['advertiser'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      audioUrl: (json['audioUrl'] ?? '').toString(),
      narrationScript: (json['narrationScript'] ?? '').toString(),
      companionImgUrl: (json['companionImgUrl'] ?? '').toString(),
      companionVideoUrl: (json['companionVideoUrl'] ?? '').toString(),
      ctaRoute: (json['ctaRoute'] ?? '').toString(),
      ctaUrl: (json['ctaUrl'] ?? '').toString(),
      ctaLabel: (json['ctaLabel'] ?? 'Conocer más').toString(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 15,
      skipAfterSeconds: (json['skipAfterSeconds'] as num?)?.toInt() ?? 10,
      accentColorHex: (json['accentColorHex'] as num?)?.toInt() ?? 0xFF00879E,
      isHouseAd: json['isHouseAd'] == true,
      vastImpressionUrls: readList('vastImpressionUrls'),
      vastFirstQuartileUrls: readList('vastFirstQuartileUrls'),
      vastMidpointUrls: readList('vastMidpointUrls'),
      vastThirdQuartileUrls: readList('vastThirdQuartileUrls'),
      vastCompleteUrls: readList('vastCompleteUrls'),
      vastSkipUrls: readList('vastSkipUrls'),
      vastClickTrackingUrls: readList('vastClickTrackingUrls'),
    );
  }

  /// Builds `MediaItem.extras` compatible with `NeomAudioHandler`'s single-player
  /// ephemeral pipeline (`ephemeralPlayback: true` + `isAd: true`).
  Map<String, dynamic> toMediaItemExtras() {
    return <String, dynamic>{
      'url': audioUrl,
      extraEphemeralKey: true,
      extraIsAdKey: true,
      extraSkipAfterSecondsKey: skipAfterSeconds,
      extraSpecJsonKey: jsonEncode(toJson()),
    };
  }

  static AudioAdBreakSpec? fromMediaItemExtras(Map<String, dynamic>? extras) {
    if (extras == null || extras[extraIsAdKey] != true) return null;
    final raw = extras[extraSpecJsonKey];
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return AudioAdBreakSpec.fromJson(decoded);
        }
      } catch (_) {}
    }
    return AudioAdBreakSpec(
      id: (extras['adId'] ?? 'ad').toString(),
      title: (extras['title'] ?? 'Anuncio').toString(),
      advertiser: (extras['advertiser'] ?? '').toString(),
      audioUrl: (extras['url'] ?? '').toString(),
      skipAfterSeconds:
          (extras[extraSkipAfterSecondsKey] as num?)?.toInt() ?? 10,
    );
  }
}
