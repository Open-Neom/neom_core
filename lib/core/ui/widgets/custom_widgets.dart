import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';



Widget customText(String msg,
    { Key? key,
      required TextStyle style,
      required BuildContext context,
      TextAlign textAlign = TextAlign.justify,
      TextOverflow overflow = TextOverflow.visible,
      bool softWrap = true}) {
  if (msg.isEmpty) {
    return const SizedBox(
      height: 0,
      width: 0,
    );
  } else {
    var fontSize = style.fontSize ?? Theme.of(context).textTheme.bodyMedium!.fontSize;
    style = style.copyWith(
      fontSize: fontSize! - (AppTheme.fullWidth(context) <= 375 ? 2 : 0),
    );
    return Text(
      msg,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      softWrap: softWrap,
      key: key,
    );
  }
}

Widget customInkWell(
    {required Widget child,
    required BuildContext context,
    Function(bool, int)? function1,
    Function? onPressed,
    bool isEnable = false,
    int no = 0,
    Color color = Colors.transparent,
    Color? splashColor,
    BorderRadius? radius}) {
  splashColor ??= Theme.of(context).primaryColorLight;
  radius ??= BorderRadius.circular(0);
  return Material(
    color: color,
    child: InkWell(
      borderRadius: radius,
      onTap: () {
        if (function1 != null) {
          function1(isEnable, no);
        } else if (onPressed != null) {
          onPressed();
        }
      },
      splashColor: splashColor,
      child: child,
    ),
  );
}

SizedBox sizedBox({double height = 5, String title = ""}) {
  return SizedBox(
    height: title.isEmpty ? 0 : height,
  );
}

Widget customNetworkImage(String path, {BoxFit fit = BoxFit.contain}) {
  return CachedNetworkImage(
    fit: fit,
    imageUrl: path,
    imageBuilder: (context, imageProvider) => Container(
      decoration: BoxDecoration(
          image: DecorationImage(
          image: imageProvider,
          fit: fit,
        ),
      ),
    ),
    placeholderFadeInDuration: const Duration(milliseconds: 250),
    placeholder: (context, url) => Container(
      color: const Color(0xffeeeeee),
    ),
    errorWidget: (context, url, error) => const Icon(Icons.error),
  );
}
