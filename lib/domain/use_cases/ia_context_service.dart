// import 'package:google_generative_ai/google_generative_ai.dart';
//
// import '../../app_config.dart';
// import '../../app_properties.dart';
// import '../model/ia_info.dart';
//
// /// Service for generating and managing AI context for books/releases.
// /// Used by EMXI to generate book context once, which is then stored
// /// in AppReleaseItem.iaInfo and reused for all chat sessions.
// class IaContextService {
//
//   /// Generate book context from PDF text content.
//   /// This should be called once when the author enables AI for their book.
//   ///
//   /// [pdfTextContent] - The full text extracted from the PDF
//   /// [bookTitle] - Title of the book
//   /// [bookAuthor] - Author name
//   /// [bookDescription] - Book description/synopsis
//   /// [language] - Target language for the context
//   ///
//   /// Returns a generated context summary suitable for AI chat sessions.
//   static Future<String?> generateBookContext({
//     required String pdfTextContent,
//     required String bookTitle,
//     required String bookAuthor,
//     String bookDescription = '',
//     String language = 'es',
//   }) async {
//     final apiKey = AppProperties.getGeminiApiKey();
//     if (apiKey.isEmpty) {
//       AppConfig.logger.e("Gemini API key not configured");
//       return null;
//     }
//
//     try {
//       final model = GenerativeModel(
//         model: 'gemini-2.0-flash',
//         apiKey: apiKey,
//       );
//
//       // Truncate content if too long (Gemini has token limits)
//       String content = pdfTextContent;
//       if (content.length > 100000) {
//         // Take beginning, middle, and end for better coverage
//         final third = content.length ~/ 3;
//         content = '${content.substring(0, 30000)}\n\n[...]\n\n'
//             '${content.substring(third, third + 30000)}\n\n[...]\n\n'
//             '${content.substring(content.length - 30000)}';
//       }
//
//       final prompt = '''
// Eres un asistente experto en análisis literario. Tu tarea es crear un contexto completo y útil para un asistente de IA que ayudará a lectores con preguntas sobre el siguiente libro.
//
// **Libro:** $bookTitle
// **Autor:** $bookAuthor
// ${bookDescription.isNotEmpty ? '**Sinopsis:** $bookDescription' : ''}
//
// **Contenido del libro:**
// $content
//
// ---
//
// Por favor, genera un contexto estructurado que incluya:
//
// 1. **Resumen General** (2-3 párrafos): Un resumen completo del libro sin spoilers mayores.
//
// 2. **Personajes Principales**: Lista de personajes principales con breve descripción de cada uno.
//
// 3. **Temas Centrales**: Los temas principales que explora la obra.
//
// 4. **Estructura Narrativa**: Cómo está organizado el libro (capítulos, partes, línea temporal).
//
// 5. **Contexto y Ambientación**: Dónde y cuándo se desarrolla la historia.
//
// 6. **Información del Autor**: Breve contexto sobre el autor y su estilo.
//
// 7. **Puntos Clave por Sección**: Resumen de eventos importantes por cada sección/parte del libro (sin revelar finales o giros importantes).
//
// El contexto debe estar en ${language == 'en' ? 'inglés' : 'español'} y ser útil para que un asistente de IA pueda responder preguntas de lectores sin tener que procesar el PDF cada vez.
//
// IMPORTANTE: No incluyas spoilers del final o giros argumentales sorpresa. El asistente debe poder ayudar sin arruinar la experiencia de lectura.
// ''';
//
//       final response = await model.generateContent([Content.text(prompt)]);
//       final generatedContext = response.text;
//
//       if (generatedContext != null && generatedContext.isNotEmpty) {
//         AppConfig.logger.d("Book context generated successfully (${generatedContext.length} chars)");
//         return generatedContext;
//       }
//
//       return null;
//     } catch (e) {
//       AppConfig.logger.e("Error generating book context: $e");
//       return null;
//     }
//   }
//
//   /// Create a new IaInfo with generated context.
//   /// This is the main method to be called from EMXI when author configures AI.
//   static Future<IaInfo?> createIaInfo({
//     required String pdfTextContent,
//     required String bookTitle,
//     required String bookAuthor,
//     required String agentName,
//     required String personality,
//     String bookDescription = '',
//     String authorInstructions = '',
//     String language = 'es',
//     String avatarUrl = '',
//   }) async {
//     final context = await generateBookContext(
//       pdfTextContent: pdfTextContent,
//       bookTitle: bookTitle,
//       bookAuthor: bookAuthor,
//       bookDescription: bookDescription,
//       language: language,
//     );
//
//     if (context == null) {
//       return null;
//     }
//
//     return IaInfo(
//       isEnabled: true,
//       agentName: agentName,
//       personality: personality,
//       itemContext: context,
//       authorInstructions: authorInstructions,
//       contextGeneratedAt: DateTime.now().millisecondsSinceEpoch,
//       language: language,
//       avatarUrl: avatarUrl,
//     );
//   }
//
//   /// Regenerate context for an existing IaInfo (if author wants to refresh it).
//   static Future<IaInfo?> regenerateContext({
//     required IaInfo existingIaInfo,
//     required String pdfTextContent,
//     required String bookTitle,
//     required String bookAuthor,
//     String bookDescription = '',
//   }) async {
//     final newContext = await generateBookContext(
//       pdfTextContent: pdfTextContent,
//       bookTitle: bookTitle,
//       bookAuthor: bookAuthor,
//       bookDescription: bookDescription,
//       language: existingIaInfo.language,
//     );
//
//     if (newContext == null) {
//       return null;
//     }
//
//     return existingIaInfo.copyWith(
//       itemContext: newContext,
//       contextGeneratedAt: DateTime.now().millisecondsSinceEpoch,
//     );
//   }
//
//   /// Validate that an IaInfo is properly configured for chat.
//   static String? validateIaInfo(IaInfo? iaInfo) {
//     if (iaInfo == null) {
//       return 'No hay configuración de IA';
//     }
//
//     if (!iaInfo.isEnabled) {
//       return 'La IA no está habilitada';
//     }
//
//     if (iaInfo.agentName.isEmpty) {
//       return 'El nombre del agente es requerido';
//     }
//
//     if (!iaInfo.hasContext) {
//       return 'El contexto del libro no ha sido generado';
//     }
//
//     return null; // Valid
//   }
// }
