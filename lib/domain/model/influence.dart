class Influence {

  String id;
  String name;
  String thumbnailUrl;

  Influence({
    this.id = "",
    this.name = "",
    this.thumbnailUrl = "",
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  Influence.fromJSON(dynamic data)
      : id = data["id"] ?? "",
        name = data["name"] ?? "",
        thumbnailUrl = data["thumbnailUrl"] ?? "";

  @override
  String toString() => 'Influence{id: $id, name: $name}';
}
