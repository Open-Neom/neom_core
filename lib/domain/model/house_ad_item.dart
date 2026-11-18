import '../../utils/enums/ad_media_format.dart';
import '../../utils/enums/ad_placement.dart';
import '../../utils/enums/app_in_use.dart';

/// Represents an internal platform advertisement ("House Ad") or direct campaign
/// inviting users to discover menu features, tools, events, or subscriptions
/// tailored to the active [AppInUse].
class HouseAdItem {
  final String id;
  final List<AppInUse> targetApps;
  final List<AdPlacement> placements;
  final AdMediaFormat mediaFormat;

  final String badgeLabel;
  final String title;
  final String subtitle;
  final String ctaLabel;

  /// Internal route (`AppRouteConstants.*`) navigated via `Sint.toNamed`.
  final String ctaRoute;

  /// Optional external URL when promoting an external landing page.
  final String externalUrl;

  /// Optional remote image, local asset, promo loop video, or MP3 spot URL.
  final String imgUrl;
  final String assetPath;
  final String videoUrl;
  final String audioUrl;

  /// Short voiced script used for Read-Aloud / TTS audio spots when [audioUrl]
  /// is empty, or displayed as transcript caption during audio playback.
  final String narrationScript;

  /// ARGB color hex (`0xFF...`) styling the card accent & CTA button.
  final int accentColorHex;

  /// Semantic icon identifier resolved by UI widgets (`book`, `rocket`, `daw`, etc.).
  final String iconKey;

  /// Whether tapping the CTA requires authentication (`AuthGuard.protect`).
  final bool requiresAuth;

  /// Whether this house ad targets creators/authors specifically.
  final bool creatorsOnly;

  /// Whether this item is an upgrade/subscription promo (hidden for paid users).
  final bool hideForSubscribers;

  /// Relative weight/priority (higher surfaces first before graduation).
  final int priority;

  /// Optional campaign expiration (e.g. seasonal events like FIL Guadalajara).
  final DateTime? expiresAt;

  /// Seconds before a video/audio break using this item allows skipping.
  final int skipAfterSeconds;

  const HouseAdItem({
    required this.id,
    required this.targetApps,
    this.placements = const [
      AdPlacement.feedInline,
      AdPlacement.feedFeatureCarousel,
      AdPlacement.feedSidebarWeb,
    ],
    this.mediaFormat = AdMediaFormat.nativeCard,
    required this.badgeLabel,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    this.ctaRoute = '',
    this.externalUrl = '',
    this.imgUrl = '',
    this.assetPath = '',
    this.videoUrl = '',
    this.audioUrl = '',
    this.narrationScript = '',
    this.accentColorHex = 0xFF00879E,
    this.iconKey = 'sparkles',
    this.requiresAuth = false,
    this.creatorsOnly = false,
    this.hideForSubscribers = false,
    this.priority = 50,
    this.expiresAt,
    this.skipAfterSeconds = 5,
  });

  bool isActiveAt(DateTime now) {
    if (expiresAt == null) return true;
    return now.isBefore(expiresAt!);
  }

  bool matchesApp(AppInUse app) {
    return targetApps.isEmpty || targetApps.contains(app);
  }

  bool matchesPlacement(AdPlacement placement) {
    return placements.isEmpty || placements.contains(placement);
  }

  factory HouseAdItem.fromJson(Map<String, dynamic> json) {
    final rawApps = (json['targetApps'] as List<dynamic>?) ?? const [];
    final rawPlacements = (json['placements'] as List<dynamic>?) ?? const [];
    final rawExpires = json['expiresAt'];

    return HouseAdItem(
      id: (json['id'] ?? '').toString(),
      targetApps: rawApps
          .map(
            (name) => AppInUse.values.firstWhere(
              (e) => e.name == name.toString(),
              orElse: () => AppInUse.e,
            ),
          )
          .toList(),
      placements: rawPlacements
          .map(
            (name) => AdPlacement.values.firstWhere(
              (e) => e.name == name.toString(),
              orElse: () => AdPlacement.feedInline,
            ),
          )
          .toList(),
      mediaFormat: AdMediaFormat.values.firstWhere(
        (e) => e.name == (json['mediaFormat'] ?? 'nativeCard').toString(),
        orElse: () => AdMediaFormat.nativeCard,
      ),
      badgeLabel: (json['badgeLabel'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      ctaLabel: (json['ctaLabel'] ?? '').toString(),
      ctaRoute: (json['ctaRoute'] ?? '').toString(),
      externalUrl: (json['externalUrl'] ?? '').toString(),
      imgUrl: (json['imgUrl'] ?? '').toString(),
      assetPath: (json['assetPath'] ?? '').toString(),
      videoUrl: (json['videoUrl'] ?? '').toString(),
      audioUrl: (json['audioUrl'] ?? '').toString(),
      narrationScript: (json['narrationScript'] ?? '').toString(),
      accentColorHex: json['accentColorHex'] is int
          ? json['accentColorHex'] as int
          : int.tryParse((json['accentColorHex'] ?? '').toString()) ??
                0xFF00879E,
      iconKey: (json['iconKey'] ?? 'sparkles').toString(),
      requiresAuth: json['requiresAuth'] == true,
      creatorsOnly: json['creatorsOnly'] == true,
      hideForSubscribers: json['hideForSubscribers'] == true,
      priority: (json['priority'] as num?)?.toInt() ?? 50,
      expiresAt: rawExpires is int
          ? DateTime.fromMillisecondsSinceEpoch(rawExpires)
          : (rawExpires is String ? DateTime.tryParse(rawExpires) : null),
      skipAfterSeconds: (json['skipAfterSeconds'] as num?)?.toInt() ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'targetApps': targetApps.map((e) => e.name).toList(),
      'placements': placements.map((e) => e.name).toList(),
      'mediaFormat': mediaFormat.name,
      'badgeLabel': badgeLabel,
      'title': title,
      'subtitle': subtitle,
      'ctaLabel': ctaLabel,
      'ctaRoute': ctaRoute,
      'externalUrl': externalUrl,
      'imgUrl': imgUrl,
      'assetPath': assetPath,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'narrationScript': narrationScript,
      'accentColorHex': accentColorHex,
      'iconKey': iconKey,
      'requiresAuth': requiresAuth,
      'creatorsOnly': creatorsOnly,
      'hideForSubscribers': hideForSubscribers,
      'priority': priority,
      if (expiresAt != null) 'expiresAt': expiresAt!.millisecondsSinceEpoch,
      'skipAfterSeconds': skipAfterSeconds,
    };
  }
}
