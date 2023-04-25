
import '../google_book.dart';

class BookVolume {

  String? kind;
  int? totalBooks;
  List<GoogleBook>? books;

  BookVolume({
    String? kind,
    int? totalBooks,
    List<GoogleBook>? books,
  });

  BookVolume.fromJson(dynamic json) {
    kind = json['kind'];
    totalBooks = json['totalItems'];
    if (json['items'] != null) {
      books = [];
      json['items'].forEach((v) {
        books?.add(GoogleBook.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['kind'] = kind;
    map['totalItems'] = totalBooks;
    if (books != null) {
      map['items'] = books?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}
