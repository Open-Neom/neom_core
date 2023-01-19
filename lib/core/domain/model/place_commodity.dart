
class PlaceCommodity {

  bool wifi;
  bool parking;
  bool roomService;
  bool audioEquipment;
  bool musicalInstruments;
  bool acousticConditioning;
  bool childAllowance;
  bool smokingAllowance;
  bool smokeDetector;
  bool publicBathroom;
  bool privateBathroom;
  bool sharedPlace;

  Map<String, dynamic> toJSON()=>{
    'wifi': wifi,
    'parking': parking,
    'roomService': roomService,
    'audioEquipment': audioEquipment,
    'musicalInstruments': musicalInstruments,
    'acousticConditioning': acousticConditioning,
    'childAllowance': childAllowance,
    'smokingAllowance': smokingAllowance,
    'smokeDetector': smokeDetector,
    'publicBathroom': publicBathroom,
    'privateBathroom': privateBathroom,
    'sharedPlace': sharedPlace,
  };

  PlaceCommodity({
      this.wifi = true,
      this.parking = true,
      this.roomService = false,
      this.audioEquipment = true,
      this.musicalInstruments = false,
      this.acousticConditioning = false,
      this.childAllowance = false,
      this.smokingAllowance = false,
      this.smokeDetector = false,
      this.publicBathroom = true,
      this.privateBathroom = false,
      this.sharedPlace = true
  });

  PlaceCommodity.fromJSON(Map<dynamic, dynamic> data):
        wifi = data["wifi"],
        parking = data["parking"],
        roomService = data["roomService"],
        audioEquipment = data["audioEquipment"],
        musicalInstruments = data["musicalInstruments"],
        acousticConditioning = data['acousticConditioning'],
        childAllowance = data["childAllowance"],
        smokingAllowance = data["smokingAllowance"],
        smokeDetector = data["smokeDetector"],
        publicBathroom = data["publicBathroom"],
        privateBathroom = data["privateBathroom"],
        sharedPlace = data["sharedPlace"];

}
