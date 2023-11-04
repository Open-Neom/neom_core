import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app_flavour.dart';

class CircleAvatarRoutingImage extends StatelessWidget {

  final String toNamed;
  final String mediaUrl;
  final double radius;
  final int? height;
  final int? width;
  final dynamic arguments;
  final BoxFit fit;
  final bool enableRouting;

  const CircleAvatarRoutingImage({
    required this.mediaUrl, required this.toNamed,
    this.radius = 25, this.height, this.width,
    this.fit = BoxFit.cover, this.enableRouting = true,
    this.arguments, super.key,}
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(mediaUrl.isNotEmpty
          ? mediaUrl : AppFlavour.getNoImageUrl(),
          maxHeight: height,
          maxWidth: width,
        ),
        radius: radius,
      ),
      onTap: () => enableRouting
          ? Get.toNamed(toNamed, arguments: arguments)
          : {},
    );
  }

}
