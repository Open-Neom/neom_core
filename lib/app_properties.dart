import 'dart:convert';
import 'package:flutter/services.dart';
import 'app_config.dart';
import 'cloud_properties.dart';
import 'utils/neom_error_logger.dart';
import 'domain/model/price.dart';
import 'utils/constants/data_assets.dart';
import 'utils/enums/app_currency.dart';
import 'utils/enums/app_in_use.dart';

class AppProperties {

  static final AppProperties _instance = AppProperties._internal();

  factory AppProperties() {
    _instance._init();
    return _instance;
  }

  AppProperties._internal(); // Constructor privado para Singleton

  static dynamic appProperties = {};

  /// Flag para garantizar que `readProperties()` solo se llame una vez
  static bool _isPropertiesRead = false;

  /// Inicializa las propiedades si aún no se han leído
  Future<void> _init() async {
    if (!_isPropertiesRead) {
      await readProperties();
      await CloudProperties.init();
      _isPropertiesRead = true;
    }
  }

  /// Loads app configuration. On web, fetches from Cloud Functions (secureOpsWeb)
  /// so that secrets never reach the client. On mobile, falls back to the
  /// local asset file for offline support.
  static Future<void> readProperties() async {
    AppConfig.logger.t("readProperties");

    // All platforms: load from local asset (properties.json)
    try {
      String jsonString = await rootBundle.loadString(DataAssets.propertiesJsonPath);
      appProperties = jsonDecode(jsonString);
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'readProperties');
      return;
    }
  }

  static String getAppName() {
    return appProperties['appName'] ?? '';
  }

  /// Returns the display name for a given AppInUse source.
  /// Reads from the `appSourceNames` map in properties/config.
  /// Falls back to the enum letter uppercased if not found.
  static String getAppSourceName(AppInUse appInUse) {
    final names = appProperties['appSourceNames'];
    if (names is Map) {
      return names[appInUse.name]?.toString() ?? appInUse.name.toUpperCase();
    }
    return appInUse.name.toUpperCase();
  }

  static String getAppSourceUrl(AppInUse appInUse) {
    String sourceUrl = '';
    final names = appProperties['appSourceUrls'];
    if (names is Map) {
      sourceUrl = names[appInUse.name]?.toString() ?? '';
    }
    return sourceUrl;
  }

  /// Get the web domain for a source app (e.g. "cyberneom.xyz", "gigmeout.com").
  /// Used by promo cards to build web URLs for content viewing.
  static String getAppSourceDomain(AppInUse appInUse) {
    final domains = appProperties['appSourceDomains'];
    if (domains is Map) {
      return domains[appInUse.name]?.toString() ?? '';
    }
    return '';
  }

  static String getAppBotName() {
    return appProperties['appBotName'] ?? '';
  }

  static String getAppLogoUrl() {
    return appProperties['appLogoUrl'] ?? '';
  }

  static String getJammingDefaultImgUrl() {
    return appProperties['jammingLogo'] ?? '';
  }

  static String getSaiaName() {
    return appProperties['saiaName'] ?? 'Itzli';
  }

  static String getLinksUrl() {
    return appProperties['linksUrl'] ?? '';
  }

  static String getPlayStoreUrl() {
    return appProperties['playStoreUrl'] ?? '';
  }

  static String getAppStoreUrl() {
    return appProperties['appStoreUrl'] ?? '';
  }

  static String getLandingPageUrl() {
    return appProperties['landingPageUrl'] ?? '';
  }

  static String getTermsOfServiceUrl() {
    return appProperties['termsOfServiceUrl'] ?? '';
  }

  static String getPrivacyPolicyUrl() {
    return appProperties['privacyPolicyUrl'] ?? '';
  }

  static String getBlogUrl() {
    return appProperties['blogUrl'] ?? '';
  }

  static String getWebContact() {
    return appProperties['webContact'] ?? '';
  }

  ///DEPRECATED
  ///It's better to show the appLogo than a "Image not found" for the user
  static String getNoImageUrl() {
    return appProperties['appLogoUrl'] ?? '';
  }

  static String getAppCoinName() {
    return appProperties['appCoinName'] ?? '';
  }

  static String getFirebaseProjectId() {
    return appProperties['firebaseProjectId'] ?? '';
  }

  static String getECommerceUrl() {
    return appProperties['eCommerceUrl'] ?? '';
  }

  static String getPresskitUrl() {
    return appProperties['presskitUrl'] ?? '';
  }

  static String getMediatourUrl() {
    return appProperties['mediatourUrl'] ?? '';
  }

  static String getOnlineInterviewUrl() {
    return appProperties['onlineInterviewUrl'] ?? '';
  }

  static String getDigitalPositioningUrl() {
    return appProperties['digitalPositioningUrl'] ?? '';
  }

  static String getConsultancyUrl() {
    return appProperties['consultancyUrl'] ?? '';
  }

  static String getCopyrightUrl() {
    return appProperties['copyrightUrl'] ?? '';
  }

  static String getIsbnProcedureUrl() {
    return appProperties['isbnProcedureUrl'] ?? '';
  }

  static String getCoverDesignUrl() {
    return appProperties['coverDesignUrl'] ?? '';
  }

  static String getOnlineClinicUrl() {
    return appProperties['onlineClinicUrl'] ?? '';
  }

  static String getStartCampaignUrl() {
    return appProperties['startCampaignUrl'] ?? '';
  }

  static String getCrowdfundingUrl() {
    return appProperties['crowdfundingUrl'] ?? '';
  }

  static String getWhatsappBusinessNumber() {
    return appProperties['whatsappBusinessNumber'] ?? '';
  }

  static String getInitialPrice() {
    return appProperties['initialPrice'] ?? '';
  }

  static String getBuyMeACoffeeURL() {
    return appProperties['buyMeACoffeeUrl'] ?? '';
  }

  static String getHubName() {
    return appProperties['hubName'] ?? '';
  }

  static String getStorageServerName() {
    return appProperties['storageServerName'] ?? '';
  }

  static String getSplashSubtitle() {
    return appProperties['splashSubText'] ?? '';
  }

  static String getPaymentGatewayBaseURL() {
    return appProperties['paymentGatewayBaseURL'] ?? '';
  }

  static String getNotificationChannelId() {
    return appProperties['notificationChannelId'] ?? '';
  }

  static String getNotificationChannelName() {
    return appProperties['notificationChannelName'] ?? '';
  }

  static String getNotificationIcon() {
    return appProperties['notificationIcon'] ?? '';
  }

  static String getInstagram() {
    return appProperties['instagramUrl'] ?? '';
  }

  static String getEmail() {
    return appProperties['contactEmail'] ?? '';
  }

  static String getSubscriptionPlansUrl() {
    return appProperties['subscriptionPlansUrl'] ?? '';
  }

  static String getSiteUrl() {
    return appProperties['siteUrl'] ?? '';
  }

  static String getWooUrl() {
    return appProperties['wooUrl'] ?? '';
  }

  static String getWordpressUrl() {
    return appProperties['wpUrl'] ?? '';
  }

  static String getWooMainCategoryId() {
    return appProperties['wooMainCategoryId'] ?? '';
  }

  static String getWooSecondaryCategoryId() {
    return appProperties['wooSecondaryCategoryId'] ?? '';
  }

  static String getGeneralSubscriptionName() {
    return appProperties['generalSubscriptionName'] ?? '';
  }

  static Price getSubscriptionPrice() {
    double amount = (appProperties['subscriptionPrice'] ?? 0).toDouble();
    String currency = appProperties['subscriptionCurrency'] ?? 'MXN';
    AppCurrency appCurrency = AppCurrency.values.firstWhere(
      (e) => e.toString().split('.').last.toUpperCase() == currency.toUpperCase(),
      orElse: () => AppCurrency.mxn,
    );

    return Price(amount: amount, currency: appCurrency);
  }

  static String getDevGithub() {
    return appProperties['devGithub'] ?? '';
  }

  static String getDevLinkedIn() {
    return appProperties['devLinkedIn'] ?? '';
  }

  static String getWhatsappUrl() {
    return appProperties['whatsappURL'] ?? '';
  }

  static String getMainWhatsGroupUrl() {
    return appProperties['mainWhatsGroupUrl'] ?? '';
  }

  static String getSecondaryWhatsGroupUrl() {
    return appProperties['secondaryWhatsGroupUrl'] ?? '';
  }

  static String getClipName() {
    return appProperties['clipName'] ?? '';
  }

  static bool mediaToWordpressFlag() {
    return bool.parse(appProperties['mediaToWordpressFlag'] ?? 'false');
  }

  /// Flag to enable automatic WooCommerce product creation when uploading releases
  static bool createWooProductFlag() {
    return bool.parse(appProperties['createWooProductFlag'] ?? 'false');
  }

  static String getCeoName() {
    return appProperties['ceoName'] ?? '';
  }

  static String getCooName() {
    return appProperties['cooName'] ?? '';
  }

  static String getCcoName() {
    return appProperties['ccoName'] ?? '';
  }

  static String getWooPhysicalItemCategory() {
    return appProperties['wooPhysicalItemCategory'] ?? '';
  }

  static String getWooDigitalItemCategory() {
    return appProperties['wooDigitalItemCategory'] ?? '';
  }

  static String getWooStreamingCategory() {
    return appProperties['wooStreamingItemCategory'] ?? '';
  }

  static String getWooSubscriptionItemCategory() {
    return appProperties['wooSubscriptionItemCategory'] ?? '';
  }

  static String getWooNupaleProdutId() {
    return appProperties['wooNupaleProductId'] ?? '';
  }

  static String getWooCaseteProdutId() {
    return appProperties['wooCaseteProductId'] ?? '';
  }

  static String getAppCoinValue() {
    return appProperties['appCoinValue'] ?? '';
  }

  static Map<String, dynamic> getDeeplinkUrl() {
    return appProperties['getDeeplinkUrl'] ?? {};
  }

}
