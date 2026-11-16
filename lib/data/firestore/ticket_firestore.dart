import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_config.dart';
import '../../domain/model/ticket.dart';
import '../../domain/repository/ticket_repository.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'core_firestore_guard.dart';

class TicketFirestore implements TicketRepository {
  CollectionReference<Map<String, dynamic>> get ticketsReference =>
      FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.tickets);

  @override
  Future<String> addTicket(Ticket ticket) async {
    AppConfig.logger.d("TicketFirestore.addTicket: eventId ${ticket.eventId}, buyer ${ticket.buyerProfileId}");
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
    final cleanId = ticketId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return null;
    AppConfig.logger.d("TicketFirestore.getTicket: ticketId $cleanId");
    try {
      final doc = await ticketsReference.doc(cleanId).get();
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
    final cleanEventId = eventId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanEventId)) return [];
    AppConfig.logger.d("TicketFirestore.getTicketsByEvent: eventId $cleanEventId");
    final List<Ticket> tickets = [];
    try {
      final querySnapshot = await ticketsReference
          .where('eventId', isEqualTo: cleanEventId)
          .limit(500)
          .get();
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
    final cleanBuyerId = buyerProfileId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanBuyerId)) return [];
    AppConfig.logger.d("TicketFirestore.getTicketsByBuyer: buyerProfileId $cleanBuyerId");
    final List<Ticket> tickets = [];
    try {
      final querySnapshot = await ticketsReference
          .where('buyerProfileId', isEqualTo: cleanBuyerId)
          .limit(500)
          .get();
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
    final cleanId = ticketId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.d("TicketFirestore.checkInTicket: ticketId $cleanId");
    try {
      await ticketsReference.doc(cleanId).update({
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
