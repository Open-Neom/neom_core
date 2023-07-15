import 'package:enum_to_string/enum_to_string.dart';

import '../../../utils/enums/scale_degree.dart';

class NeomFrequency {

  String id;
  String name;
  String description;
  double frequency;
  ScaleDegree scaleDegree;
  bool isRoot;
  bool isMain;
  bool isFav;


  NeomFrequency({
    this.id = "",
    this.name = "",
    this.description = "",
    this.frequency = 432,
    this.scaleDegree = ScaleDegree.tonic,
    this.isRoot = false,
    this.isMain = false,
    this.isFav = false
  });


  @override
  String toString() {
    return 'NeomFrequency{id: $id, name: $name, description: $description, frequency: $frequency, scaleDegree: $scaleDegree, isRoot: $isRoot, isMain: $isMain, isFav: $isFav}';
  }

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'id': frequency,
      'name': name,
      'scaleDegree': EnumToString.convertToString(scaleDegree),
      'isRoot': isRoot,
      'isMain': isMain,
      'frequency': frequency,
      'isFav': isFav,
      'description': description,
    };
  }

  NeomFrequency.fromJSON(data) :
    id = data["id"].toString(),
    name = data["name"] ?? "",
    description = data["description"] ?? "",
    frequency = double.parse(data["frequency"].toString()),
    scaleDegree = EnumToString.fromString(ScaleDegree.values, data["scaleDegree"] ?? ScaleDegree.tonic.name) ?? ScaleDegree.tonic,
    isRoot = data["isRoot"] ?? false,
    isMain = data["isMain"] ?? false,
    isFav = data["isFav"] ?? false;

  NeomFrequency.fromAssetJSON(data) :
        id = data["frequency"] ?? "",
        name = data["name"] ?? "",
        description = "${data["description"] ?? ""}  ${data["nature"] ?? ""} ${data["medicine"] ?? ""} ${data["technology"] ?? ""} ${data["science"] ?? ""} ${data["spiritual"] ?? ""} ${data["misticism"] ?? ""}".trim(),
        frequency = double.parse(data["frequency"].toString()),
        scaleDegree = EnumToString.fromString(ScaleDegree.values, data["scaleDegree"] ?? ScaleDegree.tonic.name) ?? ScaleDegree.tonic,
        isRoot = data["isRoot"] ?? false,
        isMain = data["isMain"] ?? false,
        isFav = data["isFav"] ?? false;

}
