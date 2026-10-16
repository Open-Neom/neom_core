import 'dart:typed_data';

/// Optional capability for accepting an editor's rendered PNG/MP4 locally.
///
/// A receiver stages and validates all resources before changing the selected
/// media. It returns true only after committing, false when [isCurrent] becomes
/// false, and throws on validation/preparation failure. This never publishes.
abstract interface class EditedMediaReceiver {
  Future<bool> acceptEditedMedia(
    Uint8List bytes, {
    required String filename,
    required bool Function() isCurrent,
  });
}
