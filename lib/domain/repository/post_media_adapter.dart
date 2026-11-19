import 'dart:async';

import 'package:flutter/widgets.dart';

import '../model/post.dart';

/// Optional platform/app media and transport capability adapter registered via
/// Sint DI so apps with offline/local/mesh social pipelines (such as `Blup`,
/// or any Open Neom app opting into `neom_mesh`) enhance `neom_timeline` and
/// `neom_posts` without coupling those modules to native plugins or forcing
/// Firebase dependencies onto offline-only platforms.
///
/// Mirrors [InboxMediaAdapter] from `inbox_transport_gateway.dart`:
/// - Cloud apps can omit registering this adapter (all defaults keep current
///   remote-image / FCM push behavior unchanged).
/// - Offline/hybrid apps register a [PostMediaAdapter] (for example
///   `LocalPostMediaAdapter` or `LocalMediaUploadService`) to render local file
///   attachments, compress outgoing media, show mesh origin badges, and suppress
///   cloud-only FCM push / scheduled-post queries when running offline.
abstract class PostMediaAdapter {
  /// Whether this app can render and attach local/mesh media without internet.
  bool get supportsOfflineMeshMedia => false;

  /// Whether `neom_timeline` and `neom_posts` should trigger remote FCM push
  /// notifications (`FirebaseMessagingCalls`) after creating/liking/commenting.
  /// Offline-only apps return `false` to avoid touching Firebase Messaging.
  bool get supportsRemotePushNotifications => true;

  /// Whether server-side scheduled posts are supported in this environment.
  bool get supportsScheduledPosts => true;

  /// Whether guest / local-identity sessions are allowed to publish, like,
  /// comment, and read the communal feed via injected repositories without
  /// requiring a Firebase authenticated cloud account.
  bool get supportsGuestSocialActivity => false;

  /// Optional stream notifying `TimelineController` whenever new remote mesh
  /// posts or mutations arrive asynchronously from nearby peers.
  Stream<void> get onSocialFeedChanged => const Stream<void>.empty();

  /// Optionally compress, strip EXIF/GPS, or stage a local media file before
  /// attaching it to a post. Return `null` to cancel attachment.
  Future<String?> prepareOutgoingMediaPath(
    String sourcePath, {
    bool isVideo = false,
  }) async => sourcePath;

  /// Optional image renderer for local/mesh paths (e.g. device file paths or
  /// `file://` URIs) that `HandledCachedNetworkImage` cannot fetch over HTTP.
  ///
  /// Returning `null` falls back to the default network image renderer.
  Widget? buildPostImage(
    BuildContext context,
    String mediaPathOrUrl, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    VoidCallback? onTap,
  }) => null;

  /// Optional inline video widget for local/mesh video files.
  ///
  /// Returning `null` falls back to `NeomVideoPlayer`.
  Widget? buildPostVideo(
    BuildContext context,
    Post post, {
    double? height,
  }) => null;

  /// Open or share a locally stored post attachment via the OS share sheet.
  Future<bool> openOrShareLocalMedia(
    String filePath, {
    String? title,
    String? mimeType,
  }) async => false;

  /// Open a post's geolocation inside the host app's native map/radar view.
  /// Returns `true` if handled internally.
  Future<bool> openPostLocation(
    BuildContext context, {
    required double lat,
    required double lng,
    String label = '',
  }) async => false;

  /// Optional subtle badge displayed on a post card to indicate its transport
  /// origin (e.g., local BLE/Wi-Fi mesh vs. cloud).
  Widget? buildOriginBadge(BuildContext context, Post post) => null;
}
