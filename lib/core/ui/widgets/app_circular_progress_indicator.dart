import 'package:flutter/material.dart';
import '../../app_flavour.dart';
import '../../utils/app_theme.dart';


class AppCircularProgressIndicator extends StatelessWidget {

  const AppCircularProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppFlavour.getIconPath(),
              height: AppTheme.fullWidth(context)/6,
              width: AppTheme.fullWidth(context)/6,
              fit: BoxFit.fitWidth,
            ),
            AppTheme.heightSpace20,
            const CircularProgressIndicator()
          ],
        )
    );
  }

}
