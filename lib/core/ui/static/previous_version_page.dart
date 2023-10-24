import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_theme.dart';
import '../../utils/constants/app_constants.dart';


class PreviousVersionPage extends StatelessWidget {
  const PreviousVersionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
        padding: const EdgeInsets.all(50),
        decoration: AppTheme.boxDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Text("${AppConstants.prevVersion1.tr} ${AppConstants.prevVersion2.tr}",
                style: const TextStyle(fontSize: 20), textAlign: TextAlign.justify,),
              AppTheme.heightSpace20,
              Text(AppConstants.prevVersion4.tr,
                style: const TextStyle(fontSize: 20), textAlign: TextAlign.end),
            ]
        ),
      ),
    );
  }
}
