import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readmore/readmore.dart';
import '../../utils/constants/app_translation_constants.dart';


class ReadMoreContainer extends StatelessWidget {

  final String text;
  final int trimLines;
  final double fontSize;
  final double padding;
  final double letterSpacing;
  final Color? color;
  final bool isCollapsed;

  const ReadMoreContainer({
    this.text = '',
    this.trimLines = 5,
    this.fontSize = 16,
    this.padding = 10,
    this.letterSpacing = 0.5,
    this.color,
    this.isCollapsed = true,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: ReadMoreText(text,
        trimLines: trimLines,
        colorClickableText: Colors.grey.shade500,
        trimMode: TrimMode.Line,
        trimCollapsedText: ' ${AppTranslationConstants.readMore.tr.capitalizeFirst}',
        textAlign: TextAlign.justify,
        style: TextStyle(
          letterSpacing: letterSpacing,
          fontWeight: FontWeight.w500,
          fontSize: fontSize,
          color: color
        ),
        trimExpandedText: ' ${AppTranslationConstants.less.tr.capitalizeFirst}',
        isCollapsed: ValueNotifier(isCollapsed),
      ),
    );
  }

}
