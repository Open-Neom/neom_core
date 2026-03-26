/// Abstract interface for Google Calendar sync operations.
///
/// Implemented by neom_cloud's GoogleCalendarController.
/// Consumed by neom_booking, neom_events, neom_calendar via Sint DI
/// without importing neom_cloud directly.
///
/// Usage:
/// ```dart
/// if (Sint.isRegistered<GoogleCalendarSyncService>()) {
///   final calSync = Sint.find<GoogleCalendarSyncService>();
///   await calSync.createEvent(title: 'Ensayo', start: ..., end: ...);
/// }
/// ```
abstract class GoogleCalendarSyncService {

  /// Whether the user has linked their Google Calendar.
  bool get isLinked;

  /// Create an event in the user's Google Calendar.
  /// Returns the Google Calendar event ID (for linking back).
  Future<String> createEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    String description = '',
    String location = '',
    List<String> attendeeEmails = const [],
    String timeZone = 'America/Mexico_City',
  });

  /// Update an existing Google Calendar event.
  Future<bool> updateEvent({
    required String googleEventId,
    String? title,
    DateTime? start,
    DateTime? end,
    String? description,
    String? location,
  });

  /// Delete a Google Calendar event.
  Future<bool> deleteEvent(String googleEventId);

  /// List events in a date range from Google Calendar.
  Future<List<CalendarSyncEvent>> listEvents({
    required DateTime from,
    required DateTime to,
  });

  /// Sync: push a local event to Google Calendar.
  /// Returns the Google Calendar event ID.
  Future<String> pushEvent({
    required String localEventId,
    required String title,
    required DateTime start,
    required DateTime end,
    String description = '',
    String location = '',
  });

  /// Sync: pull Google Calendar events into local format.
  Future<List<CalendarSyncEvent>> pullEvents({
    required DateTime from,
    required DateTime to,
  });
}

/// Lightweight event representation for sync operations.
/// Avoids importing the full Event model from neom_core domain.
class CalendarSyncEvent {
  final String googleEventId;
  final String title;
  final DateTime start;
  final DateTime end;
  final String description;
  final String location;
  final List<String> attendeeEmails;
  final bool isAllDay;

  const CalendarSyncEvent({
    required this.googleEventId,
    required this.title,
    required this.start,
    required this.end,
    this.description = '',
    this.location = '',
    this.attendeeEmails = const [],
    this.isAllDay = false,
  });
}
