import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract class HomeService {

  void selectTab(int index, {BuildContext? context});
  Future<void> modalBottomAddMenu(BuildContext context);
  void timelineIsReady({bool isReady = true});
  double getTimelineScrollOffset();

  int get currentIndex;
  set currentIndex(int index);

  bool get timelineReady;
  bool get mediaPlayerEnabled;
  set mediaPlayerEnabled(bool enabled);

}
