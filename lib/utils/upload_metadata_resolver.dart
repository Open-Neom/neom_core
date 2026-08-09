import 'enums/app_media_type.dart';
import 'enums/media_type.dart';

/// Pure resolver for upload file naming and MIME metadata.
///
/// Previously every upload was stored with a hard-coded extension per
/// [MediaType] (an `.m4a` became `<id>.mp3`) and without any `contentType`,
/// so Firebase Storage served everything as `application/octet-stream` —
/// browsers downloaded instead of streaming and some players refused the
/// file. These helpers are pure and unit-testable; `AppUploadFirestore`
/// wires them into the upload calls.
class UploadMetadataResolver {

  static const Map<String, String> _mimeByExtension = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'mp3': 'audio/mpeg',
    'm4a': 'audio/mp4',
    'aac': 'audio/aac',
    'wav': 'audio/wav',
    'ogg': 'audio/ogg',
    'oga': 'audio/ogg',
    'flac': 'audio/flac',
    'opus': 'audio/ogg',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'webm': 'video/webm',
    'm4v': 'video/x-m4v',
    'pdf': 'application/pdf',
    'txt': 'text/plain',
  };

  /// Historical default extension per [MediaType] (kept for storage-path
  /// backwards compatibility when the source file extension is unknown).
  static String defaultExtensionFor(MediaType mediaType) {
    switch (mediaType) {
      case MediaType.image:
        return '.jpg';
      case MediaType.video:
        return '.mp4';
      case MediaType.audio:
        return '.mp3';
      case MediaType.document:
        return '.pdf';
      case MediaType.media:
      case MediaType.unknown:
        return '';
    }
  }

  /// Extracts the extension (with dot, lower-cased) from [path] when it is a
  /// known media extension; returns null otherwise.
  static String? extensionFromPath(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == path.length - 1) return null;
    final ext = path.substring(dotIndex + 1).toLowerCase();
    // Reject anything that does not look like a plain extension (e.g. paths
    // with query params or trailing slashes).
    if (ext.length > 5 || ext.contains('/') || ext.contains('?')) return null;
    return _mimeByExtension.containsKey(ext) ? '.$ext' : null;
  }

  /// Extension to store the file under: the real one from [filePath] when it
  /// is a known media type, otherwise the historical default for [mediaType].
  static String resolveExtension({String? filePath, required MediaType mediaType}) {
    if (filePath != null) {
      final fromPath = extensionFromPath(filePath);
      if (fromPath != null) return fromPath;
    }
    return defaultExtensionFor(mediaType);
  }

  /// MIME type for [extension] (with or without leading dot, any case).
  /// Falls back to `application/octet-stream` so metadata is never null.
  static String contentTypeForExtension(String extension) {
    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    return _mimeByExtension[ext.toLowerCase()] ?? 'application/octet-stream';
  }

  /// MIME type for a release item of [type]. Non-file kinds (posts, polls,
  /// youtube references) also fall back to octet-stream.
  static String contentTypeForAppMediaType(AppMediaType type) =>
      contentTypeForExtension(type.value);
}
