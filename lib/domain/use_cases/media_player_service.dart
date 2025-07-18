import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';

abstract class MediaPlayerService {

  bool get isVideoPlayerInitialized;
  bool get isVideoPlayerPlaying;
  double get aspectRatio;

  Future<void> initializeVideoPlayerController(File file);
  Future<void> playPauseVideo();
  void setIsPlaying({bool value = true});
  void disposeVideoPlayer();
  void visibleVideoAction();

  Widget getVideoPlayerContainer({required double height, required double width});

}
