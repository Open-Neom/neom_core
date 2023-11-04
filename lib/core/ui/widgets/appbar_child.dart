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

  AppBarChild({this.title = "", this.preTitle, this.color, this.leadingWidget, this.actionWidgets, super.key});

  @override
  Size get preferredSize => AppTheme.appBarHeight;
  @override
  Widget build(BuildContext context) {

    color ??= AppColor.appBar;

    ///DEPRECATED
    // Widget defaultLeading = IconButton(
    //     padding: EdgeInsets.zero,
    //     icon: const Icon(Icons.arrow_back,
    //       color: Colors.white70,
    //     ),
    //     onPressed: () {
    //       Navigator.pop(context);
    //     Navigator.pop(context);
    //
    //     }
    // );
    //
    // leadingWidget ??= defaultLeading;

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
    );
  }

}
