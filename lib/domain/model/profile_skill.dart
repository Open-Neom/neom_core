import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/experience_level.dart';

class ProfileSkill {

  String id;
  String name;
  String description;
  ExperienceLevel experienceLevel;
  double price;

  ProfileSkill({
    this.id = '',
    this.name = '',
    this.description = '',
    this.experienceLevel = ExperienceLevel.beginner,
    this.price = 0,
  });

  ProfileSkill.addBasic(this.name) :
    id = name,
    description = '',
    experienceLevel = ExperienceLevel.beginner,
    price = 0;

  static ProfileSkill fromJsonDefault(Map<String, dynamic> json) {
    return ProfileSkill(
      id: json['name'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      experienceLevel: ExperienceLevel.beginner,
      price: 0,
    );
  }

  ProfileSkill.fromJSON(dynamic data) :
    id = data['name'] ?? '',
    name = data['name'] ?? '',
    description = data['description'] ?? '',
    experienceLevel = EnumToString.fromString(ExperienceLevel.values, data['experienceLevel']) ?? ExperienceLevel.beginner,
    price = (data['price'] ?? 0).toDouble();

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'id': name,
      'name': name,
      'description': description,
      'experienceLevel': experienceLevel.name,
      'price': price,
    };
  }

  String get priceDisplay => price > 0 ? '\$${price.toStringAsFixed(0)}' : '';

  @override
  String toString() {
    return 'ProfileSkill{id: $id, name: $name, experienceLevel: $experienceLevel, price: $price}';
  }
}
