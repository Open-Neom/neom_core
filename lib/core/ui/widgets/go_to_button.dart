import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';

class GoToButton extends StatelessWidget {

  final String text;
  final Function()? onPressed;
  final bool isEnabled;
  final Color? color;
  final double fontSize;

  const GoToButton(this.text,{
    Key? key, this.onPressed,
    this.isEnabled = true, this.color, this.fontSize = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.fullHeight(context) * 0.08,
      width: AppTheme.fullWidth(context) * 0.58,
      decoration: BoxDecoration(
          color: AppColor.main50,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 2),
              blurRadius: 20.0,
            )
          ]
      ),
      child: TextButton(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(text,
                  style: const TextStyle(
                      fontSize: 20,
                      color: AppColor.white
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.white)
              ],
            ),
          ),
          onPressed: onPressed
      ),
    );
  }
}
