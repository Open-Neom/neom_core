import '../model/app_item.dart';

abstract class EventDetailsService {

  Future<void> getEvent(String eventId);
  void getItemDetails(AppItem appItem);
  void setMessage(String text);
  void setNewOffer(String newAmount);
  void sendRequest();

}
