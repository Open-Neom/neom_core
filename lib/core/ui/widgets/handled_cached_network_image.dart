import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app_flavour.dart';
import '../../utils/constants/app_route_constants.dart';

class HandledCachedNetworkImage extends StatelessWidget {

  final String mediaUrl;
  final BoxFit fit;
  final double? height;
  final double? width;
  final bool enableFullScreen;

  const HandledCachedNetworkImage(this.mediaUrl, {
    this.fit = BoxFit.fill, this.height, this.width, this.enableFullScreen = true,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: CachedNetworkImage(
        imageUrl: mediaUrl.isNotEmpty ? mediaUrl : AppFlavour.getAppLogoUrl(),
        height: height,
        width: width,
        fit: fit,
        // placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context,url,error) => const Icon(Icons.image_not_supported),
      ),
      onTap: () => enableFullScreen
          ? Get.toNamed(AppRouteConstants.mediaFullScreen, arguments: [mediaUrl])
          : {}
    );
  }

}
