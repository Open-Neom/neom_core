import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../utils/constants/app_constants.dart';
import '../../../utils/constants/app_translation_constants.dart';
import '../app_profile.dart';
import 'neom-chamber-preset.dart';

//TODO
//For future reference
class NeomChamber {

  String id;
  String name;
  String description;
  String href;
  String imgUrl;
  bool public;
  List<NeomChamberPreset>? neomChamberPresets;
  List<AppProfile>? neomProfiles;
  bool isFav;

  NeomChamber({
    this.id = "",
    this.name = "",
    this.description = "",
    this.href = "",
    this.imgUrl = "",
    this.public = true,
    this.neomChamberPresets,
    this.isFav = false
  });


  @override
  String toString() {
    return 'NeomChamber{id: $id, name: $name, description: $description, href: $href, imgUrl: $imgUrl, public: $public, neomChamberPresets: $neomChamberPresets, neomProfiles: $neomProfiles, isFav: $isFav}';
  }

  NeomChamber.myFirstNeomChamber() :
    id = AppConstants.firstItemlist,
    name = AppTranslationConstants.myFirstItemlistName.tr,
    description = AppTranslationConstants.myFirstItemlistDesc.tr,
    href = "",
    imgUrl = "",
    public = true,
    neomChamberPresets = [NeomChamberPreset.myFirstNeomChamberPreset()],
    isFav = true;


  NeomChamber.createBasic(name, desc) :
    id = "",
    name = name,
    description = desc,
    href = "",
    imgUrl = "",
    public = true,
    neomChamberPresets = [],
    isFav = false;


  NeomChamber.fromQueryDocumentSnapshot({required QueryDocumentSnapshot queryDocumentSnapshot}) :
    id = queryDocumentSnapshot.id,
    name = queryDocumentSnapshot.get("name"),
    description = queryDocumentSnapshot.get("description"),
    href = queryDocumentSnapshot.get("href"),
    imgUrl = queryDocumentSnapshot.get("imgUrl"),
    public = queryDocumentSnapshot.get("public"),
    isFav = queryDocumentSnapshot.get("isFav"),
    neomChamberPresets = queryDocumentSnapshot.get("neomChamberPresets").map<NeomChamberPreset>((item) {
              return NeomChamberPreset.fromMap(item);
            }).toList() ?? [];


  Map<String, dynamic>  toJSON()=>{
    //'id': id, generated in firebase
    'name': name,
    'description': description,
    'href': href,
    'imgUrl': imgUrl,
    'public': public,
    'neomChamberPresets': neomChamberPresets!.map((chamberPresets) => chamberPresets.toJSON()).toList(),
    'isFav': isFav
  };

   Map<String, dynamic>  toJsonDefault()=>{
    'name': "My First Neom Chamber",
    'description': "This is your first Neom Chamber. Start adding some presets",
    'href': "",
    'imgUrl': "",
    'public': true,
    'isFav': true,
  };

  NeomChamber.fromMap(Map<dynamic, dynamic> data) :
        id = data["id"],
        name = data["name"],
        description = data["description"],
        href = data["href"],
        imgUrl = data["imgUrl"],
        public = data["public"],
        isFav = data["isFav"];
}