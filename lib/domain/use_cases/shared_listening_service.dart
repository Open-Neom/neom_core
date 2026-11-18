import 'package:flutter/widgets.dart';

/// Launches an optional shared listening room (`Sesión Compartida`) for a song
/// without coupling `neom_audio_player` directly to `neom_rooms`.
abstract class SharedListeningService {
  Future<void> openSharedSongRoom(
    BuildContext context, {
    required String mediaId,
    required String title,
    required String artist,
    String? coverUrl,
    String? ownerEmail,
    String? ownerProfileId,
    int durationSeconds = 180,
    int positionSeconds = 0,
  });
}
