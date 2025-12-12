import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';

abstract class MediaPlayerService {

  bool get isVideoPlayerInitialized;
  bool get isVideoPlayerPlaying;
  double get aspectRatio;

  Map<String, GlobalKey> get youtubeKeys;
  Map<String, GlobalKey> get videoKeys;
  Map<String, String> get spotifyTrackImgUrls;

  Future<void> initializeVideoPlayerController(File file);
  Future<void> playPauseVideo();
  // void setIsPlaying({bool value = true});
  void disposeVideoPlayer();
  void visibleVideoAction();

  Widget getVideoPlayerAspectRatio();

}
