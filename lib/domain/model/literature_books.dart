
/// Lightweight book model for timeline display.
/// Avoids dependency on neom_freebooks module.
class LiteraryBook {
  final int id;
  final String title;
  final String author;
  final String coverUrl;
  final String htmlUrl;
  final List<String> subjects;

  const LiteraryBook({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.htmlUrl,
    this.subjects = const [],
  });

  factory LiteraryBook.fromGutendexJson(Map<String, dynamic> json) {
    final authors = (json['authors'] as List<dynamic>?)
        ?.map((a) => a['name'] as String?)
        .whereType<String>()
        .toList() ?? [];

    final formats = json['formats'] as Map<String, dynamic>? ?? {};
    final coverUrl = formats['image/jpeg'] as String? ?? '';
    final htmlUrl = formats['text/html'] as String?
        ?? formats['text/html; charset=utf-8'] as String?
        ?? '';

    return LiteraryBook(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      author: authors.isNotEmpty ? authors.first : '',
      coverUrl: coverUrl,
      htmlUrl: htmlUrl,
      subjects: List<String>.from(json['subjects'] ?? []),
    );
  }
}
