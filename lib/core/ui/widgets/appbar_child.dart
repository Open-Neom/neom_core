import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_color.dart';
import '../../utils/app_theme.dart';


// ignore: must_be_immutable
class AppBarChild extends StatelessWidget implements PreferredSizeWidget {

  final String title;
  Color? color;
  bool goBack;

  AppBarChild({this.title = "", this.color, this.goBack = false, Key? key}) : super(key: key);

  @override
  Size get preferredSize => AppTheme.appBarHeight;

  @override
  Widget build(BuildContext context) {

    color ??= AppColor.appBar;

    return AppBar(
      title: Text(title.capitalize ?? "", style: TextStyle(color: Colors.white.withOpacity(0.8),
          fontWeight: FontWeight.bold),
      ),
      backgroundColor: color,
      elevation: 0.0,
    );
  }

}
