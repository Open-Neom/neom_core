import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../utils/app_color.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/constants/app_translation_constants.dart';
import 'appbar_child.dart';
import 'video_play_button.dart';

class FullScreenVideo extends StatefulWidget {

  final String? thumbnailUrl;
  final String? mediaUrl;
  const FullScreenVideo({this.thumbnailUrl, this.mediaUrl, super.key});

  @override
  FullScreenVideoState createState() => FullScreenVideoState();
}

class FullScreenVideoState extends State<FullScreenVideo> {

  late VideoPlayerController controller;
  late Stream<Duration> durationStream;
  final DeviceOrientation currentOrientation = DeviceOrientation.portraitUp;
  bool isLoading = true;
  bool isPlaying = false;
  bool isFullScreen = false;
  
  @override
  void initState() {
    super.initState();   
    controller = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl ?? ''))
      ..initialize().then((_) {
        /// Ensure the first frame is shown after the video is initialized,
        /// even before the play button has been pressed.
        setState(() {
          isLoading = false;
        });
      });

    controller.play().then((_) {
      setState(() {
        isPlaying = true;
      });
    });


    durationStream = Stream<Duration>.periodic(const Duration(seconds: 1), (data) {
      return controller.value.position;
    });
  }

  @override
  void dispose() {
    super.dispose();
    // Ensure disposing of the VideoPlayerController to free up resources.
    controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown
    ]);
  }

    
  
  @override
  Widget build(BuildContext context) {

    double ratio = controller.value.aspectRatio;
    String aspectRatio = '';

    if(!isFullScreen) {
      if(ratio >= 1) {
        if(ratio == 1) {
          aspectRatio = '1:1';
        } else {
          aspectRatio = '16:9';
        }
        SystemChrome.setPreferredOrientations([]);
      } else {
        if(ratio == 0.8) {
          aspectRatio = '4:5';
        } else if(ratio >= 0.6 && ratio < 0.75) {
          aspectRatio = '2:3';
        } else if(ratio >= 0.4 && ratio < 0.6) {
          aspectRatio = '9:16';
        }

        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown
        ]);
      }

      AppUtilities.logger.i('Aspect Radio of video is $aspectRatio - $ratio');
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColor.main50,
      appBar: AppBarChild(color: Colors.transparent),
      body: Container(decoration: AppTheme.appBoxDecoration,
        child: !isLoading ? Center(
            child: controller.value.isInitialized
                ? AspectRatio(
              aspectRatio: ratio,
              child: Stack(
                children: [
                  VideoPlayer(controller),
                  buildControlsOverlay(),
                  Positioned(bottom: 0, right: 0, left: 0,
                    child: VideoProgressIndicator(controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: 10)
                    ),
                  ),
              ],)
            ) : Container(),
          ) : Stack(
              children: [
                Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.thumbnailUrl!,
                    width: AppTheme.fullWidth(context),
                    fit: BoxFit.fitWidth,),
                ),
                const Center(child: CircularProgressIndicator(),),
              ]
          ),
      ),
    );
  }

  Widget buildControlsOverlay() {
    return Stack(
      children: <Widget>[
        if(!isPlaying) const VideoPlayButton(),
        GestureDetector(
          onTap: () {
            setState(() {
              isPlaying ? controller.pause() : controller.play();
              isPlaying = !isPlaying;
            });
          },
          onDoubleTap: () => Navigator.pop(context),
        ),
        StreamBuilder<Duration>(
          stream: durationStream,
          builder: (BuildContext context, AsyncSnapshot<Duration> snapshot) {
            if (snapshot.hasData) {
              return Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15,),
                  child: Text('${AppUtilities.getDurationInMinutes(snapshot.data!.inMilliseconds)} / ${AppUtilities.getDurationInMinutes(controller.value.duration.inMilliseconds)}',),
                ),
              );
            } else {
              return Container();
            }
          },
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: PopupMenuButton<double>(
            initialValue: controller.value.playbackSpeed,
            color: AppColor.getMain(),
            tooltip: AppTranslationConstants.playbackSpeed,
            onSelected: (double speed) {
              controller.setPlaybackSpeed(speed);
              setState(() {});
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<double>>[
                for (final double speed in AppConstants.playbackRates)
                  PopupMenuItem<double>(
                    value: speed,
                    child: Text('${speed}x'),
                  )
              ];
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15,),
              child: Text('${controller.value.playbackSpeed}x'),
            ),
          ),
        ),
        ///TO ADD
        // Align(
        //   alignment: Alignment.bottomRight,
        //   child: Container(
        //       padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15,),
        //       child: IconButton(
        //         icon: const Icon(Icons.fullscreen),
        //         onPressed: _onFullscreenIconButtonTap,
        //       ),
        //     ),
        // ),
      ],
    );
  }

  // void _onFullscreenIconButtonTap() {
  //   if (currentOrientation == DeviceOrientation.portraitUp) {
  //     SystemChrome.setPreferredOrientations([
  //       DeviceOrientation.landscapeLeft,
  //     ]);
  //   } else {
  //     SystemChrome.setPreferredOrientations([currentOrientation]);
  //   }
  // }

}
