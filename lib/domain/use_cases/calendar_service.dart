import 'package:flutter/material.dart';
import '../model/event.dart';

/// Abstract calendar service interface.
///
/// Implemented by neom_calendar's CalendarController.
/// Consumed by any module that needs calendar functionality (neom_booking, etc.)
/// without importing neom_calendar directly.
abstract class CalendarService {
  void setSelectedDays();
  void onDaySelected(DateTime selectedDay, DateTime fDay);
  Widget buildEventsMarker(DateTime date, dynamic events);
  List<Event> getEventsForDay(DateTime day);
  bool eventDaysContains(DateTime day);
  Future<void> fetchEvents();
}
