import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../utils/app_theme.dart';

class FullScreenVideo extends StatefulWidget {
  final String? thumbnailUrl;
  final String? mediaUrl;
  const FullScreenVideo({this.thumbnailUrl, this.mediaUrl, Key? key}) : super(key: key);

  @override
  FullScreenVideoState createState() => FullScreenVideoState();
}

class FullScreenVideoState extends State<FullScreenVideo> {

  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(decoration: AppTheme.appBoxDecoration,
        child: GestureDetector(
          child: Center(
            child: Hero(
                tag: 'thumbnail_${widget.thumbnailUrl}',
                child: FutureBuilder(
                  future: _initializeVideoPlayerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      // If the VideoPlayerController has finished initialization, use
                      // the data it provides to limit the aspect ratio of the VideoPlayer.
                      return AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        // Use the VideoPlayer widget to display the video.
                        child: VideoPlayer(_controller),
                      );
                    } else {
                      // If the VideoPlayerController is still initializing, show a
                      // loading spinner.
                      return Stack(
                          children: [
                            Center(child: CachedNetworkImage(
                                imageUrl: widget.thumbnailUrl!
                            ),),
                            const Center(child: CircularProgressIndicator(),),
                          ]
                      );
                    }
                  },
                )
            ),
          ),
          onTap: () {
            Get.back();
          },
        ),),
    );
  }

  @override
  void initState() {
    ///DEPRECATED _controller = VideoPlayerController.network(widget.mediaUrl!);
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl ?? ''));
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.play();
    super.initState();
  }

  @override
  void dispose() {
    // Ensure disposing of the VideoPlayerController to free up resources.
    _controller.dispose();
    super.dispose();
  }

}
