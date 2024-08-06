class WooProductCategory {
  final int id;
  final String name;
  final String slug;

  WooProductCategory({
    this.id = 0,
    this.name = '',
    this.slug = '',
  });

  factory WooProductCategory.fromJSON(Map<String, dynamic> json) {
    return WooProductCategory(
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
