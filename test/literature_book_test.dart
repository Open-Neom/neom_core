// Tests for `LiteraryBook` — modelo Gutendex.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/literature_books.dart';

void main() {
  group('LiteraryBook — constructor', () {
    test('constructor con required positivos', () {
      const b = LiteraryBook(
        id: 1,
        title: 'Don Quijote',
        author: 'Cervantes',
        coverUrl: 'https://x/cover.jpg',
        htmlUrl: 'https://x/book.html',
      );
      expect(b.id, 1);
      expect(b.title, 'Don Quijote');
      expect(b.author, 'Cervantes');
      expect(b.coverUrl, 'https://x/cover.jpg');
      expect(b.htmlUrl, 'https://x/book.html');
      expect(b.subjects, isEmpty);
    });

    test('subjects custom', () {
      const b = LiteraryBook(
        id: 1, title: 'X', author: 'A',
        coverUrl: '', htmlUrl: '',
        subjects: ['Fiction', 'Spanish literature'],
      );
      expect(b.subjects, ['Fiction', 'Spanish literature']);
    });

    test('es const-constructible', () {
      const a = LiteraryBook(
        id: 1, title: 't', author: 'a',
        coverUrl: '', htmlUrl: '',
      );
      const b = LiteraryBook(
        id: 1, title: 't', author: 'a',
        coverUrl: '', htmlUrl: '',
      );
      expect(identical(a, b), isTrue);
    });
  });

  group('LiteraryBook.fromGutendexJson', () {
    test('parsea respuesta típica de Gutendex', () {
      final b = LiteraryBook.fromGutendexJson({
        'id': 996,
        'title': 'Don Quijote',
        'authors': [
          {'name': 'Cervantes Saavedra, Miguel de', 'birth_year': 1547},
        ],
        'subjects': ['Fiction', 'Spanish literature'],
        'formats': {
          'image/jpeg': 'https://gutenberg.org/cover.jpg',
          'text/html': 'https://gutenberg.org/996.html',
        },
      });
      expect(b.id, 996);
      expect(b.title, 'Don Quijote');
      expect(b.author, 'Cervantes Saavedra, Miguel de');
      expect(b.coverUrl, 'https://gutenberg.org/cover.jpg');
      expect(b.htmlUrl, 'https://gutenberg.org/996.html');
      expect(b.subjects, ['Fiction', 'Spanish literature']);
    });

    test('multiple authors usa el primero', () {
      final b = LiteraryBook.fromGutendexJson({
        'id': 1, 'title': 't',
        'authors': [
          {'name': 'First Author'},
          {'name': 'Second Author'},
        ],
        'formats': {},
      });
      expect(b.author, 'First Author');
    });

    test('authors vacío → author ""', () {
      final b = LiteraryBook.fromGutendexJson({
        'id': 1, 'title': 't',
        'authors': [],
        'formats': {},
      });
      expect(b.author, '');
    });

    test('authors null → author ""', () {
      final b = LiteraryBook.fromGutendexJson({
        'id': 1, 'title': 't',
        'formats': {},
      });
      expect(b.author, '');
    });

    test('fallback htmlUrl con charset', () {
      final b = LiteraryBook.fromGutendexJson({
        'id': 1, 'title': 't',
        'formats': {
          'text/html; charset=utf-8': 'https://x/book-utf8.html',
        },
      });
      expect(b.htmlUrl, 'https://x/book-utf8.html');
    });

    test('mapa vacío usa defaults', () {
      final b = LiteraryBook.fromGutendexJson({});
      expect(b.id, 0);
      expect(b.title, '');
      expect(b.author, '');
      expect(b.subjects, isEmpty);
    });
  });
}
