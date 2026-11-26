import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/utils/enums/app_media_type.dart';
import 'package:neom_core/utils/enums/media_type.dart';
import 'package:neom_core/utils/upload_metadata_resolver.dart';

void main() {
  test('binary PNG gets png metadata while legacy defaults remain unchanged', () {
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    final extension = UploadMetadataResolver.resolveBytesExtension(signature, MediaType.image);
    expect(extension, '.png');
    expect(UploadMetadataResolver.contentTypeForExtension(extension), 'image/png');
    expect(UploadMetadataResolver.resolveBytesExtension([255,216,255], MediaType.image), '.jpg');
    expect(UploadMetadataResolver.resolveBytesExtension(signature.sublist(0,7), MediaType.image), '.jpg');
    expect(UploadMetadataResolver.resolveBytesExtension(signature, MediaType.video), '.mp4');
    expect(UploadMetadataResolver.resolveBytesExtension([], MediaType.audio), '.mp3');
  });

  test('binary audio sniffs WAV, FLAC, OGG, and M4A containers accurately', () {
    final wavHeader = [0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x41, 0x56, 0x45];
    final flacHeader = [0x66, 0x4C, 0x61, 0x43, 0, 0, 0, 0, 0, 0, 0, 0];
    final oggHeader = [0x4F, 0x67, 0x67, 0x53, 0, 0, 0, 0, 0, 0, 0, 0];
    final m4aHeader = [0, 0, 0, 0x20, 0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x41, 0x20];

    expect(UploadMetadataResolver.resolveBytesExtension(wavHeader, MediaType.audio), '.wav');
    expect(UploadMetadataResolver.contentTypeForExtension('.wav'), 'audio/wav');
    expect(UploadMetadataResolver.resolveBytesExtension(flacHeader, MediaType.audio), '.flac');
    expect(UploadMetadataResolver.resolveBytesExtension(oggHeader, MediaType.audio), '.ogg');
    expect(UploadMetadataResolver.resolveBytesExtension(m4aHeader, MediaType.audio), '.m4a');
  });
  group('UploadMetadataResolver.defaultExtensionFor', () {
    test('keeps the historical per-type defaults', () {
      expect(UploadMetadataResolver.defaultExtensionFor(MediaType.image), '.jpg');
      expect(UploadMetadataResolver.defaultExtensionFor(MediaType.video), '.mp4');
      expect(UploadMetadataResolver.defaultExtensionFor(MediaType.audio), '.mp3');
      expect(UploadMetadataResolver.defaultExtensionFor(MediaType.document), '.pdf');
      expect(UploadMetadataResolver.defaultExtensionFor(MediaType.media), '');
      expect(UploadMetadataResolver.defaultExtensionFor(MediaType.unknown), '');
    });
  });

  group('UploadMetadataResolver.extensionFromPath', () {
    test('extracts known extensions with dot, lower-cased', () {
      expect(UploadMetadataResolver.extensionFromPath('/tmp/song.m4a'), '.m4a');
      expect(UploadMetadataResolver.extensionFromPath('/tmp/PHOTO.PNG'), '.png');
      expect(UploadMetadataResolver.extensionFromPath('relative/clip.MOV'), '.mov');
    });

    test('returns null for unknown or malformed extensions', () {
      expect(UploadMetadataResolver.extensionFromPath('/tmp/file.xyz'), isNull);
      expect(UploadMetadataResolver.extensionFromPath('/tmp/no_extension'), isNull);
      expect(UploadMetadataResolver.extensionFromPath('/tmp/trailing.'), isNull);
      expect(UploadMetadataResolver.extensionFromPath('/tmp/a.b/c'), isNull);
      expect(UploadMetadataResolver.extensionFromPath('file.mp3?token=abc'), isNull);
    });
  });

  group('UploadMetadataResolver.resolveExtension', () {
    test('prefers the real file extension over the type default', () {
      // Regression: an .m4a used to be stored renamed as .mp3.
      expect(
        UploadMetadataResolver.resolveExtension(
            filePath: '/tmp/track.m4a', mediaType: MediaType.audio),
        '.m4a',
      );
    });

    test('falls back to the type default when path is null or unknown', () {
      expect(
        UploadMetadataResolver.resolveExtension(
            filePath: null, mediaType: MediaType.audio),
        '.mp3',
      );
      expect(
        UploadMetadataResolver.resolveExtension(
            filePath: '/tmp/blob', mediaType: MediaType.image),
        '.jpg',
      );
    });
  });

  group('UploadMetadataResolver.contentTypeForExtension', () {
    test('maps known extensions to their MIME type', () {
      expect(UploadMetadataResolver.contentTypeForExtension('.mp3'), 'audio/mpeg');
      expect(UploadMetadataResolver.contentTypeForExtension('m4a'), 'audio/mp4');
      expect(UploadMetadataResolver.contentTypeForExtension('.JPG'), 'image/jpeg');
      expect(UploadMetadataResolver.contentTypeForExtension('mp4'), 'video/mp4');
      expect(UploadMetadataResolver.contentTypeForExtension('.pdf'), 'application/pdf');
    });

    test('never returns null — octet-stream fallback', () {
      expect(UploadMetadataResolver.contentTypeForExtension('.xyz'),
          'application/octet-stream');
      expect(UploadMetadataResolver.contentTypeForExtension(''),
          'application/octet-stream');
    });
  });

  group('UploadMetadataResolver.contentTypeForAppMediaType', () {
    test('maps release item kinds', () {
      expect(UploadMetadataResolver.contentTypeForAppMediaType(AppMediaType.audio),
          'audio/mpeg');
      expect(UploadMetadataResolver.contentTypeForAppMediaType(AppMediaType.image),
          'image/jpeg');
      expect(UploadMetadataResolver.contentTypeForAppMediaType(AppMediaType.video),
          'video/mp4');
      expect(UploadMetadataResolver.contentTypeForAppMediaType(AppMediaType.text),
          'application/pdf');
    });

    test('non-file kinds fall back to octet-stream', () {
      expect(UploadMetadataResolver.contentTypeForAppMediaType(AppMediaType.poll),
          'application/octet-stream');
    });
  });
}
