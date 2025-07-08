import 'package:cloud_firestore/cloud_firestore.dart';

class Genre {

  String id = "";
  String name = "";
  String description = "";
  bool isMain = false;
  bool isFavorite = false;

  Genre({
    this.id = "",
    this.name = "",
    this.description = "",
    this.isMain = false,
    this.isFavorite = false
  });

  @override
  String toString() {
    return 'Genre{id: $id, name: $name, description: $description}';
  }

  static Genre fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json["id"],
      name: json["name"],
      description: json["description"],
    );
  }

  static Genre fromJsonDefault(Map<String, dynamic> json) {
    return Genre(
      id: json["name"],
      name: json["name"],
      description: json["description"],
    );
  }


  Genre.fromQueryDocumentSnapshot(QueryDocumentSnapshot queryDocumentSnapshot) :
    id = queryDocumentSnapshot.id,
    name = queryDocumentSnapshot.get("name"),
    description = queryDocumentSnapshot.get("description"),
    isMain = queryDocumentSnapshot.get("isMain"),
    isFavorite = queryDocumentSnapshot.get("isFavorite");

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'isMain': isMain,
      'isFavorite': isFavorite
    };
  }


  Genre.addBasic(this.name) :
    id = name,
    description = "";


  Genre.fromJSON(Map<dynamic, dynamic> data) :
    id = data["name"],
    name = data["name"],
    description = data["description"];


  static List<Genre> listFromJSON(List<String> genres) {
    List<Genre> genres = [];

    for (var genre in genres) {
      genres.add(Genre(name: genre.name));
    }

    return genres;
  }

}
