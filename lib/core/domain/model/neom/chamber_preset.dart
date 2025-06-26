import '../../../utils/constants/core_constants.dart';
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
    this.id = "432.0_0.5_0.0_0.0_0.0",
    this.name = "",
    this.description = "",
    this.imgUrl = "",
    this.ownerId = "",
    this.state = 0,
    this.neomParameter,
    this.neomFrequency
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
    neomParameter = NeomParameter.fromJSON(data["neomParameter"] ?? NeomParameter().toJSON()) ,
    neomFrequency = NeomFrequency.fromJSON(data["neomFrequency"] ?? NeomFrequency().toJSON());


  Map<String, dynamic>  toJSON()=>{
    'id': id,
    'name': name,
    'description': description,
    'ownerId': ownerId,
    'imgUrl': imgUrl,
    'state': state,
    'neomParameter': neomParameter?.toJSON(),
    'neomFrequency': neomFrequency?.toJSON(),
  };

  Map<String, dynamic>  toJsonNoId()=>{
    'name': name,
    'description': description,
    'ownerId': ownerId,
    'imgUrl': imgUrl,
    'state': state,
    'neomParameter': neomParameter?.toJSON(),
    'neomFrequency': neomFrequency?.toJSON(),
  };

  // ChamberPreset.myFirstNeomChamberPreset() :
  //   id = AppConstants.firstChamberPreset,
  //   name = "Frecuencia 432 Hz",
  //   description = "",
  //   ownerId = "",
  //   imgUrl = "https://firebasestorage.googleapis.com/v0/b/cyberneom-edd2d.appspot.com/o/AppStatics%2FCyberneom%20Icono.png?alt=media&token=68bc867f-df6c-40fb-a8fe-e920242c21a1",
  //   state = 1,
  //   neomParameter = NeomParameter(),
  //   neomFrequency = NeomFrequency();

  ChamberPreset.custom({String name = "", String imgUrl = "", NeomParameter? parameter, NeomFrequency? frequency}) :
        id = "${CoreConstants.customPreset}_${frequency?.frequency}",
        name = "",
        description = "",
        ownerId = "",
        imgUrl = imgUrl.isNotEmpty ? imgUrl : "https://firebasestorage.googleapis.com/v0/b/cyberneom-edd2d.appspot.com/o/AppStatics%2FCyberneom%20Icono.png?alt=media&token=68bc867f-df6c-40fb-a8fe-e920242c21a1",
        state = 5,
        neomParameter = parameter,
        neomFrequency = frequency;

  ChamberPreset clone() {
    return ChamberPreset.fromJSON(toJSON());
  }

}
