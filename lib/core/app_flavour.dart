import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../neom_commons.dart';
import 'domain/model/app_media_item.dart';
import 'utils/constants/app_locale_constants.dart';
import 'utils/enums/verification_level.dart';

class AppFlavour {

  static final AppFlavour _instance = AppFlavour._internal();

  factory AppFlavour({required AppInUse inUse, required String version}) {
    _instance._init(inUse, version);
    return _instance;
  }

  AppFlavour._internal(); // Constructor privado para Singleton

  static AppInUse appInUse = AppInUse.e;
  static String appVersion = "";
  static dynamic appProperties = {};

  /// Flag para garantizar que `readProperties()` solo se llame una vez
  static bool _isPropertiesRead = false;

  /// Inicializa las propiedades si aún no se han leído
  Future<void> _init(AppInUse inUse, String version) async {
    if (!_isPropertiesRead) {
      appInUse = inUse;
      appVersion = version;
      await readProperties();
      _isPropertiesRead = true;
    }
  }

  static Future<void> readProperties() async {
    AppUtilities.logger.t("readProperties");
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
        return appProperties['playStoreUrl'];
    }
  }

  static String getAppStoreUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['appStoreUrl'];
      case AppInUse.e:
        return appProperties['appStoreUrl'];
      case AppInUse.c:
        return appProperties['appStoreUrl'];
    }
  }

  static String getLandingPageUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['landingPageUrl'];
      case AppInUse.e:
        return appProperties['landingPageUrl'];
      case AppInUse.c:
        return appProperties['landingPageUrl'];
    }
  }

  static String getTermsOfServiceUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['termsOfServiceUrl'];
      case AppInUse.e:
        return appProperties['termsOfServiceUrl'];
      case AppInUse.c:
        return appProperties['termsOfServiceUrl'];
    }
  }

  static String getPrivacyPolicyUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['privacyPolicyUrl'];
      case AppInUse.e:
        return appProperties['privacyPolicyUrl'];
      case AppInUse.c:
        return appProperties['privacyPolicyUrl'];
    }
  }

  static String getBlogUrl() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['blogUrl'];
      case AppInUse.e:
        return appProperties['blogUrl'];
      case AppInUse.c:
        return appProperties['blogUrl'];
    }
  }

  static String getWebContact() {
    return appProperties['webContact'] ?? '';
  }

  static String getNoImageUrl() {
    return appProperties['noImageUrl'] ?? '';
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

  static String getMainItemDetailsRoute() {
    switch (appInUse) {
      case AppInUse.g:
        return AppRouteConstants.audioPlayerMedia;
      case AppInUse.e:
        return AppRouteConstants.bookDetails;
      case AppInUse.c:
        return AppRouteConstants.audioPlayerMedia;
    }
  }

  static String getSecondaryItemDetailsRoute() {
    switch (appInUse) {
      case AppInUse.g:
        return AppRouteConstants.audioPlayerMedia;
      case AppInUse.e:
        return AppRouteConstants.audioPlayerMedia;
      case AppInUse.c:
        return AppRouteConstants.audioPlayerMedia;
    }
  }

  static String getMainItemDetailsTag() {
    switch (appInUse) {
      case AppInUse.g:
        return AppPageIdConstants.mediaPlayer;
      case AppInUse.e:
        return AppPageIdConstants.bookDetails;
      case AppInUse.c:
        return AppPageIdConstants.mediaPlayer;
    }
  }

  static String getSecondaryItemDetailsTag() {
    switch (appInUse) {
      case AppInUse.g:
        return AppPageIdConstants.mediaPlayer;
      case AppInUse.e:
        return AppPageIdConstants.mediaPlayer;
      case AppInUse.c:
        return AppPageIdConstants.mediaPlayer;
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

  static String getFirebaseProjectId() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['firebaseProjectId'];
      case AppInUse.e:
        return appProperties['firebaseProjectId'];
      case AppInUse.c:
        return appProperties['firebaseProjectId'];
    }
  }

  static String getFcmKey() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['fcmKey'];
      case AppInUse.e:
        return appProperties['fcmKey'];
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
        return '';
      case AppInUse.c:
        return '';
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

  static String getStripeSecretTestKey() {
    switch (appInUse) {
      case AppInUse.g:
        return appProperties['stripeSecretTestKey'];
      case AppInUse.e:
        return appProperties['stripeSecretTestKey'];
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

  static String getIsbnProcedureUrl() {
    switch (appInUse) {
      case AppInUse.c:
        return "";
      case AppInUse.g:
        return "";
      case AppInUse.e:
        return appProperties['isbnProcedureUrl'];
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
        return appProperties['whatsappBusinessNumber'];
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

  static IconData getSecondTabIcon() {
    switch (appInUse) {
      case AppInUse.g:
        return FontAwesomeIcons.calendar;
      case AppInUse.e:
        return FontAwesomeIcons.calendar;
      case AppInUse.c:
        return FontAwesomeIcons.calendar;
    }
  }

  static String getSecondTabTitle() {
    switch (appInUse) {
      case AppInUse.g:
        return AppTranslationConstants.events;
      case AppInUse.e:
        return AppTranslationConstants.events;
      case AppInUse.c:
        return AppTranslationConstants.events;
    }
  }

  static IconData getThirdTabIcon() {
    switch (appInUse) {
      case AppInUse.g:
        return FontAwesomeIcons.building;
      case AppInUse.e:
        return FontAwesomeIcons.shop;
      case AppInUse.c:
        return FontAwesomeIcons.building;
    }
  }

  static String getThirdTabTitle() {
    switch (appInUse) {
      case AppInUse.g:
        return AppTranslationConstants.directory;
      case AppInUse.e:
        return AppTranslationConstants.bookShop;
      case AppInUse.c:
        return AppTranslationConstants.directory;
    }
  }

  static IconData getForthTabIcon() {
    switch (appInUse) {
      case AppInUse.g:
        return Icons.play_circle_fill;
      case AppInUse.e:
        return FontAwesomeIcons.headphones;
      case AppInUse.c:
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
        return AppLocaleConstants.languageFromLocale(Get.locale!)
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
    return appProperties['hubName'];
  }

  static String getStorageServerName() {
    return appProperties['storageServerName'];    
  }

  static String getSplashSubtitle() {
    return appProperties['splashSubText'];    
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
        return 'https://www.instagram.com/cyberneomia/';
    }
  }

  static String getEmail() {
    switch (appInUse) {
      case AppInUse.g:
        return 'gigmeoutmx@gmail.com';
      case AppInUse.e:
        return 'escritoresmxi@gmail.com';
      case AppInUse.c:
        return 'cyberneom.om@gmail.com';
    }
  }

  static String getAudioPlayerHomeTitle() {
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

  static String getSiteUrl() {
    return appProperties['siteUrl'];
  }


  static String getWooUrl() {
    return appProperties['wooUrl'];
  }

  static String getWordpressUrl() {
    return appProperties['wpUrl'] ?? '';
  }

  static String getWooClientKey() {
    return appProperties['wooClientKey'];
  }

  static String getWooClientSecret() {
    return appProperties['wooClientSecret'];
  }

  static String getWooMainCategoryId() {
    return appProperties['wooMainCategoryId'];
  }

  static String getWooSecondaryCategoryId() {
    return appProperties['wooSecondaryCategoryId'];
  }

  static Price getSubscriptionPrice() {
    switch (appInUse) {
      case AppInUse.e:
        return Price(amount: 59, currency: AppCurrency.mxn);
      case AppInUse.g:
        return Price(amount: 39, currency: AppCurrency.mxn);
      case AppInUse.c:
        return Price(amount: 29, currency: AppCurrency.mxn);
    }
  }

  static Widget getVerificationIcon(VerificationLevel level, {double? size}) {
    switch (appInUse) {
      case AppInUse.e:
        switch(level) {
          case VerificationLevel.artist:
            return Icon(Icons.verified, size: size); // Publicado o verificado completo
          case VerificationLevel.professional:
            return Icon(Icons.handshake, size: size); // Verificado como Profesional
          case VerificationLevel.premium:
            return Icon(Icons.auto_awesome, size: size); // Verificación Premium
          // case VerificationLevel.platinum:
          //   return Icon(Icons.workspace_premium, size: size); // Verificación Platino
          default:
            return Icon(Icons.verified, size: size); // Icono predeterminado
        }
      case AppInUse.g:
      case AppInUse.c:
        return Icon(Icons.verified, size: size); // Publicado o verificado completo
    }
  }


}
