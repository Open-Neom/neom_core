import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:hashtagable_v3/hashtagable.dart';
import '../../utils/app_color.dart';
import '../../utils/app_utilities.dart';
import '../../utils/core_utilities.dart';


class HashtagLinkText extends StatelessWidget {

  final String text;
  final int minLines;
  final int maxLines;
  final double fontSize;
  final double decoratedFontSize;
  final TextAlign textAlign;
  final bool onlyHashtag;

  const HashtagLinkText({
    required this.text,
    this.minLines = 3,
    this.maxLines = 10,
    this.fontSize = 15,
    this.decoratedFontSize = 16,
    this.textAlign = TextAlign.justify,
    this.onlyHashtag = false,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    bool containsURL = text.contains("http") || text.contains("https");
    return !onlyHashtag && containsURL?
    Linkify(
      text: text,
      onOpen: (link)  {
        CoreUtilities.launchURL(link.url);
      },
      maxLines: maxLines,
      style: TextStyle(fontSize: fontSize),
      linkStyle: TextStyle(fontSize: decoratedFontSize, color: AppColor.dodgetBlue),
      textAlign: textAlign,
      overflow: TextOverflow.ellipsis,
    ) :
    HashTagText(
      text: text,
      onTap: (text) => AppUtilities.logger.e(text),
      softWrap: true,
      maxLines: maxLines,
      basicStyle: const TextStyle(fontSize: 15),
      decoratedStyle: const TextStyle(fontSize: 16, color: AppColor.dodgetBlue),
      textAlign: textAlign,
      overflow: TextOverflow.ellipsis,
    );
  }

}
