import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_config.dart';
import '../../domain/model/ticket.dart';
import '../../domain/repository/ticket_repository.dart';
import '../../utils/neom_error_logger.dart';
import '../api/app_platform_api.dart';
import 'constants/app_firestore_collection_constants.dart';

class TicketFirestore implements TicketRepository {
  final FirebaseFirestore? _firestore;

  TicketFirestore({FirebaseFirestore? firestore}) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get ticketsReference =>
      (_firestore ?? FirebaseFirestore.instance)
          .collection(AppFirestoreCollectionConstants.tickets);

  List<Ticket> _parseTicketItems(dynamic res) {
    if (res is! Map) return <Ticket>[];
    final items = res['items'];
    if (items is! List) return <Ticket>[];
    return items
        .whereType<Map>()
        .map((m) => Ticket.fromJSON(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// Retrieves all tickets held by the signed-in attendee for [eventId].
  Future<List<Ticket>> getTicketsForEvent(String eventId) async {
    if (eventId.isEmpty) return <Ticket>[];
    if (AppPlatformApi.isEnabled) {
      try {
        final res = await AppPlatformApi.client('tickets').read(
          'getTicketForEvent',
          <String, Object?>{'eventId': eventId},
          private: true,
        );
        return _parseTicketItems(res);
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_core',
          operation: 'TicketFirestore.getTicketsForEvent.platform',
        );
        return <Ticket>[];
      }
    }
    return <Ticket>[];
  }

  /// Retrieves the signed-in attendee's ticket for [eventId] on the platform.
  Future<Ticket?> getTicketForEvent(String eventId) async {
    final list = await getTicketsForEvent(eventId);
    return list.isNotEmpty ? list.first : null;
  }

  /// Purchases [quantity] tickets for [eventId] using GigCoins (`1 GigCoin = $5 MXN`).
  Future<Ticket?> purchaseWithGigCoins({
    required String eventId,
    int quantity = 1,
    String buyerName = '',
    String tierName = 'General',
  }) async {
    if (!AppPlatformApi.isEnabled) return null;
    final res = await AppPlatformApi.client('tickets').mutate(
      'purchaseWithGigCoins',
      <String, Object?>{
        'eventId': eventId,
        'quantity': quantity,
        if (buyerName.isNotEmpty) 'buyerName': buyerName,
        'tierName': tierName,
      },
      durable: false,
    );
    if (res is Map) {
      final inner = res['value'];
      if (inner is Map) {
        return Ticket.fromJSON(Map<String, dynamic>.from(inner));
      }
      return Ticket.fromJSON(Map<String, dynamic>.from(res));
    }
    return null;
  }

  /// Scans an HMAC-signed QR ticket (`gmo://ticket/v1/...`) at the venue door.
  Future<Map<String, dynamic>> scanTicket({
    required String qrPayload,
    String eventId = '',
    int? checkInCount,
  }) async {
    if (!AppPlatformApi.isEnabled) {
      return <String, dynamic>{
        'allowed': false,
        'code': 'unsupported',
        'message': 'Escaneo disponible únicamente en servidor activo',
      };
    }
    final res = await AppPlatformApi.client('tickets').mutate(
      'scanTicket',
      <String, Object?>{
        'qrPayload': qrPayload.trim(),
        if (eventId.isNotEmpty) 'eventId': eventId,
        if (checkInCount != null && checkInCount > 0) 'checkInCount': checkInCount,
      },
      durable: false,
    );
    if (res is Map) {
      final inner = res['value'];
      if (inner is Map) return Map<String, dynamic>.from(inner);
      return Map<String, dynamic>.from(res);
    }
    return <String, dynamic>{'allowed': false, 'code': 'invalid_response'};
  }

  @override
  Future<String> addTicket(Ticket ticket) async {
    AppConfig.logger.d("TicketFirestore.addTicket: eventId ${ticket.eventId}, buyer ${ticket.buyerProfileId}");
    if (AppPlatformApi.isEnabled) {
      return ticket.id;
    }
    try {
      final docRef = ticketsReference.doc();
      ticket.id = docRef.id;
      await docRef.set(ticket.toJSON());
      AppConfig.logger.d("Ticket successfully created with ID: ${ticket.id}");
      return ticket.id;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'TicketFirestore.addTicket');
    }
    return '';
  }

  @override
  Future<Ticket?> getTicket(String ticketId) async {
    AppConfig.logger.d("TicketFirestore.getTicket: ticketId $ticketId");
    if (AppPlatformApi.isEnabled) {
      final mine = await getTicketsByBuyer('');
      final found = mine.where((t) => t.id == ticketId);
      return found.isNotEmpty ? found.first : null;
    }
    try {
      final doc = await ticketsReference.doc(ticketId).get();
      if (doc.exists && doc.data() != null) {
        return Ticket.fromJSON(doc.data()!);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'TicketFirestore.getTicket');
    }
    return null;
  }

  @override
  Future<List<Ticket>> getTicketsByEvent(String eventId) async {
    AppConfig.logger.d("TicketFirestore.getTicketsByEvent: eventId $eventId");
    if (AppPlatformApi.isEnabled) {
      try {
        final res = await AppPlatformApi.client('tickets').read(
          'getTicketsByEvent',
          <String, Object?>{'eventId': eventId},
          private: true,
        );
        return _parseTicketItems(res);
      } catch (e, st) {
        NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'TicketFirestore.getTicketsByEvent.platform');
        return <Ticket>[];
      }
    }
    final List<Ticket> tickets = [];
    try {
      final querySnapshot = await ticketsReference.where('eventId', isEqualTo: eventId).get();
      for (var doc in querySnapshot.docs) {
        tickets.add(Ticket.fromJSON(doc.data()));
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'TicketFirestore.getTicketsByEvent');
    }
    return tickets;
  }

  @override
  Future<List<Ticket>> getTicketsByBuyer(String buyerProfileId) async {
    AppConfig.logger.d("TicketFirestore.getTicketsByBuyer: buyerProfileId $buyerProfileId");
    if (AppPlatformApi.isEnabled) {
      try {
        final res = await AppPlatformApi.client('tickets').read(
          'getTicketsByBuyer',
          <String, Object?>{
            if (buyerProfileId.isNotEmpty) 'profileId': buyerProfileId,
          },
          private: true,
        );
        return _parseTicketItems(res);
      } catch (e, st) {
        NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'TicketFirestore.getTicketsByBuyer.platform');
        return <Ticket>[];
      }
    }
    final List<Ticket> tickets = [];
    try {
      final querySnapshot = await ticketsReference.where('buyerProfileId', isEqualTo: buyerProfileId).get();
      for (var doc in querySnapshot.docs) {
        tickets.add(Ticket.fromJSON(doc.data()));
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'TicketFirestore.getTicketsByBuyer');
    }
    return tickets;
  }

  @override
  Future<bool> checkInTicket(String ticketId) async {
    AppConfig.logger.d("TicketFirestore.checkInTicket: ticketId $ticketId");
    if (AppPlatformApi.isEnabled) {
      final res = await scanTicket(qrPayload: '{"ticketId":"$ticketId"}');
      return res['allowed'] == true;
    }
    try {
      await ticketsReference.doc(ticketId).update({
        'checkedIn': true,
        'checkInDate': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'TicketFirestore.checkInTicket');
    }
    return false;
  }
}
