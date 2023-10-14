import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../neom_commons.dart';
import 'domain/model/app_media_item.dart';

class AppFlavour {

  static AppInUse appInUse = AppInUse.emxi;
  static String appVersion = "";
  static dynamic appProperties = {};

  AppFlavour({required AppInUse inUse, required String version,}) {
    appInUse = inUse;
    appVersion = version;
  }

  static Future<void> readProperties(BuildContext context) async {
    final jsonString = await DefaultAssetBundle.of(context)
        .loadString(AppAssets.propertiesJsonPath);

    appProperties = jsonDecode(jsonString);
  }

  static String getAppLogoUrl() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['appLogoUrl'];
      case AppInUse.emxi:
        return appProperties['appLogoUrl'];
      case AppInUse.cyberneom:
        return appProperties['appLogoUrl'];
    }
  }

  static String getLinksUrl() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['linksUrl'];
      case AppInUse.emxi:
        return appProperties['linksUrl'];
      case AppInUse.cyberneom:
        return appProperties['linksUrl'];
    }
  }

  static String getPlayStoreUrl() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['playStoreUrl'];
      case AppInUse.emxi:
        return appProperties['playStoreUrl'];
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getAppStoreUrl() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['appStoreUrl'];
      case AppInUse.emxi:
        return appProperties['appStoreUrl'];
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getLandingPageUrl() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['landingPageUrl'];
      case AppInUse.emxi:
        return appProperties['landingPageUrl'];
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getTermsOfServiceUrl() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['termsOfServiceUrl'];
      case AppInUse.emxi:
        return appProperties['termsOfServiceUrl'];
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getPrivacyPolicyUrl() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['privacyPolicyUrl'];
      case AppInUse.emxi:
        return appProperties['privacyPolicyUrl'];
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getBlogUrl() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['blogUrl'];
      case AppInUse.emxi:
        return appProperties['blogUrl'];
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getWebContact() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['webContact'];
      case AppInUse.emxi:
        return appProperties['webContact'];
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getNoImageUrl() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['noImageUrl'];
      case AppInUse.emxi:
        return appProperties['noImageUrl'];
      case AppInUse.cyberneom:
        return appProperties['noImageUrl'];
    }
  }

  static IconData getAppItemIcon() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return Icons.music_note;
      case AppInUse.emxi:
        return Icons.book;
      case AppInUse.cyberneom:
        return FontAwesomeIcons.waveSquare;
    }
  }

  static IconData getInstrumentIcon() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return FontAwesomeIcons.guitar;
      case AppInUse.emxi:
        return FontAwesomeIcons.pencil;
      case AppInUse.cyberneom:
        return FontAwesomeIcons.waveSquare;
    }
  }

  static IconData getSyncIcon() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return FontAwesomeIcons.spotify;
      case AppInUse.emxi:
        return FontAwesomeIcons.bookOpenReader;
      case AppInUse.cyberneom:
        return Icons.sync;
    }
  }

  static String getItemDetailsRoute() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return AppRouteConstants.itemDetails;
      case AppInUse.emxi:
        return AppRouteConstants.bookDetails;
      case AppInUse.cyberneom:
        return AppRouteConstants.generator;
    }
  }

  static String getEventVector() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return AppAssets.bandVector01;
      case AppInUse.emxi:
        return AppAssets.eventVector01;
      case AppInUse.cyberneom:
        return AppAssets.spiritualWitchy;
    }
  }

  static String getAppCoinName() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return "Gigcoin";
      case AppInUse.emxi:
        return "Emxis";
      case AppInUse.cyberneom:
        return "Neomcoin";
    }
  }

  ///DEPRECATED
  // static String getFirstAppItemId() {
  //   switch (appInUse) {
  //     case AppInUse.gigmeout:
  //       return "40riOy7x9W7GXjyGp4pjAv";
  //     case AppInUse.emxi:
  //       return "2drTDQAAQBAJ";
  //     case AppInUse.cyberneom:
  //       return "";
  //   }
  // }

  static List<AppMediaItem> getFirstAppItem() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return CoreUtilities.myFirstSong();
      case AppInUse.emxi:
        return CoreUtilities.myFirstBook();
      case AppInUse.cyberneom:
        return [];
    }
  }

  static String getFcmKey() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['fcmKey'];
    //return GigConstants.fcmKey;
      case AppInUse.emxi:
        return appProperties['fcmKey'];
    //return EmxiConstants.fcmKey;
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getGoogleApiKey() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['googleApiKey'];
      case AppInUse.emxi:
        return appProperties['googleApiKey'];
      case AppInUse.cyberneom:
        return appProperties['googleApiKey'];
    }
  }

  static String getSpotifyClientId() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['spotifyClientId'];
      case AppInUse.emxi:
        return appProperties['spotifyClientId'];
      case AppInUse.cyberneom:
        return appProperties['spotifyClientId'];
    }
  }

  static String getSpotifyClientSecret() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['spotifyClientSecret'];
      case AppInUse.emxi:
        return appProperties['spotifyClientSecret'];
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getStripePublishableKey() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['stripePublishableKey'];
      case AppInUse.emxi:
        return appProperties['stripePublishableKey'];
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getStripeSecretLiveKey() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['stripeSecretLiveKey'];
      case AppInUse.emxi:
        return appProperties['stripeSecretLiveKey'];
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getECommerceUrl() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['eCommerceUrl'];
      case AppInUse.emxi:
        return appProperties['eCommerceUrl'];
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getPresskitUrl() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['presskitUrl'];
      case AppInUse.emxi:
        return appProperties['presskitUrl'];
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getMediatourUrl() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['mediatourUrl'];
      case AppInUse.emxi:
        return appProperties['mediatourUrl'];
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getOnlineInterviewUrl() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['onlineInterviewUrl'];
      case AppInUse.emxi:
        return appProperties['onlineInterviewUrl'];
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getDigitalPositioningUrl() {
    switch (appInUse) {
      case AppInUse.cyberneom:
        return "";
      case AppInUse.gigmeout:
        return "";
      case AppInUse.emxi:
        return appProperties['digitalPositioningUrl'];
    }
  }

  static String getConsultancyUrl() {
    switch (appInUse) {
      case AppInUse.cyberneom:
        return "";
      case AppInUse.gigmeout:
        return "";
      case AppInUse.emxi:
        return appProperties['consultancyUrl'];
    }
  }

  static String getCopyrightUrl() {
    switch (appInUse) {
      case AppInUse.cyberneom:
        return "";
      case AppInUse.gigmeout:
        return "";
      case AppInUse.emxi:
        return appProperties['copyrightUrl'];
    }
  }

  static String getCoverDesignUrl() {
    switch (appInUse) {
      case AppInUse.cyberneom:
        return "";
      case AppInUse.gigmeout:
        return "";
      case AppInUse.emxi:
        return appProperties['coverDesignUrl'];
    }
  }

  static String getOnlineClinicUrl() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['onlineClinicUrl'];
      case AppInUse.emxi:
        return appProperties['onlineClinicUrl'];
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getStartCampaignUrl() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return "";
      case AppInUse.emxi:
        return appProperties['startCampaignUrl'];
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getCrowdfundingUrl() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return "";
      case AppInUse.emxi:
        return appProperties['crowdfundingUrl'];
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getWhatsappBusinessNumber() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return "";
      case AppInUse.emxi:
        return appProperties['whatsappBusinessNumber'];
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getInitialPrice() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['initialPrice'];
      case AppInUse.emxi:
        return appProperties['initialPrice'];
      case AppInUse.cyberneom:
        return "";
    }
  }

  static List<Widget> getHomePages() {
    switch (appInUse) {
      case AppInUse.cyberneom:
        return AppRouteConstants.neomHomePages;
      case AppInUse.gigmeout:
        return AppRouteConstants.gigHomePages;
      case AppInUse.emxi:
        return AppRouteConstants.emxiHomePages;
    }
  }

  static IconData getSecondTabIcon() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return FontAwesomeIcons.building;
      case AppInUse.emxi:
        return FontAwesomeIcons.bookOpen;
      case AppInUse.cyberneom:
        return Icons.surround_sound_outlined;
    }
  }

  static String getSecondTabTitle() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return AppTranslationConstants.directory;
      case AppInUse.emxi:
        return AppTranslationConstants.itemlists;
      case AppInUse.cyberneom:
        return AppTranslationConstants.presets;
    }
  }

  static IconData getThirdTabIcon() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return FontAwesomeIcons.calendar;
      case AppInUse.emxi:
        return FontAwesomeIcons.filePen;
      case AppInUse.cyberneom:
        return FontAwesomeIcons.calendar;
    }
  }

  static String getThirdTabTitle() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return AppTranslationConstants.events;
      case AppInUse.emxi:
        return AppTranslationConstants.inspiration;
      case AppInUse.cyberneom:
        return AppTranslationConstants.events;
    }
  }

  static IconData getForthTabIcon() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return Icons.play_circle_fill;
      case AppInUse.emxi:
        return FontAwesomeIcons.shop;
      case AppInUse.cyberneom:
      ///CHANGE TO MUSIC IN NEXT VERSION
        return FontAwesomeIcons.comments;
    }
  }

  static String getFortTabTitle() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return AppTranslationConstants.music;
      case AppInUse.emxi:
        return AppTranslationConstants.library;
      case AppInUse.cyberneom:
        ///CHANGE TO MUSIC IN NEXT VERSION
        return AppTranslationConstants.inbox;
    }
  }

  static IconData getHomeActionBtnIcon() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return CupertinoIcons.add;
      case AppInUse.emxi:
        return CupertinoIcons.add;
      case AppInUse.cyberneom:
        return FontAwesomeIcons.om;
    }
  }

  static String getAppLogoPath() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return AppTranslationConstants.languageFromLocale(Get.locale!)
            == AppTranslationConstants.spanish ? AppAssets.logoSloganSpanish
            : AppAssets.logoSloganEnglish;
      case AppInUse.emxi:
      return AppAssets.logoCompanyWhite;
      case AppInUse.cyberneom:
        return AppAssets.logoAppWhite;
    }
  }

  static String getIconPath() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return AppAssets.iconWhite;
      case AppInUse.emxi:
        return AppAssets.iconWhite;
      case AppInUse.cyberneom:
        return AppAssets.iconWhite;
    }
  }

  static String getBuyMeACoffeeURL() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['buyMeACoffeeUrl'];
      case AppInUse.emxi:
        return appProperties['buyMeACoffeeUrl'];
      case AppInUse.cyberneom:
        return appProperties['buyMeACoffeeUrl'];
    }
  }

  static String getHubName() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return appProperties['audioHubName'];
      case AppInUse.emxi:
        return appProperties['audioHubName'];
      case AppInUse.cyberneom:
        return appProperties['audioHubName'];
    }
  }

}
