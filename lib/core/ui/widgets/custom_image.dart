import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../app_flavour.dart';
import '../../data/implementations/user_controller.dart';
import '../../domain/model/event.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/constants/app_route_constants.dart';


Widget customCachedNetworkHeroImage(mediaUrl) {
  AppUtilities.logger.v("Building hero widget for image url: $mediaUrl");
  return mediaUrl == AppFlavour.getNoImageUrl() ? Container(): Hero(
    //TODO Improve removing random int to get real hero functionality
    tag: 'img_${mediaUrl}_${Random().nextInt(1000)}',
    child: CachedNetworkImage(
      imageUrl: mediaUrl,
      fit: BoxFit.fill,
      errorWidget: (context,url,error) => const Icon(
        Icons.image_not_supported,
      ),
    ),
  );
}


Widget customCachedNetworkImage(mediaUrl) {
  AppUtilities.logger.i("Building cache network widget for image url: $mediaUrl");
  return CachedNetworkImage(
    imageUrl: mediaUrl,
    fit: BoxFit.fill,
    errorWidget: (context,url,error)=>const Icon(
        Icons.image_not_supported
    ),
  );
}


Widget customCachedNetworkEventImage(Event event, String mediaUrl,
    {bool goToDetails = true, String postId = ""}) {
  return GestureDetector(
    child: Hero(
      tag: '${event.id}_img_event_$mediaUrl',
      child: CachedNetworkImage(
        imageUrl: mediaUrl,
        fit: BoxFit.fitHeight,
        errorWidget: (context,url,error) => const Icon(
          Icons.error,
        ),
      ),
    ),
    onTap: () => {
      if(goToDetails)
        Get.toNamed(AppRouteConstants.eventDetails,arguments: [event, postId]),
    }

  );
}

Widget customCachedNetworkProfileImage(String profileId, String mediaUrl) {
  return GestureDetector(
    child: Hero(
      tag: '${profileId}_img_$mediaUrl',
      child: CachedNetworkImage(
        imageUrl: mediaUrl,
        fit: BoxFit.fitHeight,
        errorWidget: (context,url,error) => const Icon(Icons.error),
      ),
    ),
    onTap: () => Get.find<UserController>().profile.id != profileId ?
      Get.offAndToNamed(AppRouteConstants.mateDetails, arguments: profileId)
    : Get.offAndToNamed(AppRouteConstants.profileDetails, arguments: profileId),
  );
}


Widget fileImage(mediaUrl) {
  return GestureDetector(
    child: Hero(
      tag: 'img_file_hero_$mediaUrl',
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(File(mediaUrl)),
            fit: BoxFit.fitHeight,
          ),
        ),
      ),
    ),
    onTap: () => Get.to(() => FullScreenStoragedMedia(mediaUrl: mediaUrl)),
  );
}


Widget cachedNetworkThumbnail(thumbnailUrl, mediaUrl) {
  return GestureDetector(
    child: Hero(
      tag: 'thumbnail_$thumbnailUrl',
      child:CachedNetworkImage(
        imageUrl: thumbnailUrl,
        fit: BoxFit.cover,
        errorWidget: (context,url,error)=>const Icon(
          Icons.error,
        ),
      ),
    ),
    onTap: () => Get.to(() => FullScreenVideo(thumbnailUrl: thumbnailUrl,
        mediaUrl: mediaUrl),
        transition: Transition.zoom),
  );
}

class FullScreenStoragedMedia extends StatelessWidget {
  final String mediaUrl;
  const FullScreenStoragedMedia({required this.mediaUrl, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        child: Center(
          child: Hero(
              tag: 'img_hero_$mediaUrl',
              child: Image.file(File(mediaUrl)),
          ),
        ),
        onTap: () {
          Get.back();
        },
      ),
    );
  }
}

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
    _controller = VideoPlayerController.network(widget.mediaUrl!);
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
