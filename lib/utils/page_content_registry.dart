/// Global registry for the content currently visible on screen.
///
/// Any module can call [register] when its page loads to make the content
/// available for AI assistants (like Itzli) without creating a dependency
/// on neom_ia. The AI module reads this registry to understand what the
/// user is looking at.
///
/// Usage:
/// ```dart
/// // On page load:
/// PageContentRegistry.register(
///   route: '/blog/abc123',
///   title: 'Roto',
///   body: 'El no esta muerto, Llora con ciertas canciones...',
///   author: 'Fcrown',
///   contentType: 'blog_entry',
/// );
///
/// // On page dispose:
/// PageContentRegistry.clear();
/// ```
class PageContentRegistry {
  PageContentRegistry._();

  static String route = '';
  static String title = '';
  static String body = '';
  static String author = '';
  static String contentType = '';
  static Map<String, String> metadata = {};
  static int registeredAt = 0;

  /// Register the visible page content.
  static void register({
    required String route,
    required String title,
    String body = '',
    String author = '',
    String contentType = '',
    Map<String, String> metadata = const {},
  }) {
    PageContentRegistry.route = route;
    PageContentRegistry.title = title;
    PageContentRegistry.body = body;
    PageContentRegistry.author = author;
    PageContentRegistry.contentType = contentType;
    PageContentRegistry.metadata = Map.of(metadata);
    PageContentRegistry.registeredAt = DateTime.now().millisecondsSinceEpoch;
  }

  /// Clear registered content.
  static void clear() {
    route = '';
    title = '';
    body = '';
    author = '';
    contentType = '';
    metadata = {};
    registeredAt = 0;
  }

  /// Whether there is active content registered.
  static bool get hasContent => title.isNotEmpty && registeredAt > 0;
}
