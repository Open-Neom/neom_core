import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../emxi/utils/constants/emxi_constants.dart';
import '../gigmeout/utils/constants/gig_constants.dart';
import '../neom_commons.dart';

class AppFlavour {

  static AppInUse appInUse = AppInUse.emxi;
  static String appVersion = "";

  AppFlavour({required AppInUse inUse, required String version,}) {
    appInUse = inUse;
    appVersion = version;
  }

  static String getAppLogoUrl() {
    switch(appInUse) {
      case AppInUse.gigmeout:
        return GigConstants.appLogoUrl;
      case AppInUse.emxi:
        return EmxiConstants.appLogoUrl;
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getPlayStoreUrl() {
    switch(appInUse) {
      case AppInUse.gigmeout:
        return GigConstants.playStoreUrl;
      case AppInUse.emxi:
        return EmxiConstants.playStoreUrl;
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getAppStoreUrl() {
    switch(appInUse) {
      case AppInUse.gigmeout:
        return GigConstants.appStoreUrl;
      case AppInUse.emxi:
        return EmxiConstants.appStoreUrl;
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getLandingPageUrl() {
    switch(appInUse) {
      case AppInUse.gigmeout:
        return GigConstants.landingPageUrl;
      case AppInUse.emxi:
        return EmxiConstants.landingPageUrl;
      case AppInUse.cyberneom:
        return "";
    }
  }
  
  static String getTermsOfServiceUrl() {
    switch(appInUse) {
      case AppInUse.gigmeout:
        return GigConstants.termsOfServiceUrl;
      case AppInUse.emxi:
        return EmxiConstants.termsOfServiceUrl;
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getPrivacyPolicyUrl() {
    switch(appInUse) {
      case AppInUse.gigmeout:
        return GigConstants.privacyPolicyUrl;
      case AppInUse.emxi:
        return EmxiConstants.privacyPolicyUrl;
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getBlogUrl() {
    switch(appInUse) {
      case AppInUse.gigmeout:
        return GigConstants.blogUrl;
      case AppInUse.emxi:
        return EmxiConstants.blogUrl;
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getWebContact() {
    switch(appInUse) {
      case AppInUse.gigmeout:
        return GigConstants.webContact;
      case AppInUse.emxi:
        return EmxiConstants.webContact;
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getNoImageUrl() {
    switch(appInUse) {
      case AppInUse.gigmeout:
        return GigConstants.noImageUrl;
      case AppInUse.emxi:
        return EmxiConstants.noImageUrl;
      case AppInUse.cyberneom:
        return "";
    }
  }

  static IconData getAppItemIcon() {
    switch(appInUse) {
      case AppInUse.gigmeout:
        return Icons.music_note;
      case AppInUse.emxi:
        return Icons.book;
      case AppInUse.cyberneom:
        return Icons.science;
    }
  }

  static IconData getInstrumentIcon() {
    switch(appInUse) {
      case AppInUse.gigmeout:
        return FontAwesomeIcons.guitar;
      case AppInUse.emxi:
        return FontAwesomeIcons.pencil;
      case AppInUse.cyberneom:
        return Icons.science;
    }
  }

  static IconData getSyncIcon() {
    switch(appInUse) {
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
        return "";
    }
  }

  static String getEventVector() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return AppAssets.bandVector01;
      case AppInUse.emxi:
        return AppAssets.eventVector01;
      case AppInUse.cyberneom:
        return "";
    }
  }

  static String getAppCoinName() {
    switch (appInUse) {
      case AppInUse.gigmeout:
        return "GigCoin";
      case AppInUse.emxi:
        return "EmxiCoin";
      case AppInUse.cyberneom:
        return "NeomCoin";
    }
  }

  static List<AppItem> getFirstAppItem() {
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
    switch(appInUse) {
      case AppInUse.gigmeout:
        return GigConstants.fcmKey;
      case AppInUse.emxi:
        return EmxiConstants.fcmKey;
      case AppInUse.cyberneom:
        return "";
    }
  }

}
