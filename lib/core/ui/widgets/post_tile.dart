import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app_flavour.dart';
import '../../domain/model/event.dart';
import '../../domain/model/post.dart';
import '../../utils/constants/app_route_constants.dart';
import '../../utils/enums/post_type.dart';
import 'custom_image.dart';

class PostTile extends StatelessWidget {

  final Post post;
  final Event? event;

  const PostTile(this.post, this.event, {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
    child: post.type == PostType.image ?
      customCachedNetworkImage(post.mediaUrl)
        : post.type == PostType.video ?
      cachedVideoThumbnail(thumbnailUrl: post.thumbnailUrl, mediaUrl: post.mediaUrl)
        : customCachedNetworkImage(event?.imgUrl ?? AppFlavour.getNoImageUrl()),
      onTap:()=> {
        //TODO VERIFY ITS WORKING
        //Get.delete<PostDetailsController>(),
        Get.toNamed(AppRouteConstants.postDetailsFullScreen, arguments: [post])
      }
    );
  }

}
//
