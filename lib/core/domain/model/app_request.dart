import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/app_utilities.dart';
import '../../utils/enums/request_decision.dart';
import 'event_offer.dart';
import 'instrument.dart';

class AppRequest {

  String id = "";
  String from = "";
  String to = "";
  String bandId = "";
  String eventId = "";
  String positionRequestedId = "";
  int createdTime = 0;
  EventOffer? newOffer;
  String message = "";
  bool unread = true;
  Instrument? instrument;
  double percentageCoverage = 0;
  int distanceKm = 0;
  RequestDecision requestDecision = RequestDecision.pending;

  AppRequest({
      this.id = "",
      this.from = "",
      this.to = "",
      this.createdTime = 0,
      this.newOffer,
      this.message = "",
      this.unread = true,
      this.eventId = "",
      this.bandId = "",
      this.positionRequestedId = "",
      this.instrument,
      this.percentageCoverage = 0,
      this.distanceKm = 0,
      this.requestDecision = RequestDecision.pending});


  @override
  String toString() {
    return 'AppRequest{id: $id, from: $from, to: $to, bandId: $bandId, eventId: $eventId, createdTime: $createdTime, newOffer: $newOffer, message: $message, unread: $unread, instrument: $instrument, percentageCoverage: $percentageCoverage, distanceKm: $distanceKm, requestDecision: $requestDecision}';
  }


  AppRequest.fromJSON(data) {
    try {
      from = data["from"] ?? "";
      to = data["to"] ?? "";
      createdTime = data["createdTime"] ?? 0;
      if(data["newOffer"] != null) {
        newOffer = EventOffer.fromJSON(data["newOffer"]);
      }
      message = data["message"] ?? "";
      unread = data["unread"] ?? "";
      bandId = data["bandId"] ?? "";
      eventId = data["eventId"] ?? "";
      positionRequestedId = data["positionRequestedId"] ?? "";
      instrument = data["instrument"] != null ? Instrument.fromJSON(data["instrument"]) : Instrument();
      percentageCoverage = data["percentageCoverage"] ?? 0.0;
      distanceKm = data["distanceKm"] ?? 0.0;
      requestDecision = EnumToString.fromString(RequestDecision.values, data["requestDecision"]) ?? RequestDecision.pending;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

  }

  Map<String, dynamic> toJSON()=>{
    'from': from,
    'to': to,
    'createdTime': createdTime,
    'newOffer': newOffer?.toJSON(),
    'message': message,
    'unread': unread,
    'eventId': eventId,
    'bandId': bandId,
    'instrument': instrument?.toJSON() ?? Instrument().toJSON(),
    'percentageCoverage': percentageCoverage,
    'distanceKm': distanceKm,
    'requestDecision': requestDecision.name,
    'positionRequestedId': positionRequestedId,
  };
}
