import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/model/event.dart';
import '../../domain/model/post.dart';
import '../../utils/constants/app_route_constants.dart';
import '../../utils/constants/url_constants.dart';
import '../../utils/enums/post_type.dart';
import 'custom_image.dart';

class PostTile extends StatelessWidget {

  final Post post;
  final Event? event;

  const PostTile(this.post, this.event, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
    child: post.type == PostType.image ?
      customCachedNetworkHeroImage(post.mediaUrl)
        : post.type == PostType.video ?
      cachedNetworkThumbnail(post.thumbnailUrl, post.mediaUrl)
        : customCachedNetworkHeroImage(event?.imgUrl ?? UrlConstants.noImageUrl),
      onTap:()=> {
        //TODO VERIFY ITS WORKING
        //Get.delete<PostDetailsController>(),
        Get.toNamed(AppRouteConstants.postDetails, arguments: [post])
      }
    );
  }

}
//
