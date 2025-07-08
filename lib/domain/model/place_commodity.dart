
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
        wifi = data["wifi"] ?? true,
        parking = data["parking"] ?? true,
        roomService = data["roomService"] ?? true,
        audioEquipment = data["audioEquipment"] ?? true,
        musicalInstruments = data["musicalInstruments"] ?? true,
        acousticConditioning = data['acousticConditioning'] ?? true,
        childAllowance = data["childAllowance"] ?? true,
        smokingAllowance = data["smokingAllowance"] ?? true,
        smokeDetector = data["smokeDetector"] ?? true,
        publicBathroom = data["publicBathroom"] ?? true,
        privateBathroom = data["privateBathroom"] ?? true,
        sharedPlace = data["sharedPlace"] ?? true;

}
