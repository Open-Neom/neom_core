import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CachedNetworkRoutingImage extends StatelessWidget {

  final String toNamed;
  final String mediaUrl;
  final String referenceId;
  final BoxFit fit;

  const CachedNetworkRoutingImage(context, {super.key,
    required this.toNamed, required this.mediaUrl,
    this.referenceId = "", this.fit = BoxFit.fitHeight});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          // child: Hero(
          //   tag: '${toNamed}_img_$referenceId',
            child: CachedNetworkImage(
              imageUrl: mediaUrl,
              fit: fit,
              errorWidget: (context,url,error) => const Icon(
                Icons.error,
              ),
            ),
          // ),
          onTap: () => {
            if(toNamed.isNotEmpty)
              Get.toNamed(toNamed, arguments: [referenceId]),
          }

      );
    }
}
