import '../../utils/enums/app_item_state.dart';
import '../model/app_media_item.dart';

abstract class EventDetailsService {

  Future<void> getEvent(String eventId);
  void getItemDetails(AppMediaItem appMediaItem);
  void setMessage(String text);
  void setNewOffer(String newAmount);
  void sendRequest();
  void setInstrumentToFulfill(String selectedInstrument);
  void addToMatchedItems(String itemId, AppItemState state);

}
