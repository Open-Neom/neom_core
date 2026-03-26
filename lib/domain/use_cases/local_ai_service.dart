/// Abstract interface for on-device AI inference.
///
/// Provides offline fallback when cloud AI (Gemini/Claude) is unavailable.
/// Implementations can use llama.cpp, MediaPipe, Core ML, or any local model.
///
/// The embedded chat assistant (SAIA) falls back to this service when:
/// - No internet connection detected
/// - Cloud API quota exceeded
/// - User explicitly requests offline mode
///
/// Register in rootBinding only if on-device inference is available:
/// ```dart
/// Bind.lazyPut<LocalAiService>(() => LlamaCppService(), fenix: true);
/// ```
abstract class LocalAiService {

  /// Whether a local model is loaded and ready for inference.
  bool get isReady;

  /// Load the local model. Call once at app startup.
  /// Returns true if model loaded successfully.
  Future<bool> initialize({String? modelPath});

  /// Generate a response from a prompt (single turn, no history).
  Future<String> generate(String prompt, {int maxTokens = 256});

  /// Generate a response with conversation history context.
  Future<String> chat(List<Map<String, String>> messages, {int maxTokens = 256});

  /// Get model info (name, size, quantization).
  Map<String, dynamic> get modelInfo;

  /// Release model from memory.
  Future<void> dispose();
}
