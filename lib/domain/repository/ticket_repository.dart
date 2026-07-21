import '../model/ticket.dart';

abstract class TicketRepository {
  Future<String> addTicket(Ticket ticket);
  Future<Ticket?> getTicket(String ticketId);
  Future<List<Ticket>> getTicketsByEvent(String eventId);
  Future<List<Ticket>> getTicketsByBuyer(String buyerProfileId);
  Future<bool> checkInTicket(String ticketId);
}
