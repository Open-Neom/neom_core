// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
//
// import '../../../utils/constants/app_constants.dart';
// import '../../../utils/constants/app_translation_constants.dart';
// import '../app_profile.dart';
// import 'neom_chamber_preset.dart';
//
// class NeomChamber {
//
//   String id;
//   String name;
//   String description;
//   String href;
//   String imgUrl;
//   bool public;
//   bool isFav;
//   List<NeomChamberPreset>? chamberPresets;
//   List<AppProfile>? profiles;
//
//   NeomChamber({
//     this.id = "",
//     this.name = "",
//     this.description = "",
//     this.href = "",
//     this.imgUrl = "",
//     this.public = true,
//     this.isFav = false,
//     this.chamberPresets,
//     this.profiles
//   });
//
//
//   @override
//   String toString() {
//     return 'NeomChamber{id: $id, name: $name, description: $description, href: $href, imgUrl: $imgUrl, public: $public, neomChamberPresets: $chamberPresets, neomProfiles: $profiles, isFav: $isFav}';
//   }
//
//   NeomChamber.myFirstNeomChamber() :
//     id = AppConstants.firstItemlist,
//     name = AppTranslationConstants.myFirstItemlistName.tr,
//     description = AppTranslationConstants.myFirstItemlistDesc.tr,
//     href = "",
//     imgUrl = "",
//     public = true,
//     chamberPresets = [NeomChamberPreset.myFirstNeomChamberPreset()],
//     isFav = true;
//
//
//   NeomChamber.createBasic(this.name, desc) :
//     id = "",
//     description = desc,
//     href = "",
//     imgUrl = "",
//     public = true,
//     chamberPresets = [],
//     isFav = false;
//
//   Map<String, dynamic>  toJSON()=>{
//     //'id': id, generated in firebase
//     'name': name,
//     'description': description,
//     'href': href,
//     'imgUrl': imgUrl,
//     'public': public,
//     'chamberPresets': chamberPresets?.map((preset) => preset.toJSON()).toList() ?? [],
//     'profiles': profiles?.map((profile) => profile.toJSON()).toList() ?? [],
//     'isFav': isFav
//   };
//
//    Map<String, dynamic>  toJsonDefault()=>{
//     'name': "Mi primera cámara Neom",
//     'description': "Aquí es donde agregarás las frecuencias que sueles contemplar.",
//     'href': "",
//     'imgUrl': "",
//     'public': true,
//     'isFav': true,
//   };
//
//   NeomChamber.fromJSON(data) :
//     id = data["id"],
//     name = data["name"],
//     description = data["description"],
//     href = data["href"],
//     imgUrl = data["imgUrl"],
//     public = data["public"],
//     isFav = data["isFav"];
// }
