
class FacilityCommodity {

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

  FacilityCommodity({
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
  
  
  FacilityCommodity.fromJSON(Map<dynamic, dynamic> data):
        wifi = data["wifi"] ?? true,
        parking = data["parking"] ?? true,
        roomService = data["roomService"] ?? false,
        audioEquipment = data["audioEquipment"] ?? true,
        musicalInstruments = data["musicalInstruments"] ?? false,
        acousticConditioning = data['acousticConditioning'] ?? false,
        childAllowance = data["childAllowance"] ?? false,
        smokingAllowance = data["smokingAllowance"] ?? false,
        smokeDetector = data["smokeDetector"] ?? false,
        publicBathroom = data["publicBathroom"] ?? true,
        privateBathroom = data["privateBathroom"] ?? false,
        sharedPlace = data["sharedPlace"] ?? true;
}
