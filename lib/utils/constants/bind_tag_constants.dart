/// Centralized Dependency Injection (`Sint` / `Bind`) tag constants for Open Neom.
///
/// Note: Standard 1-to-1 `Service <-> Controller` registrations in `RootBinding`
/// use `Bind.contract<TService, TController>(...)` or `Bind.putContract<...>()`
/// **without** a `tag`, so existing `Sint.find<TService>()` and
/// `Sint.find<TController>()` calls require zero changes across modules.
///
/// Use [BindTagConstants] only when:
/// 1. Multiple implementations of the same core `Service` coexist simultaneously
///    in the same host app (e.g. multiple payment gateways or music providers).
/// 2. Cross-module optional bridges or reactive signals resolve by tag without
///    importing sibling feature packages.
class BindTagConstants {
  const BindTagConstants._();

  // ---------------------------------------------------------------------------
  // Active Cross-Module Runtime & Reactive Bridges (exact existing identifiers)
  // ---------------------------------------------------------------------------
  static const String blupNeighborCount = 'blup_neighbor_count';
  static const String mobility = 'mobility';
  static const String neomGenerator = 'neomGenerator';
  static const String audioPlayerInvoker = 'AudioPlayerInvoker';
  static const String neomAudioHandler = 'NeomAudioHandler';
  static const String flipbookReader = 'FlipbookReaderController';
  static const String mediaPlayer = 'mediaPlayer';
  static const String authorRecord = 'author_record';

  // ---------------------------------------------------------------------------
  // Commerce & Payment Gateway Variants (e.g. PaymentGatewayService)
  // ---------------------------------------------------------------------------
  static const String stripe = 'stripe';
  static const String woo = 'woo';
  static const String paypal = 'paypal';
  static const String bank = 'bank';
  static const String appCoin = 'appCoin';
  static const String googleBooks = 'googleBooks';

  // ---------------------------------------------------------------------------
  // External Music & Media Catalog Variants (e.g. ExternalMusicService)
  // ---------------------------------------------------------------------------
  static const String spotify = 'spotify';
  static const String youtubeMusic = 'ytmusic';
  static const String youtube = 'youtube';

  // ---------------------------------------------------------------------------
  // Platform, Transport & AI Execution Variants
  // ---------------------------------------------------------------------------
  static const String web = 'web';
  static const String mobile = 'mobile';
  static const String desktop = 'desktop';
  static const String local = 'local';
  static const String cloud = 'cloud';
  static const String mesh = 'mesh';
  static const String hybrid = 'hybrid';
  static const String edge = 'edge';
  static const String remote = 'remote';
  static const String gemini = 'gemini';

  // ---------------------------------------------------------------------------
  // Scoped / Dynamic Tag Builders
  // ---------------------------------------------------------------------------
  static String webCommentsModal(String postId) => 'web_modal_$postId';
}
