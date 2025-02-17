import 'dart:convert';
import 'package:flutter/services.dart';

import 'constants/app_assets.dart';

class AppProperties {
  static final AppProperties _instance = AppProperties._internal();

  static dynamic appProperties = {};

  /// Factory constructor to return the same instance
  factory AppProperties() {
    return _instance;
  }

  /// Private constructor for singleton pattern
  AppProperties._internal();

  /// Initialize and load properties when the singleton is accessed
  static Future<void> init() async {
    await _instance._readProperties();
  }

  /// Load JSON properties from assets
  Future<void> _readProperties() async {
    String jsonString = await rootBundle.loadString(AppAssets.propertiesJsonPath);
    appProperties = jsonDecode(jsonString);
  }

  static String getAppName() => appProperties['appName'];

  static String getAppLogoUrl() => appProperties['appLogoUrl'];

  static String getJammingDefaultImgUrl() => appProperties['jammingLogo'];

  static String getLinksUrl() => appProperties['linksUrl'];

  static String getPlayStoreUrl() => appProperties['playStoreUrl'];

  static String getAppStoreUrl() => appProperties['appStoreUrl'];

  static String getLandingPageUrl() => appProperties['landingPageUrl'];

  static String getTermsOfServiceUrl() => appProperties['termsOfServiceUrl'];

  static String getPrivacyPolicyUrl() => appProperties['privacyPolicyUrl'];

  static String getBlogUrl() => appProperties['blogUrl'];

  static String getWebContact() => appProperties['webContact'];

  static String getNoImageUrl() => appProperties['noImageUrl'];

  static String getFcmKey() => appProperties['fcmKey'];

  static String getGoogleApiKey() => appProperties['googleApiKey'];

  static String getSpotifyClientId() => appProperties['spotifyClientId'];

  static String getSpotifyClientSecret() => appProperties['spotifyClientSecret'];

  static String getStripePublishableKey() => appProperties['stripePublishableKey'];

  static String getStripeSecretLiveKey() => appProperties['stripeSecretLiveKey'];

  static String getStripeSecretTestKey() => appProperties['stripeSecretTestKey'];

  static String getECommerceUrl() => appProperties['eCommerceUrl'];

  static String getPresskitUrl() => appProperties['presskitUrl'];

  static String getMediatourUrl() => appProperties['mediatourUrl'];

  static String getOnlineInterviewUrl() => appProperties['onlineInterviewUrl'];

  static String getDigitalPositioningUrl() => appProperties['digitalPositioningUrl'];

  static String getConsultancyUrl() => appProperties['consultancyUrl'];

  static String getCopyrightUrl() => appProperties['copyrightUrl'];

  static String getIsbnProcedureUrl() => appProperties['isbnProcedureUrl'];

  static String getCoverDesignUrl() => appProperties['coverDesignUrl'];

  static String getOnlineClinicUrl() => appProperties['onlineClinicUrl'];

  static String getStartCampaignUrl() => appProperties['startCampaignUrl'];

  static String getCrowdfundingUrl() => appProperties['crowdfundingUrl'];

  static String getWhatsappBusinessNumber() => appProperties['whatsappBusinessNumber'];

  static String getInitialPrice() => appProperties['initialPrice'];

  static String getBuyMeACoffeeURL() => appProperties['buyMeACoffeeUrl'];

  static String getHubName() => appProperties['hubName'];

  static String getStorageServerName() => appProperties['storageServerName'];

  static String getSplashSubtitle() => appProperties['splashSubText'];

  static String getPaymentGatewayBaseURL() => appProperties['paymentGatewayBaseURL'];

  static String getNotificationChannelId() => appProperties['notificationChannelId'];

  static String getNotificationChannelName() => appProperties['notificationChannelName'];

  static String getNotificationIcon() => appProperties['notificationIcon'];

  static String getSubscriptionPlansUrl() => appProperties['subscriptionPlansUrl'];

  static String getSiteUrl() => appProperties['siteUrl'];

  static String getWooUrl() => appProperties['wooUrl'];

  static String getWooClientKey() => appProperties['wooClientKey'];

  static String getWooClientSecret() => appProperties['wooClientSecret'];

  static String getWooMainCategoryId() => appProperties['wooMainCategoryId'];




}
