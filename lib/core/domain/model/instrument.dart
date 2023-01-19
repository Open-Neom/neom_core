import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/instrument_level.dart';

class Instrument {

  String id;
  String name;
  InstrumentLevel instrumentLevel;
  bool isMain;
  bool isFavorite;
  String model;


  Instrument({
    this.id = "",
    this.name = "",
    this.instrumentLevel = InstrumentLevel.notDetermined,
    this.model = "",
    this.isMain = false,
    this.isFavorite = false
  });


  @override
  String toString() {
    return 'Instrument{instrumentId: $id, instrumentName: $name, instrumentLevel: $instrumentLevel, isMain: $isMain, isFavorite: $isFavorite, model: $model}';
  }

  static Instrument fromJsonDefault(Map<String, dynamic> json) {
    return Instrument(
      id: json["name"],
      name: json["name"], //name from Json File "name": "guitar"
      instrumentLevel: InstrumentLevel.notDetermined,
      isMain: false,
      isFavorite: false,
      model: "",
    );
  }

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'id': name,
      'name': name,
      'instrumentLevel': instrumentLevel.name,
      'isMain': isMain,
      'isFavorite': isFavorite,
      'model': model,
    };
  }


  Instrument.addBasic(this.name) :
    id = name,
    model = "",
    instrumentLevel = InstrumentLevel.notDetermined,
    isMain = false,
    isFavorite = true;


  Instrument.fromJSON(data) :
    id = data["name"] ?? "",
    name = data["name"] ?? "",
    instrumentLevel = EnumToString.fromString(InstrumentLevel.values, data["instrumentLevel"]) ?? InstrumentLevel.notDetermined,
    isMain = data["isMain"] ?? false,
    isFavorite = data["isFavorite"] ?? false,
    model = data["model"] ?? "";

}
