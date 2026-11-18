import 'package:flutter/widgets.dart';

import '../domain/model/audio_ad_break_spec.dart';
import '../domain/model/house_ad_item.dart';
import 'enums/ad_placement.dart';

/// Dependency-free cross-module registry bridging UI surfaces (`neom_timeline`,
/// `neom_home`, `neom_books`, `neom_audio_player`) with `neom_ads` without
/// coupling content/media packages to `google_mobile_ads` or Web JS SDKs.
class NeomAdRegistry {
  NeomAdRegistry._();

  /// Whether external programmatic ads (Google AdMob / GPT / AdSense / IMA VAST)
  /// should be shown to the current user (false for active paid subscribers & staff).
  static bool Function()? shouldShowExternalAdsFn;

  /// Whether internal platform feature-discovery House Ads should be shown.
  static bool Function()? shouldShowHouseAdsFn;

  /// Renders a feed, sidebar, or banner slot combining Direct Sponsors,
  /// Google Ads (targeted to `AppInUse`), and Internal House Ads.
  static Widget Function({
    required AdPlacement placement,
    int slotIndex,
    List<String> contextKeywords,
    bool preferHouseAd,
  })? buildAdSlotFn;

  /// Renders a horizontal multi-card menu feature discovery carousel.
  static Widget Function({int slotIndex})? buildFeatureCarouselFn;

  /// Renders a page-milestone ad break modal (video/image/house ad) inside
  /// `NeomRoomWrapper.frontalWidget` (already wrapped in `PointerInterceptor`).
  static Widget Function({
    required VoidCallback onContinue,
    List<String> contextKeywords,
    String? contentTitle,
  })? buildReaderPageBreakOverlayFn;

  /// Renders a slim 50px collapsible reader banner outside the PDF canvas.
  static Widget Function({
    List<String> contextKeywords,
  })? buildReaderBannerStripFn;

  /// Displays a rewarded video/interactive ad break and returns `true` when
  /// the user earns the reward (e.g. +10 min reading or +30 min listening).
  static Future<bool> Function({
    required AdPlacement placement,
    List<String> contextKeywords,
    BuildContext? context,
  })? showRewardedUnlockFn;

  /// Resolves the next audio ad break (VAST Audio / Sponsor / House Audio Spot)
  /// for `NeomAudioHandler` or `BookNarrationController`.
  static Future<AudioAdBreakSpec?> Function({
    required AdPlacement placement,
    List<String> contextKeywords,
  })? resolveAudioAdBreakFn;

  /// Reports VAST / telemetry lifecycle events (`impression`, `firstQuartile`,
  /// `midpoint`, `thirdQuartile`, `complete`, `skip`, `click`).
  static void Function(AudioAdBreakSpec spec, String event)?
      onAudioAdTrackingEventFn;

  /// Renders the foreground companion card (synced video or campaign artwork +
  /// skip countdown + CTA + ad-free upgrade banner) during an audio ad break.
  static Widget Function({
    required AudioAdBreakSpec spec,
    required Duration position,
    required Duration duration,
    VoidCallback? onSkip,
    bool compact,
  })? buildAudioCompanionCardFn;

  /// Returns curated [HouseAdItem] entries for the current `AppInUse`.
  static List<HouseAdItem> Function({
    AdPlacement? placement,
  })? getHouseAdsFn;

  static bool get shouldShowExternalAds =>
      shouldShowExternalAdsFn?.call() ?? false;

  static bool get shouldShowHouseAds =>
      shouldShowHouseAdsFn?.call() ?? false;

  static bool get isRegistered => buildAdSlotFn != null;

  /// Clears all callbacks (useful in isolated widget/unit tests).
  static void reset() {
    shouldShowExternalAdsFn = null;
    shouldShowHouseAdsFn = null;
    buildAdSlotFn = null;
    buildFeatureCarouselFn = null;
    buildReaderPageBreakOverlayFn = null;
    buildReaderBannerStripFn = null;
    showRewardedUnlockFn = null;
    resolveAudioAdBreakFn = null;
    onAudioAdTrackingEventFn = null;
    buildAudioCompanionCardFn = null;
    getHouseAdsFn = null;
  }
}
