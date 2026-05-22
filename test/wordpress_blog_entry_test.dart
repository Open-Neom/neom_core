// Tests for `wordpress/BlogEntry` — WordPress REST API entry.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/wordpress/blog_entry.dart';

void main() {
  group('WordPress BlogEntry — constructor', () {
    test('constructor con required positivos', () {
      final e = BlogEntry(
        id: 'b1',
        date: DateTime(2024, 1, 1),
        slug: 'mi-articulo',
        title: 'Mi articulo',
        content: 'Contenido',
        excerpt: 'Resumen',
      );
      expect(e.id, 'b1');
      expect(e.date.year, 2024);
      expect(e.slug, 'mi-articulo');
      expect(e.title, 'Mi articulo');
      expect(e.author, '');
      expect(e.url, '');
      expect(e.imgUrl, '');
    });
  });

  group('BlogEntry.toJson', () {
    test('contiene 6 llaves principales', () {
      final e = BlogEntry(
        id: 'b1', date: DateTime(2024), slug: 's',
        title: 't', content: 'c', excerpt: 'e',
      );
      final json = e.toJson();
      expect(json.keys, containsAll([
        'id', 'date', 'slug', 'title', 'content', 'excerpt',
      ]));
    });

    test('date se serializa como ISO 8601', () {
      final e = BlogEntry(
        id: 'b1', date: DateTime.utc(2024, 1, 15, 12),
        slug: 's', title: 't', content: 'c', excerpt: 'e',
      );
      expect(e.toJson()['date'], '2024-01-15T12:00:00.000Z');
    });
  });

  group('BlogEntry.fromJson — happy path WordPress API', () {
    test('parsea respuesta típica de WP REST', () {
      final e = BlogEntry.fromJson({
        'id': 7764,
        'date': '2024-01-15T12:00:00',
        'slug': 'mi-articulo',
        'title': {'rendered': 'Mi <em>articulo</em>'},
        'content': {'rendered': '<p>Hola <strong>mundo</strong></p>'},
        'excerpt': {'rendered': 'Resumen'},
        'link': 'https://emxi.org/mi-articulo',
        'author': 1,
        'jetpack_featured_media_url': 'https://x.com/img.jpg',
      });
      expect(e.id, '7764');
      expect(e.date.year, 2024);
      expect(e.slug, 'mi-articulo');
      // Title strip de tags HTML
      expect(e.title, 'Mi articulo',
          reason: 'tags HTML deben removerse de title');
      expect(e.content, 'Hola mundo',
          reason: 'tags HTML deben removerse de content');
      expect(e.excerpt, 'Resumen');
      expect(e.url, 'https://emxi.org/mi-articulo');
      expect(e.author, '1');
      expect(e.imgUrl, 'https://x.com/img.jpg');
    });

    test('extrae imgUrl de _embedded cuando jetpack ausente', () {
      final e = BlogEntry.fromJson({
        'id': 1,
        'date': '2024-01-01',
        'slug': 's',
        'title': {'rendered': 't'},
        'content': {'rendered': 'c'},
        'excerpt': {'rendered': 'e'},
        'link': 'https://x',
        'author': 1,
        '_embedded': {
          'wp:featuredmedia': [
            {
              'media_details': {
                'sizes': {
                  'medium_large': {
                    'source_url': 'https://x.com/medium.jpg',
                  },
                },
              },
            },
          ],
        },
      });
      expect(e.imgUrl, 'https://x.com/medium.jpg');
    });

    test('imgUrl vacío cuando no hay jetpack ni _embedded', () {
      final e = BlogEntry.fromJson({
        'id': 1, 'date': '2024-01-01', 'slug': 's',
        'title': {'rendered': 't'}, 'content': {'rendered': 'c'},
        'excerpt': {'rendered': 'e'}, 'link': 'https://x', 'author': 1,
      });
      expect(e.imgUrl, '');
    });

    test('múltiples espacios en content se colapsan a uno', () {
      final e = BlogEntry.fromJson({
        'id': 1, 'date': '2024-01-01', 'slug': 's',
        'title': {'rendered': 't'},
        'content': {'rendered': '<p>Hola    mundo\n\n\n  texto</p>'},
        'excerpt': {'rendered': 'e'}, 'link': 'https://x', 'author': 1,
      });
      expect(e.content, 'Hola mundo texto');
    });
  });

  group('BlogEntry.fromJson — NC-43: campos null crashean', () {
    test('NC-43: id null', () {
      try {
        BlogEntry.fromJson({
          'id': null, 'date': '2024-01-01', 'slug': 's',
          'title': {'rendered': 't'}, 'content': {'rendered': 'c'},
          'excerpt': {'rendered': 'e'}, 'link': 'https://x', 'author': 1,
        });
        fail('Esperaba crash con id null');
      } on Object {}
    });

    test('NC-43: date null crashea (DateTime.parse)', () {
      try {
        BlogEntry.fromJson({
          'id': 1, 'date': null, 'slug': 's',
          'title': {'rendered': 't'}, 'content': {'rendered': 'c'},
          'excerpt': {'rendered': 'e'}, 'link': 'https://x', 'author': 1,
        });
        fail('Esperaba crash con date null');
      } on Object {}
    });

    test('NC-43: slug null crashea', () {
      try {
        BlogEntry.fromJson({
          'id': 1, 'date': '2024-01-01', 'slug': null,
          'title': {'rendered': 't'}, 'content': {'rendered': 'c'},
          'excerpt': {'rendered': 'e'}, 'link': 'https://x', 'author': 1,
        });
        fail('Esperaba crash con slug null');
      } on Object {}
    });
  });
}
