import 'package:get/get.dart';

import '../../utils/constants/app_assets.dart';
import '../../utils/constants/app_translation_constants.dart';

class SliderModel{
  String imagePath;
  String title;
  String msg1;
  String msg2;

  SliderModel(this.imagePath, this.title, this.msg1, {this.msg2 = ""});


  static List<SliderModel> getOnboardingSlides(){
    List<SliderModel> slides = [];
    SliderModel s1 = SliderModel(AppAssets.logoAppWhite,
        AppTranslationConstants.welcomeToApp.tr, AppTranslationConstants.welcomeToAppMsg.tr);
    SliderModel s2 = SliderModel(AppAssets.intro02,
        AppTranslationConstants.findItemmatesNearYourPlace.tr, AppTranslationConstants.findItemmatesNearYourPlaceMsg.tr);
    SliderModel s3 = SliderModel(AppAssets.intro03,
        AppTranslationConstants.letsGig.tr, AppTranslationConstants.letsGigMsg.tr);
    slides.add(s1);
    slides.add(s2);
    slides.add(s3);
    return slides;
  }

  static List<SliderModel> getRequiredPermissionsSlides(){
    List<SliderModel> slides = [];
    SliderModel s1 = SliderModel(AppAssets.intro02,
        AppTranslationConstants.locationRequiredTitle.tr, AppTranslationConstants.locationRequiredMsg1.tr,
        msg2: AppTranslationConstants.locationRequiredMsg2.tr);
    slides.add(s1);


    return slides;
  }

}
