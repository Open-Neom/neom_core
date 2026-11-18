import '../../app_config.dart';
import '../../utils/enums/app_in_use.dart';

/// Market-segment monetization & internal discovery policy tailored per [AppInUse].
///
/// Each Open Neom platform serves a distinct audience, session psychology,
/// eCPM vertical, and internal feature funnel:
/// - [AppInUse.e] **EMXI**: Long-form readers, independent authors & cultural backers.
/// - [AppInUse.g] **Gigmeout**: Indie musicians, producers, venues & music listeners.
/// - [AppInUse.c] **Cyberneom**: Meditation, binaural frequencies, sleep & wellness.
/// - [AppInUse.i] **Itzli**: B2B/SaaS AI power users, researchers & developers.
/// - [AppInUse.b] **Blup**: Offline-first BLE/Wi-Fi mesh, urban mobility & SOS safety.
/// - [AppInUse.o] **Open Neom**: Cross-platform creator & community hub.
class AdMarketPolicy {
  final AppInUse app;
  final String segmentName;

  /// Target share (`0.0`–`1.0`) of eligible ad slots allocated to external
  /// programmatic ads (Google AdMob / AdSense / GPT / VAST). The complement
  /// (`1 - externalAdShare`) is reserved for internal platform [HouseAdItem]s.
  final double externalAdShare;

  /// Organic feed posts between inline ad/promo turns.
  final int feedPostsPerInlineAd;

  /// Organic feed posts between 3-card horizontal menu feature carousels.
  final int feedPostsPerFeatureCarousel;

  /// Page turns before triggering a visual/video reader page-break modal.
  final int readerPagesPerAdBreak;

  /// Minimum seconds between two reader page-break modals.
  final int readerMinCooldownSeconds;

  /// Narrated pages before playing a Read-Aloud audio/TTS break.
  final int narrationPagesPerAdBreak;

  /// Non-ad tracks completed before inserting an ephemeral mid-roll audio ad.
  final int audioTracksPerAdBreak;

  /// Minimum seconds between two audio mid-roll ad breaks.
  final int audioMinCooldownSeconds;

  /// Whether mid-roll audio breaks are permitted during queue playback.
  /// Disabled by default in meditation/sleep (`Cyberneom`) and emergency/mesh (`Blup`).
  final bool allowAudioMidRoll;

  /// Critical routes where ad overlays/slots must never render (e.g. `/blupSos`).
  final List<String> blockedRoutes;

  const AdMarketPolicy({
    required this.app,
    required this.segmentName,
    required this.externalAdShare,
    required this.feedPostsPerInlineAd,
    required this.feedPostsPerFeatureCarousel,
    required this.readerPagesPerAdBreak,
    required this.readerMinCooldownSeconds,
    required this.narrationPagesPerAdBreak,
    required this.audioTracksPerAdBreak,
    required this.audioMinCooldownSeconds,
    required this.allowAudioMidRoll,
    this.blockedRoutes = const [],
  });

  /// Resolves the active [AdMarketPolicy] for `AppConfig.instance.appInUse`,
  /// honoring per-app (`adConfig.apps.<app>.*`) and global (`adConfig.*`)
  /// remote Firestore overrides.
  static AdMarketPolicy get current => forApp(
    AppConfig.instance.appInUse,
    remoteAdConfig: AppConfig.instance.appInfo.adConfig,
  );

  static AdMarketPolicy forApp(
    AppInUse app, {
    Map<String, dynamic> remoteAdConfig = const {},
  }) {
    final base = _defaultsFor(app);
    if (remoteAdConfig.isEmpty) return base;

    Map<String, dynamic> appMap = const {};
    final apps = remoteAdConfig['apps'];
    if (apps is Map && apps[app.name] is Map) {
      appMap = Map<String, dynamic>.from(apps[app.name] as Map);
    }

    num? pickNum(String key) {
      final perApp = appMap[key];
      if (perApp is num) return perApp;
      final global = remoteAdConfig[key];
      if (global is num) return global;
      return null;
    }

    bool? pickBool(String key) {
      final perApp = appMap[key];
      if (perApp is bool) return perApp;
      final global = remoteAdConfig[key];
      if (global is bool) return global;
      return null;
    }

    final extShare = pickNum('externalAdShare');
    final feedInline = pickNum('feedPostsPerInlineAd');
    final feedCarousel = pickNum('feedPostsPerFeatureCarousel');
    final readerPages = pickNum('readerPagesPerAdBreak');
    final readerCooldown = pickNum('readerMinCooldownSeconds');
    final narrationPages = pickNum('narrationPagesPerAdBreak');
    final audioTracks = pickNum('audioTracksPerAdBreak');
    final audioCooldown = pickNum('audioMinCooldownSeconds');
    final allowMidRoll = pickBool('allowAudioMidRoll');

    return AdMarketPolicy(
      app: app,
      segmentName: base.segmentName,
      externalAdShare: extShare != null
          ? extShare.toDouble().clamp(0.0, 1.0)
          : base.externalAdShare,
      feedPostsPerInlineAd: feedInline != null && feedInline >= 3
          ? feedInline.toInt()
          : base.feedPostsPerInlineAd,
      feedPostsPerFeatureCarousel: feedCarousel != null && feedCarousel >= 5
          ? feedCarousel.toInt()
          : base.feedPostsPerFeatureCarousel,
      readerPagesPerAdBreak: readerPages != null && readerPages >= 3
          ? readerPages.toInt()
          : base.readerPagesPerAdBreak,
      readerMinCooldownSeconds: readerCooldown != null && readerCooldown >= 60
          ? readerCooldown.toInt()
          : base.readerMinCooldownSeconds,
      narrationPagesPerAdBreak: narrationPages != null && narrationPages >= 3
          ? narrationPages.toInt()
          : base.narrationPagesPerAdBreak,
      audioTracksPerAdBreak: audioTracks != null && audioTracks >= 2
          ? audioTracks.toInt()
          : base.audioTracksPerAdBreak,
      audioMinCooldownSeconds: audioCooldown != null && audioCooldown >= 60
          ? audioCooldown.toInt()
          : base.audioMinCooldownSeconds,
      allowAudioMidRoll: allowMidRoll ?? base.allowAudioMidRoll,
      blockedRoutes: base.blockedRoutes,
    );
  }

  static AdMarketPolicy _defaultsFor(AppInUse app) {
    return switch (app) {
      AppInUse.e => const AdMarketPolicy(
        app: AppInUse.e,
        segmentName: 'Lectura Digital, Editorial Independiente y Fondeos Culturales',
        externalAdShare: 0.65,
        feedPostsPerInlineAd: 6,
        feedPostsPerFeatureCarousel: 10,
        readerPagesPerAdBreak: 12,
        readerMinCooldownSeconds: 300,
        narrationPagesPerAdBreak: 8,
        audioTracksPerAdBreak: 5,
        audioMinCooldownSeconds: 480,
        allowAudioMidRoll: true,
      ),
      AppInUse.g => const AdMarketPolicy(
        app: AppInUse.g,
        segmentName: 'Música Independiente, Producción DAW, Estudios y Booking',
        externalAdShare: 0.75,
        feedPostsPerInlineAd: 5,
        feedPostsPerFeatureCarousel: 10,
        readerPagesPerAdBreak: 10,
        readerMinCooldownSeconds: 300,
        narrationPagesPerAdBreak: 8,
        audioTracksPerAdBreak: 4,
        audioMinCooldownSeconds: 420,
        allowAudioMidRoll: true,
      ),
      AppInUse.c => const AdMarketPolicy(
        app: AppInUse.c,
        segmentName: 'Meditación, Frecuencias Binaurales, Sueño y Neuro-Bienestar',
        externalAdShare: 0.70,
        feedPostsPerInlineAd: 6,
        feedPostsPerFeatureCarousel: 10,
        readerPagesPerAdBreak: 14,
        readerMinCooldownSeconds: 420,
        narrationPagesPerAdBreak: 12,
        audioTracksPerAdBreak: 8,
        audioMinCooldownSeconds: 1500,
        allowAudioMidRoll: false,
      ),
      AppInUse.i => const AdMarketPolicy(
        app: AppInUse.i,
        segmentName: 'IA Soberana, Productividad B2B/SaaS, Código e Investigación',
        externalAdShare: 0.75,
        feedPostsPerInlineAd: 7,
        feedPostsPerFeatureCarousel: 12,
        readerPagesPerAdBreak: 15,
        readerMinCooldownSeconds: 420,
        narrationPagesPerAdBreak: 10,
        audioTracksPerAdBreak: 6,
        audioMinCooldownSeconds: 600,
        allowAudioMidRoll: true,
      ),
      AppInUse.b => const AdMarketPolicy(
        app: AppInUse.b,
        segmentName: 'Red Malla Offline BLE/Wi-Fi, Movilidad Urbana y Emergencias SOS',
        externalAdShare: 0.50,
        feedPostsPerInlineAd: 8,
        feedPostsPerFeatureCarousel: 12,
        readerPagesPerAdBreak: 16,
        readerMinCooldownSeconds: 600,
        narrationPagesPerAdBreak: 12,
        audioTracksPerAdBreak: 8,
        audioMinCooldownSeconds: 900,
        allowAudioMidRoll: false,
        blockedRoutes: ['/blupSos'],
      ),
      _ => AdMarketPolicy(
        app: app,
        segmentName: 'Hub Transversal Open Neom y Polinización Cruzada',
        externalAdShare: 0.60,
        feedPostsPerInlineAd: 6,
        feedPostsPerFeatureCarousel: 10,
        readerPagesPerAdBreak: 12,
        readerMinCooldownSeconds: 300,
        narrationPagesPerAdBreak: 8,
        audioTracksPerAdBreak: 5,
        audioMinCooldownSeconds: 480,
        allowAudioMidRoll: true,
      ),
    };
  }

  /// Deterministic Bresenham quota allocator: distributes external vs. internal
  /// House Ads across sequential `slotIndex` values (`0, 1, 2, ...`) matching
  /// [externalAdShare] without random flicker during widget rebuilds.
  bool shouldPreferExternalAd(int slotIndex) {
    if (externalAdShare <= 0.0) return false;
    if (externalAdShare >= 1.0) return true;
    final k = slotIndex < 0 ? 0 : slotIndex;
    final prevQuota = (k * externalAdShare).floor();
    final nextQuota = ((k + 1) * externalAdShare).floor();
    return nextQuota > prevQuota;
  }

  /// Returns `true` when [route] belongs to a safety-critical flow where ads
  /// must be suppressed (e.g. `/blupSos` emergency screen).
  bool isRouteBlocked(String route) {
    if (route.isEmpty || blockedRoutes.isEmpty) return false;
    return blockedRoutes.any((blocked) => route.startsWith(blocked));
  }

  /// Safely evaluates [routeReader] only when [blockedRoutes] is non-empty,
  /// returning `false` if navigation root is not yet mounted.
  bool isActiveRouteBlocked(String Function() routeReader) {
    if (blockedRoutes.isEmpty) return false;
    try {
      return isRouteBlocked(routeReader());
    } catch (_) {
      return false;
    }
  }
}
