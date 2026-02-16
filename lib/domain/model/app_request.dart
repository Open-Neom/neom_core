import 'package:enum_to_string/enum_to_string.dart';


import '../../app_config.dart';
import '../../utils/enums/game_request_type.dart';
import '../../utils/enums/request_decision.dart';
import 'event_offer.dart';
import 'instrument.dart';

class AppRequest {

  String id = "";
  String from = "";
  String to = "";
  String bandId = ""; //in case "from" is part of a colective or band
  String eventId = ""; //event or room (roomId for games: {hostId}_{gameType}_{guestId})
  String positionRequestedId = "";
  int createdTime = 0;
  int expiresAt = 0; // For time-sensitive requests like game invitations
  EventOffer? newOffer;
  String message = "";
  bool unread = true;
  Instrument? instrument;
  double percentageCoverage = 0;
  int distanceKm = 0;
  RequestDecision requestDecision = RequestDecision.pending;
  GameRequestType? gameRequestType; // For game-related requests

  AppRequest({
      this.id = "",
      this.from = "",
      this.to = "",
      this.createdTime = 0,
      this.expiresAt = 0,
      this.newOffer,
      this.message = "",
      this.unread = true,
      this.eventId = "",
      this.bandId = "",
      this.positionRequestedId = "",
      this.instrument,
      this.percentageCoverage = 0,
      this.distanceKm = 0,
      this.requestDecision = RequestDecision.pending,
      this.gameRequestType});


  /// Check if request has expired (for game invitations)
  bool get isExpired => expiresAt > 0 && DateTime.now().millisecondsSinceEpoch > expiresAt;

  /// Check if request is still pending and not expired
  bool get isPending => requestDecision == RequestDecision.pending && !isExpired;

  /// Get time remaining until expiration
  Duration get timeRemaining {
    if (expiresAt == 0) return Duration.zero;
    final remaining = expiresAt - DateTime.now().millisecondsSinceEpoch;
    return Duration(milliseconds: remaining > 0 ? remaining : 0);
  }

  /// Check if this is a game request
  bool get isGameRequest => gameRequestType != null;

  /// Check if this is a release approval request
  /// Release approval requests have eventId (releaseItemId) and id containing '_release_'
  bool get isReleaseApprovalRequest => id.contains('_release_') && eventId.isNotEmpty && gameRequestType == null;

  /// Default game invitation expiration (3 minutes)
  static const int defaultGameExpirationMinutes = 3;

  /// Create a game invitation request
  factory AppRequest.gameInvitation({
    required String from,
    required String to,
    required GameRequestType gameType,
    String? message,
    int expirationMinutes = defaultGameExpirationMinutes,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Include timestamp in roomId to ensure each game session is unique
    final roomId = '${from}_${gameType.name}_${to}_$now';
    return AppRequest(
      id: '${from}_${to}_$now',
      from: from,
      to: to,
      eventId: roomId, // roomId format: {hostId}_{gameType}_{guestId}_{timestamp}
      createdTime: now,
      expiresAt: now + (expirationMinutes * 60 * 1000),
      message: message ?? '',
      gameRequestType: gameType,
      requestDecision: RequestDecision.pending,
    );
  }

  /// Create a release approval request (for books, songs, etc.)
  /// [from] - profileId of the author submitting the release
  /// [to] - app identifier (e.g., "EMXI", "Gigmeout") for admin review
  /// [releaseItemId] - ID of the AppReleaseItem being submitted
  /// [releaseName] - Name of the release for the message
  factory AppRequest.releaseApproval({
    required String from,
    required String to,
    required String releaseItemId,
    required String releaseName,
    String? authorName,
    String? message,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return AppRequest(
      id: '${from}_release_$now',
      from: from,
      to: to,
      eventId: releaseItemId, // Using eventId to store releaseItemId
      createdTime: now,
      message: message ?? 'Solicitud de aprobación: "$releaseName" por ${authorName ?? from}',
      requestDecision: RequestDecision.pending,
    );
  }

  @override
  String toString() {
    return 'AppRequest{id: $id, from: $from, to: $to, bandId: $bandId, eventId: $eventId, createdTime: $createdTime, expiresAt: $expiresAt, newOffer: $newOffer, message: $message, unread: $unread, instrument: $instrument, percentageCoverage: $percentageCoverage, distanceKm: $distanceKm, requestDecision: $requestDecision, gameRequestType: $gameRequestType}';
  }


  AppRequest.fromJSON(dynamic data) {
    try {
      from = data["from"] ?? "";
      to = data["to"] ?? "";
      createdTime = data["createdTime"] ?? data["createdTime"] ?? 0; // Support legacy createdTime
      expiresAt = data["expiresAt"] ?? 0;
      if(data["newOffer"] != null) {
        newOffer = EventOffer.fromJSON(data["newOffer"]);
      }
      message = data["message"] ?? "";
      unread = data["unread"] ?? "";
      bandId = data["bandId"] ?? "";
      eventId = data["eventId"] ?? "";
      positionRequestedId = data["positionRequestedId"] ?? "";
      instrument = data["instrument"] != null ? Instrument.fromJSON(data["instrument"]) : null;
      percentageCoverage = double.parse((data["percentageCoverage"] ?? '0').toString());
      distanceKm = data["distanceKm"] ?? 0;
      requestDecision = EnumToString.fromString(RequestDecision.values, data["requestDecision"] ?? RequestDecision.pending.name) ?? RequestDecision.pending;
      gameRequestType = data["gameRequestType"] != null
          ? EnumToString.fromString(GameRequestType.values, data["gameRequestType"])
          : null;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  Map<String, dynamic> toJSON()=>{
    'from': from,
    'to': to,
    'createdTime': createdTime,
    'expiresAt': expiresAt,
    'newOffer': newOffer?.toJSON(),
    'message': message,
    'unread': unread,
    'eventId': eventId,
    'bandId': bandId,
    'instrument': instrument?.toJSON(),
    'percentageCoverage': percentageCoverage,
    'distanceKm': distanceKm,
    'requestDecision': requestDecision.name,
    'positionRequestedId': positionRequestedId,
    'gameRequestType': gameRequestType?.name,
  };

  AppRequest copyWith({
    String? id,
    String? from,
    String? to,
    String? bandId,
    String? eventId,
    String? positionRequestedId,
    int? createdTime,
    int? expiresAt,
    EventOffer? newOffer,
    String? message,
    bool? unread,
    Instrument? instrument,
    double? percentageCoverage,
    int? distanceKm,
    RequestDecision? requestDecision,
    GameRequestType? gameRequestType,
  }) {
    return AppRequest(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      bandId: bandId ?? this.bandId,
      eventId: eventId ?? this.eventId,
      positionRequestedId: positionRequestedId ?? this.positionRequestedId,
      createdTime: createdTime ?? this.createdTime,
      expiresAt: expiresAt ?? this.expiresAt,
      newOffer: newOffer ?? this.newOffer,
      message: message ?? this.message,
      unread: unread ?? this.unread,
      instrument: instrument ?? this.instrument,
      percentageCoverage: percentageCoverage ?? this.percentageCoverage,
      distanceKm: distanceKm ?? this.distanceKm,
      requestDecision: requestDecision ?? this.requestDecision,
      gameRequestType: gameRequestType ?? this.gameRequestType,
    );
  }
}
