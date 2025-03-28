import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_color.dart';
import '../../utils/app_theme.dart';

// ignore: must_be_immutable
class AppBarChild extends StatelessWidget implements PreferredSizeWidget {

  Widget? preTitle;
  final String title;
  Color? color;
  Widget? leadingWidget;
  List<Widget>? actionWidgets;
  bool? centerTitle;

  AppBarChild({this.title = "", this.preTitle, this.color, this.leadingWidget, this.actionWidgets, this.centerTitle, super.key});

  @override
  Size get preferredSize => AppTheme.appBarHeight;
  @override
  Widget build(BuildContext context) {

    color ??= AppColor.appBar;
    return AppBar(
      leading: leadingWidget,
      title: Row(
        children: [
          if(preTitle != null) Row(children: [preTitle!, AppTheme.widthSpace10],),
          Text(title.capitalize, style: TextStyle(color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.bold),
          ),
        ],
      ),
      backgroundColor: color,
      elevation: 0.0,
      actions: actionWidgets,
      centerTitle: centerTitle,
    );
  }

}
