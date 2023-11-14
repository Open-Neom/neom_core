import 'dart:async';

import '../../utils/enums/event_type.dart';
import '../../utils/enums/usage_reason.dart';
import '../model/app_media_item.dart';
import '../model/app_profile.dart';
import '../model/band.dart';
import '../model/instrument.dart';

abstract class EventService {

  void setEventType(EventType eventType);

  void addInstrument(int index);
  void removeInstrument(int index);
  void createInstrumentFulfillment();

  void addAppMediaItem(AppMediaItem appMediaItem);
  void removeAppMediaItem(AppMediaItem appMediaItem);
  void addItemsToEvent();

  void setReason(UsageReason reason);
  void updateEventType(EventType eventType);
  void updateEventDate(DateTime dateTime);

  Future<void> createEvent();
  Future<void> createPostEvent();
  Future<void> getEventPlace(context);

  bool validateInfo();

  void addInfoToEvent();
  void setEventDate(DateTime date);
  void setCoverFree();
  void setIsOnlineCheckboxState();
  void setEventTime(context);
  void setPaymentAmount();

  void setEventName();

  void setEventDesc();
  void setEventMaxDistance();

  bool validateNameDesc();
  void gotoEventSummary();
  void addEventImage();

  void retrieveEvents();

  void setInstrumentToFulfill({String selectedInstr = ""});

  void setVocalTypeToFulfill(String vocalType);

  void addBandToFestival(Band band);
  void removeBandFromFestival(Band band);
  void addBandsToFestival();
  void setSelectedBand(Band selectedBand);
  void lookupForMusicians();
  void gotoBandDetails(Band band);

  Future<void> sendBandEventRequest(String bandId);
  Future<void> sendProfileEventInvitations();
  void addInvitedProfile(AppProfile mate, Instrument instr);
  void setCurrency(String chosenCurrency);
  void filterEventsBy({EventType eventType = EventType.any});

  void setMessage(String text);
  ///DEPRECATED Future<void> sendEventInvitation(AppProfile mate, Instrument instrument);
  void goWithFlyer();

  void addActivity(int index);
  void removeActivity(int index);
  void setDefaultNameDesc();

  Future<void> sendProfileInvitation(AppProfile mate, Instrument inst);
  bool isAlreadyInvited(String profileId);

}
