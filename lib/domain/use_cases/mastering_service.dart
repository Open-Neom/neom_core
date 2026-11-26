import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Result returned when a track finishes mastering in `neom_mastering`.
class MasteringTrackResult {
  final String jobId;
  final String fileName;
  final String? downloadUrl;
  final String? localFilePath;
  final Uint8List? bytes;
  final String providerId;
  final String presetId;
  final double? integratedLufs;
  final double? truePeakDb;

  const MasteringTrackResult({
    required this.jobId,
    required this.fileName,
    this.downloadUrl,
    this.localFilePath,
    this.bytes,
    this.providerId = 'auto',
    this.presetId = 'balanced',
    this.integratedLufs,
    this.truePeakDb,
  });

  bool get hasMasterAsset =>
      (downloadUrl != null && downloadUrl!.isNotEmpty) ||
      (localFilePath != null && localFilePath!.isNotEmpty) ||
      (bytes != null && bytes!.isNotEmpty);
}

/// Decoupled contract allowing `neom_home`, `neom_releases`, `neom_media_upload`,
/// or `neom_daw` to invoke `neom_mastering` without circular dependencies.
abstract class MasteringService {
  /// Opens the standalone Gig Mastering flow (eMastered-style overlay modal on
  /// Web, or multi-step flow on Mobile) directly from Home / Right Sidebar.
  Future<void> showMasteringModal(BuildContext context);

  /// Opens the Gig Mastering flow pre-populated with the given track, and
  /// resolves with the mastered result if the user completes checkout, or `null`
  /// if cancelled.
  Future<MasteringTrackResult?> openMasteringForTrack({
    required BuildContext context,
    String? initialFilePath,
    Uint8List? initialBytes,
    String? fileName,
    String? trackTitle,
    String? genreHint,
  });
}
