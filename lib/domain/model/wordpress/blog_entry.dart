import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;


class BlogEntry {
  final String id;
  final DateTime date;
  final String slug;
  final String title;
  final String content;
  final String excerpt;
  final String url;
  final String author;
  final String imgUrl;

  BlogEntry({
    required this.id,
    required this.date,
    required this.slug,
    required this.title,
    required this.content,
    required this.excerpt,
    this.author = '',
    this.url = '',
    this.imgUrl = '',
  });

  /// Creates a BlogEntry instance from JSON.
  factory BlogEntry.fromJson(Map<String, dynamic> json) {

    String title = (json['title']?['rendered'].toString() ?? '');
    title = title..replaceAll(RegExp(r'<[^>]*>'), '');

    String htmlContent = (json['content']?['rendered'].toString() ?? '');
    final document = html_parser.parse(htmlContent);
    String content = document.body?.text ?? '';
    // Reemplazar múltiples espacios, saltos de línea y tabulaciones por un único espacio
    content = content.replaceAll(RegExp(r'\s+'), ' ').trim();

    return BlogEntry(
      id: json['id'].toString(),
      date: DateTime.parse(json['date'] as String),
      slug: json['slug'] as String,
      title: title,
      content: content,
      excerpt: (json['excerpt']?['rendered'] ?? '') as String,
      author: (json['author'].toString()),
      imgUrl: (json['jetpack_featured_media_url'] ?? '') as String,
      url: json['link'] as String,
    );
  }

  /// Converts this BlogEntry instance to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'slug': slug,
    'title': title,
    'content': content,
    'excerpt': excerpt,
  };


  /// Crea una instancia de BlogEntry a partir de un elemento HTML que representa un post.
  factory BlogEntry.fromHtml(dom.Element article) {
    // Extraer el id desde el atributo, por ejemplo "post-7764"
    String id = '';
    String? idAttr = article.attributes['id'];
    if (idAttr != null && idAttr.startsWith('post-')) {
      id = idAttr.substring(5);
    }

    // Extraer la fecha desde el <time datetime="...">
    DateTime date = DateTime.now();
    var timeElement = article.querySelector('time');
    if (timeElement != null) {
      String? datetimeAttr = timeElement.attributes['datetime'];
      if (datetimeAttr != null) {
        date = DateTime.tryParse(datetimeAttr) ?? DateTime.now();
      }
    }

    // Extraer la URL del post (suponemos que el primer <a href="..."> dentro del artículo es el enlace al post)
    String url = '';
    var linkElement = article.querySelector('a[href]');
    if (linkElement != null) {
      url = linkElement.attributes['href'] ?? '';
    }

    // Derivar el slug a partir de la URL (usando el último segmento del path)
    String slug = '';
    if (url.isNotEmpty) {
      Uri uri = Uri.tryParse(url) ?? Uri();
      if (uri.pathSegments.isNotEmpty) {
        slug = uri.pathSegments.last;
      }
    }

    // Extraer el título (por ejemplo, de <h2 class="content-item-title">)
    String title = article.querySelector('h2.content-item-title')?.text.trim() ?? '';

    // Extraer el contenido completo; en este ejemplo, se toma el HTML interno del contenedor con clase "entry-summary"
    String content = article.querySelector('.entry-summary')?.innerHtml.trim() ?? '';

    // Para el extracto se puede tomar el texto del primer párrafo dentro de "entry-summary"
    String excerpt = '';
    var pElement = article.querySelector('.entry-summary p');
    if (pElement != null) {
      excerpt = pElement.text.trim();
    } else {
      excerpt = article.querySelector('.entry-summary')?.text.trim() ?? '';
    }

    // Extraer el autor, asumiendo que está en un <li class="meta-author"> y dentro de un <a>
    String author = '';
    var authorElement = article.querySelector('li.meta-author a');
    if (authorElement != null) {
      author = authorElement.text.trim();
    }

    // Extraer la URL de la imagen, por ejemplo, del <img> dentro de <div class="blog-details-img">
    String imgUrl = '';
    var imgElement = article.querySelector('div.blog-details-img img');
    if (imgElement != null) {
      // Se prefiere el atributo data-src, pero si no existe se usa src
      imgUrl = imgElement.attributes['data-src'] ?? imgElement.attributes['src'] ?? '';
    }

    return BlogEntry(
      id: id,
      date: date,
      slug: slug,
      title: title,
      content: content,
      excerpt: excerpt,
      url: url,
      author: author,
      imgUrl: imgUrl,
    );
  }

}
