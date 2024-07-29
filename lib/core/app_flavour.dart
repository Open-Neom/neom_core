import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../neom_commons.dart';
import 'domain/model/app_media_item.dart';

class AppFlavour {

  static AppInUse appInUse = AppInUse.e;
  static String appVersion = "";
  static dynamic appProperties = {};

  AppFlavour({required AppInUse inUse, required String version,}) {
    appInUse = inUse;
    appVersion = version;
  }

  static Future<void> readProperties() async {
    String jsonString = await rootBundle.loadString(AppAssets.propertiesJsonPath);
    appProperties = jsonDecode(jsonString);
  }

  static String getAppName() {    
    return appProperties['appName'];      
  }
  
  static String getAppLogoUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['appLogoUrl'];
      case AppInUse.e:
        return appProperties['appLogoUrl'];
      case AppInUse.c:
        return appProperties['appLogoUrl'];
    }
  }

  static String getJammingDefaultImgUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['jammingLogo'];
      case AppInUse.e:
        return appProperties['jammingLogo'];
      case AppInUse.c:
        return '';
    }
  }

  static String getLinksUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['linksUrl'];
      case AppInUse.e:
        return appProperties['linksUrl'];
      case AppInUse.c:
        return appProperties['linksUrl'];
    }
  }

  static String getPlayStoreUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['playStoreUrl'];
      case AppInUse.e:
        return appProperties['playStoreUrl'];
      case AppInUse.c:
        return "";
    }
  }

  static String getAppStoreUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['appStoreUrl'];
      case AppInUse.e:
        return appProperties['appStoreUrl'];
      case AppInUse.c:
        return "";
    }
  }

  static String getLandingPageUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['landingPageUrl'];
      case AppInUse.e:
        return appProperties['landingPageUrl'];
      case AppInUse.c:
        return "";
    }
  }

  static String getTermsOfServiceUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['termsOfServiceUrl'];
      case AppInUse.e:
        return appProperties['termsOfServiceUrl'];
      case AppInUse.c:
        return "";
    }
  }

  static String getPrivacyPolicyUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['privacyPolicyUrl'];
      case AppInUse.e:
        return appProperties['privacyPolicyUrl'];
      case AppInUse.c:
        return "";
    }
  }

  static String getBlogUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['blogUrl'];
      case AppInUse.e:
        return appProperties['blogUrl'];
      case AppInUse.c:
        return "";
    }
  }

  static String getWebContact() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['webContact'];
      case AppInUse.e:
        return appProperties['webContact'];
      case AppInUse.c:
        return "";
    }
  }

  static String getNoImageUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['noImageUrl'];
      case AppInUse.e:
        return appProperties['noImageUrl'];
      case AppInUse.c:
        return appProperties['noImageUrl'];
    }
  }

  static IconData getAppItemIcon() {
    switch (appInUse) {
      case AppInUse.g:
        return Icons.music_note;
      case AppInUse.e:
        return Icons.book;
      case AppInUse.c:
        return FontAwesomeIcons.waveSquare;
    }
  }

  static IconData getInstrumentIcon() {
    switch (appInUse) {
      case AppInUse.g:
        return FontAwesomeIcons.guitar;
      case AppInUse.e:
        return FontAwesomeIcons.pencil;
      case AppInUse.c:
        return FontAwesomeIcons.waveSquare;
    }
  }

  static IconData getSyncIcon() {
    switch (appInUse) {
      case AppInUse.g:
        return FontAwesomeIcons.spotify;
      case AppInUse.e:
        return FontAwesomeIcons.bookOpenReader;
      case AppInUse.c:
        return Icons.sync;
    }
  }

  static String getItemDetailsRoute() {
    switch (appInUse) {
      case AppInUse.g:
        return AppRouteConstants.musicPlayerMedia;
      case AppInUse.e:
        return AppRouteConstants.bookDetails;
      case AppInUse.c:
        return AppRouteConstants.generator;
    }
  }

  static String getEventVector() {
    switch (appInUse) {
      case AppInUse.g:
        return AppAssets.bandVector01;
      case AppInUse.e:
        return AppAssets.eventVector01;
      case AppInUse.c:
        return AppAssets.spiritualWitchy;
    }
  }

  static String getAppCoinName() {
    switch (appInUse) {
      case AppInUse.g:
        return "Gigcoin";
      case AppInUse.e:
        return "Emxis";
      case AppInUse.c:
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
      case AppInUse.g:
        return CoreUtilities.myFirstSong();
      case AppInUse.e:
        return CoreUtilities.myFirstBook();
      case AppInUse.c:
        return [];
    }
  }

  static String getFcmKey() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['fcmKey'];
    //return GigConstants.fcmKey;
      case AppInUse.e:
        return appProperties['fcmKey'];
    //return EmxiConstants.fcmKey;
      case AppInUse.c:
        return "";
    }
  }

  static String getGoogleApiKey() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['googleApiKey'];
      case AppInUse.e:
        return appProperties['googleApiKey'];
      case AppInUse.c:
        return appProperties['googleApiKey'];
    }
  }

  static String getSpotifyClientId() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['spotifyClientId'];
      case AppInUse.e:
        return appProperties['spotifyClientId'];
      case AppInUse.c:
        return appProperties['spotifyClientId'];
    }
  }

  static String getSpotifyClientSecret() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['spotifyClientSecret'];
      case AppInUse.e:
        return appProperties['spotifyClientSecret'];
      case AppInUse.c:
        return "";
    }
  }

  static String getStripePublishableKey() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['stripePublishableKey'];
      case AppInUse.e:
        return appProperties['stripePublishableKey'];
      case AppInUse.c:
        return "";
    }
  }

  static String getStripeSecretLiveKey() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['stripeSecretLiveKey'];
      case AppInUse.e:
        return appProperties['stripeSecretLiveKey'];
      case AppInUse.c:
        return "";
    }
  }

  static String getECommerceUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['eCommerceUrl'];
      case AppInUse.e:
        return appProperties['eCommerceUrl'];
      case AppInUse.c:
        return "";
    }
  }

  static String getPresskitUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['presskitUrl'];
      case AppInUse.e:
        return appProperties['presskitUrl'];
      case AppInUse.c:
        return "";
    }
  }

  static String getMediatourUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['mediatourUrl'];
      case AppInUse.e:
        return appProperties['mediatourUrl'];
      case AppInUse.c:
        return "";
    }
  }

  static String getOnlineInterviewUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['onlineInterviewUrl'];
      case AppInUse.e:
        return appProperties['onlineInterviewUrl'];
      case AppInUse.c:
        return "";
    }
  }

  static String getDigitalPositioningUrl() {
    switch (appInUse) {
      case AppInUse.c:
        return "";
      case AppInUse.g:
        return "";
      case AppInUse.e:
        return appProperties['digitalPositioningUrl'];
    }
  }

  static String getConsultancyUrl() {
    switch (appInUse) {
      case AppInUse.c:
        return "";
      case AppInUse.g:
        return "";
      case AppInUse.e:
        return appProperties['consultancyUrl'];
    }
  }

  static String getCopyrightUrl() {
    switch (appInUse) {
      case AppInUse.c:
        return "";
      case AppInUse.g:
        return "";
      case AppInUse.e:
        return appProperties['copyrightUrl'];
    }
  }

  static String getCoverDesignUrl() {
    switch (appInUse) {
      case AppInUse.c:
        return "";
      case AppInUse.g:
        return "";
      case AppInUse.e:
        return appProperties['coverDesignUrl'];
    }
  }

  static String getOnlineClinicUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['onlineClinicUrl'];
      case AppInUse.e:
        return appProperties['onlineClinicUrl'];
      case AppInUse.c:
        return "";
    }
  }

  static String getStartCampaignUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return "";
      case AppInUse.e:
        return appProperties['startCampaignUrl'];
      case AppInUse.c:
        return "";
    }
  }

  static String getCrowdfundingUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return "";
      case AppInUse.e:
        return appProperties['crowdfundingUrl'];
      case AppInUse.c:
        return "";
    }
  }

  static String getWhatsappBusinessNumber() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['whatsappBusinessNumber'];
      case AppInUse.e:
        return appProperties['whatsappBusinessNumber'];
      case AppInUse.c:
        return "";
    }
  }

  static String getInitialPrice() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['initialPrice'];
      case AppInUse.e:
        return appProperties['initialPrice'];
      case AppInUse.c:
        return "";
    }
  }

  ///DEPRECATED
  // static List<Widget> getHomePages() {
  //   switch (appInUse) {
  //     case AppInUse.c:
  //       return AppRouteConstants.cHomePages;
  //     case AppInUse.g:
  //       return AppRouteConstants.gHomePages;
  //     case AppInUse.e:
  //       return AppRouteConstants.eHomePages;
  //   }
  // }

  static IconData getSecondTabIcon() {
    switch (appInUse) {
      case AppInUse.g:
        return FontAwesomeIcons.building;
      case AppInUse.e:
        return FontAwesomeIcons.calendar;
      case AppInUse.c:
        return Icons.surround_sound_outlined;
    }
  }

  static String getSecondTabTitle() {
    switch (appInUse) {
      case AppInUse.g:
        return AppTranslationConstants.directory;
      case AppInUse.e:
        return AppTranslationConstants.events;
      case AppInUse.c:
        return AppTranslationConstants.presets;
    }
  }

  static IconData getThirdTabIcon() {
    switch (appInUse) {
      case AppInUse.g:
        return FontAwesomeIcons.calendar;
      case AppInUse.e:
        return FontAwesomeIcons.shop;
      case AppInUse.c:
        return FontAwesomeIcons.calendar;
    }
  }

  static String getThirdTabTitle() {
    switch (appInUse) {
      case AppInUse.g:
        return AppTranslationConstants.events;
      case AppInUse.e:
        return AppTranslationConstants.bookShop;
      case AppInUse.c:
        return AppTranslationConstants.events;
    }
  }

  static IconData getForthTabIcon() {
    switch (appInUse) {
      case AppInUse.g:
        return Icons.play_circle_fill;
      case AppInUse.e:
        return FontAwesomeIcons.headphones;
      case AppInUse.c:
      ///CHANGE TO MUSIC IN NEXT VERSION
        return LucideIcons.audioWaveform;
    }
  }

  static String getFortTabTitle() {
    switch (appInUse) {
      case AppInUse.g:
        return AppTranslationConstants.music;
      case AppInUse.e:
        return AppTranslationConstants.audioLibrary;
      case AppInUse.c:
        ///CHANGE TO MUSIC IN NEXT VERSION
        return AppTranslationConstants.audioLibrary;
    }
  }

  static IconData getHomeActionBtnIcon() {
    switch (appInUse) {
      case AppInUse.g:
        return CupertinoIcons.add;
      case AppInUse.e:
        return CupertinoIcons.add;
      case AppInUse.c:
        return FontAwesomeIcons.om;
    }
  }

  static String getAppLogoPath() {
    switch (appInUse) {
      case AppInUse.g:
        return AppTranslationConstants.languageFromLocale(Get.locale!)
            == AppTranslationConstants.spanish ? AppAssets.logoSloganSpanish
            : AppAssets.logoSloganEnglish;
      case AppInUse.e:
      return AppAssets.logoCompanyWhite;
      case AppInUse.c:
        return AppAssets.logoAppWhite;
    }
  }

  static String getAppPreLogoPath() {
    switch (appInUse) {
      case AppInUse.g:
        return '';
      case AppInUse.e:
        return AppAssets.logoAppWhite;
      case AppInUse.c:
        return '';
    }
  }

  static String getIconPath() {
    switch (appInUse) {
      case AppInUse.g:
        return AppAssets.iconWhite;
      case AppInUse.e:
        return AppAssets.iconWhite;
      case AppInUse.c:
        return AppAssets.iconWhite;
    }
  }

  static String getBuyMeACoffeeURL() {
    return appProperties['buyMeACoffeeUrl'];    
  }

  static String getHubName() {
    return appProperties['audioHubName'];    
  }

  static String getStorageServerName() {
    return appProperties['storageServerName'];    
  }

  static String getSplashSubtitle() {
    return appProperties['splashSubText'];    
  }

  static List<BlogArticle> getBlogArticles() {
    List<BlogArticle> articles = [];
    switch (appInUse) {
      case AppInUse.g:
        articles = [
          BlogArticle(
              writerName: appProperties['blogWriterName_0'],
              writeImgUrl: appProperties['blogWriterImgUrl_0'],
              articleDescription: appProperties['blogArticleDescription_0'],
              articleUrl: appProperties['blogArticleUrl_0'],
          ),
          BlogArticle(
            writerName: appProperties['blogWriterName_1'],
            writeImgUrl: appProperties['blogWriterImgUrl_1'],
            articleDescription: appProperties['blogArticleDescription_1'],
            articleUrl: appProperties['blogArticleUrl_1'],
          ),
          BlogArticle(
            writerName: appProperties['blogWriterName_2'],
            writeImgUrl: appProperties['blogWriterImgUrl_2'],
            articleDescription: appProperties['blogArticleDescription_2'],
            articleUrl: appProperties['blogArticleUrl_2'],
          ),
        ];
      case AppInUse.e:
        articles = [
          BlogArticle(
            writerName: appProperties['blogWriterName_0'],
            writeImgUrl: appProperties['blogWriterImgUrl_0'],
            articleDescription: appProperties['blogArticleDescription_0'],
            articleUrl: appProperties['blogArticleUrl_0'],
          ),
          BlogArticle(
            writerName: appProperties['blogWriterName_1'],
            writeImgUrl: appProperties['blogWriterImgUrl_1'],
            articleDescription: appProperties['blogArticleDescription_1'],
            articleUrl: appProperties['blogArticleUrl_1'],
          ),
          BlogArticle(
            writerName: appProperties['blogWriterName_2'],
            writeImgUrl: appProperties['blogWriterImgUrl_2'],
            articleDescription: appProperties['blogArticleDescription_2'],
            articleUrl: appProperties['blogArticleUrl_2'],
          ),
        ];
      case AppInUse.c:
        break;
    }

    return articles;
  }

  static String getPaymentGatewayBaseURL() {
    return appProperties['paymentGatewayBaseURL'];
  }

  static String getNotificationChannelId() {
    return appProperties['notificationChannelId'];
  }

  static String getNotificationChannelName() {
    return appProperties['notificationChannelName'];
  }

  static String getNotificationIcon() {
    return appProperties['notificationIcon'];
  }

  static String getInstagram() {
    switch (appInUse) {
      case AppInUse.g:
        return 'https://instagram.com/gigmeoutmx';
      case AppInUse.e:
        return 'https://instagram.com/escritoresmxi';
      case AppInUse.c:
        return 'https://instagram.com/cyber.neom';
    }
  }

  static String getEmail() {
    switch (appInUse) {
      case AppInUse.g:
        return 'gigmeoutmx@gmail.com';
      case AppInUse.e:
        return 'escritoresmxi@gmail.com';
      case AppInUse.c:
        return '';
    }
  }

  static String getMusicPlayerHomeTitle() {
    switch (appInUse) {
      case AppInUse.g:
        return AppTranslationConstants.music.tr;
      case AppInUse.e:
        return AppTranslationConstants.audioLibrary.tr;
      case AppInUse.c:
        return AppTranslationConstants.audioLibrary.tr;
    }
  }

  static String getSubscriptionPlansUrl() {
    return appProperties['subscriptionPlansUrl'];
  }

}
