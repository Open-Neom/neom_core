

class EventActivity {

  String id;
  String name;
  String description;


  EventActivity({
    this.id = "",
    this.name = "",
    this.description = "",
  });


  @override
  String toString() {
    return 'EventActivity{id: $id, name: $name, description: $description}';
  }

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'id': name,
      'name': name,
      'description': description,
    };
  }

  EventActivity.fromJSON(data) :
    id = data["name"] ?? "",
    name = data["name"] ?? "",
    description = data["description"] ?? "";

}
