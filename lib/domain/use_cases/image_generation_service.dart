import 'dart:typed_data';

/// Abstract interface for AI image generation.
///
/// Implemented by Firebase AI's Imagen model.
/// Consumed by neom_ia (SAIA) via Sint DI.
abstract class ImageGenerationService {
  /// Generate an image from a text prompt.
  /// Returns the image bytes (PNG), or null on failure.
  Future<Uint8List?> generateImage(String prompt);

  /// Generate multiple images from a text prompt.
  /// Returns list of image bytes.
  Future<List<Uint8List>> generateImages(String prompt, {int count = 1});
}
