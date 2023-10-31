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

  const ReadMoreContainer({
    this.text = '',
    this.trimLines = 5,
    this.fontSize = 16,
    this.padding = 10,
    this.letterSpacing = 0.5,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: ReadMoreText(text.capitalizeFirst,
        trimLines: trimLines,
        colorClickableText: Colors.grey.shade500,
        trimMode: TrimMode.Line,
        trimCollapsedText: AppTranslationConstants.readMore.tr,
        textAlign: TextAlign.justify,
        style: TextStyle(
          letterSpacing: letterSpacing,
          fontWeight: FontWeight.w500,
          fontSize: fontSize,
        ),
        trimExpandedText: ' ${AppTranslationConstants.less.tr.capitalize}',
      ),
    );
  }

}
