import 'package:enum_to_string/enum_to_string.dart';

import '../../utils/enums/game_request_type.dart';
import '../../utils/enums/request_decision.dart';
import '../../utils/enums/request_type.dart';
import '../../utils/neom_error_logger.dart';
import 'event_offer.dart';
import 'instrument.dart';

class AppRequest {

  String id = "";
  String from = "";
  String to = "";
  String collectiveId = ""; //in case "from" is part of a collective
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

  /// Semantic kind of this request (release approval, change approval, game
  /// invitation, DAW invitation, or general collaboration). Persisted so
  /// consumers evaluate the enum directly instead of parsing the id.
  RequestType type = RequestType.collaboration;

  /// Generic payload for approval-gated requests (content edits, ERP sensitive
  /// changes, etc.). For change-approval requests it carries:
  /// `targetType`, `targetId`, `targetName`, `module`, and `changes` (map of
  /// field -> new value to apply on approval).
  Map<String, dynamic> payload = {};

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
      this.collectiveId = "",
      this.positionRequestedId = "",
      this.instrument,
      this.percentageCoverage = 0,
      this.distanceKm = 0,
      this.requestDecision = RequestDecision.pending,
      this.gameRequestType,
      this.type = RequestType.collaboration,
      Map<String, dynamic>? payload}) : payload = payload ?? {};


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

  /// Check if this is a game request.
  bool get isGameRequest => type == RequestType.gameInvitation;

  /// Check if this is a release approval request.
  bool get isReleaseApprovalRequest => type == RequestType.releaseApproval;

  /// Check if this is a generic change-approval request (content edits, ERP
  /// sensitive-data changes, etc.).
  bool get isChangeApprovalRequest => type == RequestType.changeApproval;

  /// What kind of entity the change targets (e.g. 'releaseItem', 'erpLead').
  String get changeTargetType => (payload['targetType'] ?? '').toString();

  /// Id of the entity being changed (falls back to eventId).
  String get changeTargetId => (payload['targetId'] ?? eventId).toString();

  /// Human-readable name of the target for review display.
  String get changeTargetName => (payload['targetName'] ?? '').toString();

  /// Map of field -> new value to apply when the change is approved.
  Map<String, dynamic> get changes => (payload['changes'] is Map)
      ? Map<String, dynamic>.from(payload['changes'] as Map)
      : <String, dynamic>{};

  /// Mutation kind for the change ('create', 'update', 'delete'); empty when
  /// the request is a plain field-diff edit.
  String get changeAction => (payload['action'] ?? '').toString();

  /// Module that originated the change (e.g. 'neom_books', 'neom_erp') — lets
  /// each domain load/approve only its own requests.
  String get changeModule => (payload['module'] ?? '').toString();

  /// Generic "change approval" request — gates sensitive edits behind review.
  /// Reusable across the ecosystem (content edits by non-admin users) and the
  /// ERP (approvals on sensitive financial/contact data).
  ///
  /// [from] - profileId of the requester
  /// [to] - reviewer queue (typically CoreConstants.appBot)
  /// [targetType] - entity kind ('releaseItem', 'erpLead', ...)
  /// [targetId] - id of the entity being changed
  /// [changes] - map of field -> new value (or full entity JSON) to apply
  /// [action] - mutation kind: 'create' | 'update' | 'delete' (optional)
  /// [extra] - additional payload keys merged in (optional)
  factory AppRequest.changeApproval({
    required String from,
    required String to,
    required String targetType,
    required String targetId,
    required Map<String, dynamic> changes,
    String? targetName,
    String? module,
    String? message,
    String? action,
    Map<String, dynamic>? extra,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return AppRequest(
      id: '${from}_change_$now',
      from: from,
      to: to,
      eventId: targetId,
      createdTime: now,
      message: message ?? 'Solicitud de cambio: "${targetName ?? targetId}"',
      requestDecision: RequestDecision.pending,
      type: RequestType.changeApproval,
      payload: {
        if (action != null) 'action': action,
        ...?extra,
        'targetType': targetType,
        'targetId': targetId,
        if (targetName != null) 'targetName': targetName,
        if (module != null) 'module': module,
        'changes': changes,
      },
    );
  }

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
      type: RequestType.gameInvitation,
    );
  }

  /// Default DAW invitation expiration (7 days).
  static const int defaultDawExpirationDays = 7;

  /// Create a DAW project collaboration invitation.
  ///
  /// [from] - profileId of the inviting user (project owner)
  /// [to] - profileId of the user being invited
  /// [projectId] - ID of the DawProject
  /// [projectName] - Name of the project for display
  /// [role] - Proposed role (producer, musician, listener)
  factory AppRequest.dawInvitation({
    required String from,
    required String to,
    required String projectId,
    required String projectName,
    String role = 'musician',
    String? message,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return AppRequest(
      id: '${from}_daw_$now',
      from: from,
      to: to,
      eventId: projectId,
      createdTime: now,
      expiresAt: now + (defaultDawExpirationDays * 24 * 60 * 60 * 1000),
      message: message ?? 'Invitación al proyecto "$projectName" como $role',
      requestDecision: RequestDecision.pending,
      type: RequestType.dawInvitation,
    );
  }

  /// Check if this is a DAW collaboration invitation.
  bool get isDawInvitation => type == RequestType.dawInvitation;

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
      type: RequestType.releaseApproval,
    );
  }

  @override
  String toString() {
    return 'AppRequest{id: $id, from: $from, to: $to, collectiveId: $collectiveId, eventId: $eventId, createdTime: $createdTime, expiresAt: $expiresAt, newOffer: $newOffer, message: $message, unread: $unread, instrument: $instrument, percentageCoverage: $percentageCoverage, distanceKm: $distanceKm, requestDecision: $requestDecision, gameRequestType: $gameRequestType, type: $type}';
  }


  AppRequest.fromJSON(dynamic data) {
    try {
      id = data["id"] ?? "";
      from = data["from"] ?? "";
      to = data["to"] ?? "";
      createdTime = data["createdTime"] ?? 0;
      expiresAt = data["expiresAt"] ?? 0;
      if(data["newOffer"] != null) {
        newOffer = EventOffer.fromJSON(data["newOffer"]);
      }
      message = data["message"] ?? "";
      unread = data["unread"] ?? true;
      collectiveId = data["collectiveId"] ?? "";
      eventId = data["eventId"] ?? "";
      positionRequestedId = data["positionRequestedId"] ?? "";
      instrument = data["instrument"] != null ? Instrument.fromJSON(data["instrument"]) : null;
      percentageCoverage = double.parse((data["percentageCoverage"] ?? '0').toString());
      distanceKm = data["distanceKm"] ?? 0;
      requestDecision = EnumToString.fromString(RequestDecision.values, data["requestDecision"] ?? RequestDecision.pending.name) ?? RequestDecision.pending;
      gameRequestType = data["gameRequestType"] != null
          ? EnumToString.fromString(GameRequestType.values, data["gameRequestType"])
          : null;
      payload = (data["payload"] is Map)
          ? Map<String, dynamic>.from(data["payload"] as Map)
          : {};
      type = EnumToString.fromString(RequestType.values, data["type"] ?? RequestType.collaboration.name)
          ?? RequestType.collaboration;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'AppRequest.fromJSON');
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
    'collectiveId': collectiveId,
    'instrument': instrument?.toJSON(),
    'percentageCoverage': percentageCoverage,
    'distanceKm': distanceKm,
    'requestDecision': requestDecision.name,
    'positionRequestedId': positionRequestedId,
    'gameRequestType': gameRequestType?.name,
    'type': type.name,
    'payload': payload,
  };

  AppRequest copyWith({
    String? id,
    String? from,
    String? to,
    String? collectiveId,
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
    RequestType? type,
    Map<String, dynamic>? payload,
  }) {
    return AppRequest(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      collectiveId: collectiveId ?? this.collectiveId,
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
      type: type ?? this.type,
      payload: payload ?? this.payload,
    );
  }
}
