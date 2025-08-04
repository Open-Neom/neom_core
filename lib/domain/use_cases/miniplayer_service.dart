import 'package:flutter/material.dart';
import '../model/app_media_item.dart';

abstract class MiniPlayerService {

  Future<void> setAppMediaItem(AppMediaItem appMediaItem);
  void setIsTimeline(bool value);
  void setShowInTimeline({bool value = true});
  StreamBuilder<Duration> positionSlider({bool isPreview = false});
  void goToMusicPlayerHome();
  void goToTimeline(BuildContext context);

}
