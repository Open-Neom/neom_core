class WooProductAttribute {

  int id;
  String name;
  String slug;
  int position;
  bool visible;
  bool variation;
  List<String> options;

  WooProductAttribute({
    this.id = 0,
    this.name = '',
    this.slug = '',
    this.position = 0,
    this.visible = false,
    this.variation = false,
    this.options = const [],
  });

  factory WooProductAttribute.fromJSON(Map<String, dynamic> json) {
    return WooProductAttribute(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      position: json['position'] ?? 0,
      visible: json['visible'] ?? false,
      variation: json['variation'] ?? false,
      options: List<String>.from(json['options'] ?? []),
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'position': position,
      'visible': visible,
      'variation': variation,
      'options': options,
    };
  }
}
