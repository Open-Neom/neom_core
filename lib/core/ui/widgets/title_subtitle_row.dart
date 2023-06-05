import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_utilities.dart';
import '../../utils/constants/app_route_constants.dart';
import '../../utils/constants/app_translation_constants.dart';
import '../../utils/core_utilities.dart';
import 'custom_url_text.dart';

class TitleSubtitleRow extends StatelessWidget {

  final bool visibleSwitch, showDivider;
  final String navigateTo;
  final String url;
  final String subtitle, title;
  final Color textColor;
  final  Function? onPressed;
  final double vPadding, hPadding;

  const TitleSubtitleRow(
    this.title, {
    Key? key,
    this.navigateTo = "",
    this.url = "",
    this.subtitle = "",
    this.textColor = Colors.white70,
    this.onPressed,
    this.vPadding = 0,
    this.hPadding = 10,
    this.showDivider = true,
    this.visibleSwitch = true,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          contentPadding:
              EdgeInsets.symmetric(vertical: vPadding, horizontal: hPadding),
          onTap: () {
            if (onPressed != null) {
              onPressed!();
            }

            if(navigateTo.isNotEmpty) {
              navigateTo != AppRouteConstants.underConstruction ?
              Get.toNamed(navigateTo)
                  : AppUtilities.showAlert(context, title, AppTranslationConstants.underConstruction.tr);
            } else if(url.isNotEmpty) {
              CoreUtilities.launchURL(url);
            }
          },
          title: title.isNotEmpty ? UrlText(
            text: title,
            style: TextStyle(fontSize: 16, color: textColor, ),
          ) : Container(),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.justify,
          ),
        ),
        !showDivider ? const SizedBox() : const Divider(height: 0)
      ],
    );
  }
}
