import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../app_config.dart';
import '../../../app_properties.dart';
import '../../../domain/model/wordpress/blog_entry.dart';

class BlogEntriesApi {

  static Future<List<BlogEntry>> getBlogEntries({int perPage = 10, int page = 1}) async {

    List<BlogEntry> entries = [];
    final String url = '${AppProperties.getWordpressUrl()}/posts?page=$page&per_page=$perPage';

    try {
      final response = await http.get(
        Uri.parse(url),
        // headers: {
        //   'Accept': 'application/json',
        //   'User-Agent': 'Mozilla/5.0 (compatible; FlutterApp/1.0)',
        // },
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        final List<dynamic> data = jsonDecode(response.body);
        entries = data
            .map((item) => BlogEntry.fromJson(item as Map<String, dynamic>))
            .toList();
        AppConfig.logger.d('${entries.length} blog entries retrieved.');
      } else {
        AppConfig.logger.w('Failed to load blog entries: ${response.body}');
        throw Exception('Error loading blog entries');
      }
    } catch (e) {
      AppConfig.logger.e('Error retrieving blog entries: $e');
    }

    return entries;
  }

}
