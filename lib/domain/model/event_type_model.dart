import '../../utils/enums/event_type.dart';

class EventTypeModel {

  String imgAssetPath;
  EventType? type;

  EventTypeModel({this.imgAssetPath = "", this.type});

  @override
  String toString() {
    return 'EventTypeModel{imgAssetPath: $imgAssetPath, type: $type}';
  }

}
