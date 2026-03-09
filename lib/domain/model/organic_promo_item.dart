import '../../utils/enums/app_in_use.dart';

class OrganicPromoItem {
  String id;
  AppInUse sourceApp;
  String itemType; // 'EventType', 'PostType', 'AppReleaseItemType'
  
  String title;
  String description;
  String mediaUrl;
  String deepLink; 
  
  OrganicPromoItem({
    required this.id,
    required this.sourceApp,
    required this.itemType,
    required this.title,
    required this.description,
    required this.mediaUrl,
    required this.deepLink,
  });

  factory OrganicPromoItem.fromJson(Map<String, dynamic> json) {
    return OrganicPromoItem(
      id: json['id'] ?? '',
      sourceApp: AppInUse.values.firstWhere(
        (e) => e.name == json['sourceApp'],
        orElse: () => AppInUse.a, // Default fallback
      ),
      itemType: json['itemType'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      mediaUrl: json['mediaUrl'] ?? '',
      deepLink: json['deepLink'] ?? '',
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
    };
  }
}
