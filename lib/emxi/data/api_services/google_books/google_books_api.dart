import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../domain/google_book.dart';
import '../../../domain/google_book/book_volume.dart';

class GoogleBooksApi {

  static String baseUrl = "https://www.googleapis.com/books/v1/volumes";
  static String langRestrict = "es";
  static int maxResults = 30;

  static Future getBooks() async {
    final response = await http.get(
      Uri.parse("$baseUrl?q=Fiction&maxResults=40&langRestrict=es"),
      // headers: headers,
    );

    var body = response.body;
    //print(body);
    return body;
  }

  static Future<List<GoogleBook>> searchBooks(String searchParam) async {
    final response = await http.get(
      Uri.parse("$baseUrl?q=$searchParam&langRestrict=es&maxResults=$maxResults"),
      // headers: headers,
    );

    var data = jsonDecode(response.body);
    BookVolume bookVolume = BookVolume.fromJson(data);

    return bookVolume.books ?? [];
  }

  static Future<BookVolume> searchBookVolume(String searchParam) async {
    final response = await http.get(
      Uri.parse("$baseUrl?q=$searchParam&langRestrict=es&maxResults=$maxResults"),
      // headers: headers,
    );

    var data = jsonDecode(response.body);
    return BookVolume.fromJson(data);

  }

  Future showBooksDetails({required String id}) async {
    final response = await http.get(
      Uri.parse("$baseUrl/$id"),
    );

    var body = response.body;
    return json.decode(body);
  }

}
