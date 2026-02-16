import '../../utils/enums/booking_status.dart';


class Booking {

  String id;

  String profileId;
  String profileName;
  String profileImgUrl;

  String placeId;
  String eventId;
  int date;

  BookingStatus bookingStatus;

  String orderId;

  Booking({
      this.id = "",
      this.profileId = "",
      this.profileName = "",
      this.profileImgUrl = "",
      this.placeId = "",
      this.eventId = "",
      this.date = 0,
      this.bookingStatus = BookingStatus.notDefined,
      this.orderId = ""
    });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'id': id,
      'profileId': profileId,
      'profileName': profileName,
      'profileImgUrl': profileImgUrl,
      'placeId': placeId,
      'eventId': eventId,
      'date': date,
      'bookingStatus': bookingStatus.name,
      'orderId': orderId
    };
  }

  Booking.fromJSON(dynamic data) :
        id = data["id"] ?? "",
        profileId = data["profileId"] ?? "",
        profileName = data["profileName"] ?? "",
        profileImgUrl = data["profileImgUrl"] ?? "",
        placeId = data["placeId"] ?? "",
        eventId = data["eventId"] ?? "",
        date = data["date"] ?? 0,
        bookingStatus = data["bookingStatus"] ?? BookingStatus.notDefined,
        orderId = data["orderId"] ?? "";
}
