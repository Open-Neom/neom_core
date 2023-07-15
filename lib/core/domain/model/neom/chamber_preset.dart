
import 'neom_frequency.dart';
import 'neom_parameter.dart';

class ChamberPreset {

  String id;
  String name;
  String description;
  String ownerId;
  String imgUrl;
  int state;
  NeomParameter? neomParameter;
  NeomFrequency? neomFrequency;

  ChamberPreset({
    this.id = "",
    this.name = "",
    this.description = "",
    this.imgUrl = "",
    this.ownerId = "",
    this.state = 0
  });


  @override
  String toString() {
    return 'ChamberPreset{id: $id, name: $name, description: $description, imgUrl: $imgUrl, ownerId: $ownerId, neomParameter: $neomParameter, neomFrequencies: $neomFrequency}';
  }


  ChamberPreset.fromJSON(Map<dynamic, dynamic> data) :
    id = data["id"] ?? "",
    name = data["name"] ?? "",
    description = data["description"] ?? "",
    ownerId = data["ownerId"] ?? "",
    imgUrl = data["imgUrl"] ?? "",
    state = data["state"] ?? 0,
    neomParameter = NeomParameter.fromJSON(data["neomParameter"]),
    neomFrequency = NeomFrequency.fromJSON(data["neomFrequency"]);


  Map<String, dynamic>  toJSON()=>{
    'id': id,
    'name': name,
    'description': description,
    'ownerId': ownerId,
    'imgUrl': imgUrl,
    'state': state,
    'neomParameter': neomParameter!.toJSON(),
    'neomFrequency': neomFrequency!.toJSON(),
  };

  Map<String, dynamic>  toJsonNoId()=>{
    'name': name,
    'description': description,
    'ownerId': ownerId,
    'imgUrl': imgUrl,
    'state': state,
    'neomParameter': neomParameter!.toJSON(),
    'neomFrequency': neomFrequency!.toJSON(),
  };

  ChamberPreset.myFirstNeomChamberPreset() :
    id = "",
    name = "Frecuencia 432 Hz",
    description = "",
    ownerId = "",
    imgUrl = "",
    state = 0,
    neomParameter = NeomParameter(),
    neomFrequency = NeomFrequency();

}
