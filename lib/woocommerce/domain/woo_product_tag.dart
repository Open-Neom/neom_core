class WooProductTag {
  final int id;
  final String name;
  final String slug;

  WooProductTag({
    this.id = 0,
    this.name = '',
    this.slug = '',
  });

  factory WooProductTag.fromJSON(Map<String, dynamic> json) {
    return WooProductTag(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }

}
