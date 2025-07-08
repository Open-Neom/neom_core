import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract class HomeService {

  void selectPageView(int index, {BuildContext context});
  Future<void> modalBottomSheetMenu(BuildContext context);
  void timelineIsReady({bool isReady = true});
  double getTimelineScrollOffset();

  int get currentIndex;
  set currentIndex(int index);

  bool get timelineReady;
  bool get mediaPlayerEnabled;

}
