class WooProductImage {
  final int id;
  final DateTime dateCreated;
  final DateTime dateCreatedGmt;
  final DateTime dateModified;
  final DateTime dateModifiedGmt;
  final String src;
  final String name;
  final String alt;

  WooProductImage({
    this.id = 0,
    DateTime? dateCreated,
    DateTime? dateCreatedGmt,
    DateTime? dateModified,
    DateTime? dateModifiedGmt,
    this.src = '',
    this.name = '',
    this.alt = '',
  })  : dateCreated = dateCreated ?? DateTime.now(),
        dateCreatedGmt = dateCreatedGmt ?? DateTime.now(),
        dateModified = dateModified ?? DateTime.now(),
        dateModifiedGmt = dateModifiedGmt ?? DateTime.now();

  factory WooProductImage.fromJSON(Map<String, dynamic> json) {
    return WooProductImage(
      id: json['id'] ?? 0,
      dateCreated: DateTime.tryParse(json['date_created'] ?? '') ?? DateTime.now(),
      dateCreatedGmt: DateTime.tryParse(json['date_created_gmt'] ?? '') ?? DateTime.now(),
      dateModified: DateTime.tryParse(json['date_modified'] ?? '') ?? DateTime.now(),
      dateModifiedGmt: DateTime.tryParse(json['date_modified_gmt'] ?? '') ?? DateTime.now(),
      src: json['src'] ?? '',
      name: json['name'] ?? '',
      alt: json['alt'] ?? '',
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'date_created': dateCreated.toIso8601String(),
      'date_created_gmt': dateCreatedGmt.toIso8601String(),
      'date_modified': dateModified.toIso8601String(),
      'date_modified_gmt': dateModifiedGmt.toIso8601String(),
      'src': src,
      'name': name,
      'alt': alt,
    };
  }
}
