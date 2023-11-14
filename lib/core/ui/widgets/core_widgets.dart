import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_color.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/message_translation_constants.dart';
import 'custom_widgets.dart';

Widget buildLabel(BuildContext context, String title, String msg){
  return Column(
    children: <Widget>[
      customText(title,
          context: context,
          style: const TextStyle(fontSize: 25,fontWeight: FontWeight.bold)
      ),
      AppTheme.heightSpace10,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: customText(msg, context: context,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white70),
            textAlign: TextAlign.center),
      ),
      AppTheme.heightSpace10,
    ],
  );
}

Widget buildActionChip({
  required appEnum, required Function controllerFunction,
  bool isActive = true, bool isSelected = false}) {
  return ActionChip(
    backgroundColor: isSelected ? AppColor.bondiBlue : AppColor.bottomNavigationBar,
    shape: AppTheme.outlinedBorderChip,
    label: Text((appEnum as Enum).name.tr.capitalizeFirst,
      style: TextStyle(
        fontSize: AppTheme.chipsFontSize,
        color: isActive ? null : AppColor.white50,
      ),
    ),
    onPressed:() {
      isActive ? controllerFunction(appEnum) :
      AppUtilities.showSnackBar(
        title: MessageTranslationConstants.underConstruction.tr,
        message: MessageTranslationConstants.featureAvailableSoon.tr,
      );
    },
  );
}

Widget buildTextActionChip({
  required String text, required Function controllerFunction,
  bool isActive = true, bool isSelected = false}) {
  return ActionChip(
    backgroundColor: isSelected ? AppColor.bondiBlue : AppColor.bottomNavigationBar,
    shape: AppTheme.outlinedBorderChip,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    label: Text(text.tr.capitalizeFirst,
      style: TextStyle(
        fontSize: AppTheme.chipsFontSize,
        color: isActive ? null : AppColor.white50,
      ),
    ),
    onPressed:() {
      isActive ? controllerFunction() :
      AppUtilities.showSnackBar(
        title: MessageTranslationConstants.underConstruction.tr,
        message: MessageTranslationConstants.featureAvailableSoon.tr,
      );
    },
  );
}

Widget buildIconActionChip({
  required Icon icon, required Function controllerFunction,
  bool isActive = true, bool isSelected = false}) {
  return ActionChip(
    backgroundColor: isSelected ? AppColor.bondiBlue : AppColor.bottomNavigationBar,
    shape: AppTheme.outlinedBorderChip,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    label: icon,
    onPressed:() {
      isActive ? controllerFunction() :
      AppUtilities.showSnackBar(
        title: MessageTranslationConstants.underConstruction.tr,
        message: MessageTranslationConstants.featureAvailableSoon.tr,
      );
    },
  );
}

Widget buildContainerTextField(String hint, {
  required TextEditingController controller,
  TextInputType textInputType = TextInputType.multiline,
  int maxLines = 1
}) {
  return Container(
      padding: const EdgeInsets.only(
          left: AppTheme.padding20,
          right: AppTheme.padding20
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: textInputType,
        minLines: 1,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: hint),
      )
  );
}
