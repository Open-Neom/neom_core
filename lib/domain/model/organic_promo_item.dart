import '../../app_properties.dart';
import '../../utils/enums/app_in_use.dart';

class OrganicPromoItem {
  String id;
  AppInUse sourceApp;
  String itemType; // 'EventType', 'PostType', 'AppReleaseItemType'

  String title;
  String description;
  String mediaUrl;
  String deepLink;
  String slug;

  OrganicPromoItem({
    required this.id,
    required this.sourceApp,
    required this.itemType,
    required this.title,
    required this.description,
    required this.mediaUrl,
    required this.deepLink,
    this.slug = '',
  });

  /// Build the web URL for this promo item.
  /// Uses slug if available, falls back to itemType/id.
  String get webUrl {
    final sourceUrl = AppProperties.getAppSourceUrl(sourceApp);
    if (sourceUrl.isEmpty) return '';

    // Use slug if available
    if (slug.isNotEmpty) return '$sourceUrl/$slug';

    // Try to extract slug from deepLink
    if (deepLink.isNotEmpty) {
      try {
        final uri = Uri.tryParse(deepLink);
        if (uri != null && uri.pathSegments.length >= 2) {
          return '$sourceUrl/${uri.pathSegments.sublist(1).join('/')}';
        }
      } catch (_) {}
    }

    // Fallback: build from itemType and id
    final type = _itemTypeToPath(itemType);
    if (type.isNotEmpty && id.isNotEmpty) {
      return '$sourceUrl/$type/$id';
    }

    return sourceUrl;
  }

  static String _itemTypeToPath(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'posttype': return 'post';
      case 'eventtype': return 'evento';
      case 'appreleaseitemtype': return 'obra';
      default: return '';
    }
  }

  factory OrganicPromoItem.fromJson(Map<String, dynamic> json) {
    return OrganicPromoItem(
      id: json['id'] ?? '',
      sourceApp: AppInUse.values.firstWhere(
        (e) => e.name == json['sourceApp'],
        orElse: () => AppInUse.a,
      ),
      itemType: json['itemType'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      mediaUrl: json['mediaUrl'] ?? '',
      deepLink: json['deepLink'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceApp': sourceApp.name,
      'itemType': itemType,
      'title': title,
      'description': description,
      'mediaUrl': mediaUrl,
      'deepLink': deepLink,
      'slug': slug,
    };
  }
}
