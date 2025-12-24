import 'dart:convert';
import 'package:flutter/services.dart';
import 'app_config.dart';
import 'domain/model/price.dart';
import 'utils/constants/data_assets.dart';
import 'utils/enums/app_currency.dart';

class AppProperties {

  static final AppProperties _instance = AppProperties._internal();

  factory AppProperties() {
    _instance._init();
    return _instance;
  }

  AppProperties._internal(); // Constructor privado para Singleton

  static dynamic appProperties = {};
  static dynamic serviceAccount = {};

  /// Flag para garantizar que `readProperties()` solo se llame una vez
  static bool _isPropertiesRead = false;

  /// Inicializa las propiedades si aún no se han leído
  Future<void> _init() async {
    if (!_isPropertiesRead) {
      await readProperties();
      await readServiceAccount();
      _isPropertiesRead = true;
    }
  }

  static Future<void> readProperties() async {
    AppConfig.logger.t("readProperties");

    try {
      String jsonString = await rootBundle.loadString(DataAssets.propertiesJsonPath);
      appProperties = jsonDecode(jsonString);
    } catch (e) {
      AppConfig.logger.e("Error reading properties: $e");
      return;
    }
  }

  static Future<void> readServiceAccount() async {
    AppConfig.logger.t("readServiceAccount");
    try {
      String jsonString = await rootBundle.loadString(DataAssets.serviceAccountJsonPath);
      serviceAccount = jsonDecode(jsonString);
      AppConfig.logger.t("Service Account Loaded as: $serviceAccount");
    } catch (e) {
      AppConfig.logger.e("Error reading service account: $e");
      return;
    }
  }

  static String getAppName() {    
    return appProperties['appName'];      
  }

  static String getAppBotName() {
    return appProperties['appBotName'];
  }

  static String getAppLogoUrl() {
    return appProperties['appLogoUrl'];
  }

  static String getJammingDefaultImgUrl() {
    return appProperties['jammingLogo'];
  }

  static String getLinksUrl() {
    return appProperties['linksUrl'];
  }

  static String getPlayStoreUrl() {
    return appProperties['playStoreUrl'];
  }

  static String getAppStoreUrl() {
    return appProperties['appStoreUrl'];
  }

  static String getLandingPageUrl() {
    return appProperties['landingPageUrl'];
  }

  static String getTermsOfServiceUrl() {
    return appProperties['termsOfServiceUrl'];
  }

  static String getPrivacyPolicyUrl() {
    return appProperties['privacyPolicyUrl'];
  }

  static String getBlogUrl() {
    return appProperties['blogUrl'];
  }

  static String getWebContact() {
    return appProperties['webContact'] ?? '';
  }

  static String getNoImageUrl() {
    return appProperties['noImageUrl'] ?? '';
  }

  static String getAppCoinName() {
    return appProperties['appCoinName'] ?? '';
  }

  static String getFirebaseProjectId() {
    return appProperties['firebaseProjectId'];
  }

  static String getGoogleApiKey() {
    return appProperties['googleApiKey'];
  }

  static String getSpotifyClientId() {
    return appProperties['spotifyClientId'];
  }

  static String getSpotifyClientSecret() {
    return appProperties['spotifyClientSecret'];
  }

  static String getStripePublishableKey() {
    return appProperties['stripePublishableKey'];
  }

  static String getStripeSecretKey({required bool isLive}) {
    return isLive ? appProperties['stripeSecretLiveKey'] : appProperties['stripeSecretTestKey'];
  }

  static String getECommerceUrl() {
    return appProperties['eCommerceUrl'];
  }

  static String getPresskitUrl() {
    return appProperties['presskitUrl'];
  }

  static String getMediatourUrl() {
    return appProperties['mediatourUrl'];
  }

  static String getOnlineInterviewUrl() {
    return appProperties['onlineInterviewUrl'];
  }

  static String getDigitalPositioningUrl() {
    return appProperties['digitalPositioningUrl'];
  }

  static String getConsultancyUrl() {
    return appProperties['consultancyUrl'];
  }

  static String getCopyrightUrl() {
    return appProperties['copyrightUrl'];
  }

  static String getIsbnProcedureUrl() {
    return appProperties['isbnProcedureUrl'];
  }

  static String getCoverDesignUrl() {
    return appProperties['coverDesignUrl'];
  }

  static String getOnlineClinicUrl() {
    return appProperties['onlineClinicUrl'];
  }

  static String getStartCampaignUrl() {
    return appProperties['startCampaignUrl'];
  }

  static String getCrowdfundingUrl() {
    return appProperties['crowdfundingUrl'];
  }

  static String getWhatsappBusinessNumber() {
    return appProperties['whatsappBusinessNumber'];
  }

  static String getInitialPrice() {
    return appProperties['initialPrice'];
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
    return appProperties['instagramUrl'];
  }

  static String getEmail() {
    return appProperties['contactEmail'];
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

  static String getWooAccount() {
    return appProperties['wooAccount'];
  }

  static String getWooPass() {
    return appProperties['wooPass'];
  }

  static String getGeneralSubscriptionName() {
    return appProperties['generalSubscriptionName'];
  }

  static Price getSubscriptionPrice() {
    double amount = appProperties['subscriptionPrice'];
    String currency = appProperties['subscriptionCurrency'] ?? 'MXN';
    AppCurrency appCurrency = AppCurrency.values.firstWhere(
      (e) => e.toString().split('.').last.toUpperCase() == currency.toUpperCase(),
      orElse: () => AppCurrency.mxn,
    );

    return Price(amount: amount, currency: appCurrency);
  }

  static String getDevGithub() {
    return appProperties['devGithub'];
  }

  static String getDevLinkedIn() {
    return appProperties['devLinkedIn'];
  }

  static String getWhatsappUrl() {
    return appProperties['whatsappURL'];
  }

  static String getMainWhatsGroupUrl() {
    return appProperties['mainWhatsGroupUrl'];
  }

  static String getSecondaryWhatsGroupUrl() {
    return appProperties['secondaryWhatsGroupUrl'];
  }

  static String getClipName() {
    return appProperties['clipName'];
  }

  static bool mediaToWordpressFlag() {
    return bool.parse(appProperties['mediaToWordpressFlag'] ?? 'false');
  }

  static String getCeoName() {
    return appProperties['ceoName'];
  }

  static String getCooName() {
    return appProperties['cooName'];
  }

  static String getCcoName() {
    return appProperties['ccoName'];
  }

  static String getWooPhysicalItemCategory() {
    return appProperties['wooPhysicalItemCategory'];
  }

  static String getWooDigitalItemCategory() {
    return appProperties['wooDigitalItemCategory'];
  }

  static String getWooStreamingCategory() {
    return appProperties['wooStreamingItemCategory'];
  }

  static String getWooSubscriptionItemCategory() {
    return appProperties['wooSubscriptionItemCategory'];
  }

  static String getWooNupaleProdutId() {
    return appProperties['wooNupaleProductId'];
  }

  static String getWooCaseteProdutId() {
    return appProperties['wooCaseteProductId'];
  }

  static String getWebCliendId() {
    return appProperties['webClientId'];
  }

  static String getServerCliendId() {
    return appProperties['serverClientId'];
  }

  static String getAppCoinValue() {
    return appProperties['appCoinValue'];
  }
  
  static Map<String, dynamic> getDeeplinkUrl() {
    return appProperties['getDeeplinkUrl'] ?? {};
  }

}
