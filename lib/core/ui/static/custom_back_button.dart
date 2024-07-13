import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_color.dart';
import '../../utils/app_theme.dart';

class CustomBackButton extends StatelessWidget {
  const CustomBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 4,
      top: 26,
      child: GestureDetector(
        onTap: () => Get.back(),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.padding10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.main25,
              border: Border.all(
                color: AppColor.main50,
              ),
              borderRadius: BorderRadius.circular(20.0)
            ),
            child: const BackButton()
          ),
        ),
      ),
    );
  }
}
