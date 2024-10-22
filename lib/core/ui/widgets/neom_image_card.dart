import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../utils/constants/app_assets.dart';

import '../../utils/enums/image_quality.dart';

class NeomImageCard extends StatelessWidget {

  final String imageUrl;
  final bool localImage;
  final double elevation;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double? boxDimension;
  final ImageProvider placeholderImage;
  final bool selected;
  final ImageQuality imageQuality;
  final Function(Object, StackTrace?)? localErrorFunction;

  const NeomImageCard({super.key,
    required this.imageUrl,
    this.localImage = false,
    this.elevation = 5,
    this.margin = EdgeInsets.zero,
    this.borderRadius = 7.0,
    this.boxDimension = 55.0,
    this.placeholderImage = const AssetImage(AppAssets.audioPlayerCover,),
    this.selected = false,
    this.imageQuality = ImageQuality.high,
    this.localErrorFunction,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      elevation: elevation,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox.square(
        dimension: boxDimension,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (localImage)
              Image.file(File(imageUrl,),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stacktrace) {
                  if (localErrorFunction != null) {
                    localErrorFunction!(error, stacktrace);
                  }
                  return Image(fit: BoxFit.cover, image: placeholderImage,);
                },
              )
            else
              CachedNetworkImage(
                fit: BoxFit.cover,
                errorWidget: (context, _, __) => Image(fit: BoxFit.cover, image: placeholderImage,),
                imageUrl: imageUrl,
                placeholder: (context, url) => Image(fit: BoxFit.cover, image: placeholderImage,),
              ),
            if (selected)
              Container(
                decoration: const BoxDecoration(color: Colors.black54,),
                child: const Center(child: Icon(Icons.check_rounded,),),
              ),
          ],
        ),
      ),
    );
  }

}
