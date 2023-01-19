
import '../../domain/model/address.dart';
import '../../domain/model/place.dart';
import '../../domain/model/place_commodity.dart';
import '../../domain/model/price.dart';
import '../constants/app_static_img_urls.dart';
import '../enums/app_currency.dart';
import '../enums/place_type.dart';

class PlacesMockups {

  static List<Place> places = [
    Place(
      type: PlaceType.forum,
      galleryImgUrls: AppStaticImageUrls.warheadImgs,
      price: Price(amount: 150, currency: AppCurrency.mxn),
      address: Address(country: "México",
          state: "Jalisco",
          city: "Guadalajara",
          street: "Camaron de la Isla",
          placeNumber: "15",
          zipCode: "44600"),
      description: "HEHE",
      reviewStars: 4.2,
      placeCommodity: PlaceCommodity(acousticConditioning: true, parking: false),
      bookings: ["1","2","3","1","2","3","1","2","3"],
      reviews:["1","2","3","1","2","3","1","2","3"],
      ownerName: "Juan Efectivo",
      isActive: true,
      name: "WarHead"
    ),
    Place(
      type: PlaceType.forum,
      galleryImgUrls: AppStaticImageUrls.solazImgs,
      price: Price(amount: 250, currency: AppCurrency.mxn),
      address: Address(
          country: "México",
          state: "Jalisco",
          city: "Guadalajara",
          street: "Niños Heroes",
          placeNumber: "55",
          zipCode: "16025"),
      description: "OMG",
      reviewStars: 4.0,
      placeCommodity: PlaceCommodity(acousticConditioning: true, parking: false),
      bookings: ["1","2","3","1","2","3","1",],
      reviews:["1","2","3","1","2","3","1"],
      ownerName: "Juan Efectivo",
      isActive: true,
      name: "Solaz"
    ),
    Place(
        type: PlaceType.forum,
        galleryImgUrls: AppStaticImageUrls.ghettoBlasterImgs,
        price: Price(amount: 500, currency: AppCurrency.mxn),
        address: Address(
            country: "México",
            state: "Jalisco",
            city: "Guadalajara",
            street: "Washington",
            placeNumber: "212",
            zipCode: "16025"),
        description: "OMG",
        reviewStars: 5.0,
        placeCommodity: PlaceCommodity(acousticConditioning: true, parking: false),
        bookings: ["1","2","3"],
        reviews:["1","2","3"],
        ownerName: "Mephisto",
        isActive: true,
        name: "Ghettoblaster Productions"
    ),
  ];

}
