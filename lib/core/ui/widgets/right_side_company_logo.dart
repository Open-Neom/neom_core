import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../app_flavour.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_assets.dart';
import '../../utils/constants/app_translation_constants.dart';

class RightSideCompanyLogo extends StatelessWidget {
  const RightSideCompanyLogo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        child: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Center(child: Image.asset(
            AppAssets.logoCompanyWhite,
            height: 22.5, ///previous height: 60, width: 150,
            fit: BoxFit.fitHeight,
          ),),
        ),
        onTap: () async {
          AppUtilities.showAlert(context, message: "${AppTranslationConstants.version.tr} "
              "${AppFlavour.appVersion}${kDebugMode ? " - Dev Mode" : ""}");
        }
    );
  }
}
