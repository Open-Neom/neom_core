//TODO
//   /*//import 'package:firebase_admob/firebase_admob.dart';
//
// class AdmobInitializer {
//
//
//   static final String appId = "ca-app-pub-9248844542810621~4699252247";
//
//   static void initialize(){
//     //FirebaseAdMob.instance.initialize(appId: appId);
//   }
// }*/
//
// import 'dart:io';
//
// class AdManager {
//
//   static String androidAdMobAppId = "ca-app-pub-9248844542810621~4699252247";
//   static String androidBannerAdUnitId = "ca-app-pub-9248844542810621/2203120849";
//
//   //Preconfigured AdMob app ID and ad unit IDs for this codelab.
//   static String preconfiguredAdMobAppId = "ca-app-pub-3940256099942544~4354546703";
//   static String preconfiguredInterstitialAdUnitId = "ca-app-pub-3940256099942544/7049598008";
//   static String preconfiguredRewardedAdUnitId = "ca-app-pub-3940256099942544/8673189370";
//
//   static String get appId {
//     if (Platform.isAndroid) {
//       return androidAdMobAppId;
//     } else if (Platform.isIOS) {
//       return androidAdMobAppId;
//     } else {
//       throw UnsupportedError("Unsupported platform");
//     }
//   }
//
//   static String get bannerAdUnitId {
//     if (Platform.isAndroid) {
//       return androidBannerAdUnitId;
//     } else if (Platform.isIOS) {
//       return androidBannerAdUnitId;
//     } else {
//       throw UnsupportedError("Unsupported platform");
//     }
//   }
//
//   static String get interstitialAdUnitId {
//     if (Platform.isAndroid) {
//       return interstitialAdUnitId;
//     } else if (Platform.isIOS) {
//       return interstitialAdUnitId;
//     } else {
//       throw UnsupportedError("Unsupported platform");
//     }
//   }
//
//   static String get rewardedAdUnitId {
//     if (Platform.isAndroid) {
//       return rewardedAdUnitId;
//     } else if (Platform.isIOS) {
//       return rewardedAdUnitId;
//     } else {
//       throw UnsupportedError("Unsupported platform");
//     }
//   }
// }
