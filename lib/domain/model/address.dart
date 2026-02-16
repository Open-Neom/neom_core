import '../../app_config.dart';


class Address {

  String country;
  String state;
  String city;
  String neighborhood;
  String street;
  String placeNumber;
  String zipCode;

  Address({
    this.country = "",
    this.state = "",
    this.city = "",
    this.neighborhood = "",
    this.street = "",
    this.placeNumber = "",
    this.zipCode = ""
  });

  Map<String, dynamic> toJSON()=>{
    'country': country,
    'state': state,
    'city': city,
    'neighborhood': neighborhood,
    'street': street,
    'placeNumber': placeNumber,
    'zipCode': zipCode
  };

  Address.fromJSON(dynamic data):
        country = data["country"] ?? "",
        state = data["state"] ?? "",
        city = data["city"] ?? "",
        neighborhood = data["neighborhood"] ?? "",
        street = data["street"] ?? "",
        placeNumber = data["placeNumber"] ?? "",
        zipCode = data["zipCode"] ?? "";

  String getAddressSimple()  {
    AppConfig.logger.d("Getting address simple from address: ${toJSON().toString()}");

    String address = "";

    try {
      String locality = city;
      String administrativeArea = street;
      String country = this.country;

      locality.isNotEmpty ?
      address = "$locality, $country"
          : address = "$administrativeArea, $country" ;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return address;
  }

}
