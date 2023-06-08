import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_flavour.dart';
import '../../domain/model/app_analytics.dart';
import '../../domain/model/app_coupon.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/app_user.dart';
import '../../domain/repository/app_analytics_repository.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_translation_constants.dart';
import '../../utils/core_utilities.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'profile_firestore.dart';
import 'user_firestore.dart';

class AppAnalyticsFirestore implements AppAnalyticsRepository {

  var logger = AppUtilities.logger;
  final analyticsReference = FirebaseFirestore.instance
      .collection(AppFirestoreCollectionConstants.analytics);

  @override
  Future<List<AppAnalytics>> getAnalytics() async {
    logger.d("Get all Users");

    List<AppAnalytics> analytics = [];
    try {
      QuerySnapshot querySnapshot = await analyticsReference.get();
      for (var queryDocumentSnapshot in querySnapshot.docs) {
        if (queryDocumentSnapshot.exists) {
          Map<String, dynamic> snapshots = queryDocumentSnapshot.data() as Map<String, dynamic>;
          snapshots.forEach((key, value) {
            AppAnalytics analytic = AppAnalytics(location: "", qty: 0);
            Map<String,dynamic> mapItem = {};
            mapItem["location"] = key;
            mapItem["qty"] = int.parse(value);

            analytic = AppAnalytics.fromJson(mapItem);
            analytics.add(analytic);
          });
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return analytics;

  }
  @override
  Future<Map<String, AppCoupon>> getUserAnalytics() async {
    logger.d("");
    Map<String, AppCoupon> coupons = {};
    return coupons;
  }


  @override
  Future<AppCoupon> getAnalyticsByType(String couponCode) async {
    return AppCoupon();

  }

  @override
  Future<void> setUserAnalytics({bool getEmailsAsText = false}) async {

      logger.d("Setting App Analytics for fast access.");

      try {

        List<AppUser> users = await UserFirestore().getAll();
        Map<String, AppProfile> profiles = await ProfileFirestore().retrieveAllProfiles();
        List<String> totalLocations = [];

        for (var profile in profiles.values) {
          if(profile.position!.latitude > 0.000000) {
            totalLocations.add(await AppUtilities.getAddressFromPlacerMark(profile.position!));
          }
        }

        await analyticsReference
            .doc(AppFirestoreCollectionConstants.analytics)
            .set({});

        await analyticsReference
            .doc(AppFirestoreCollectionConstants.analytics)
            .set({
              AppFirestoreConstants.totalUsers: "${users.length}",
              AppFirestoreConstants.totalLocations: "${totalLocations.length}"
            });


        Map<String,int> locationTimes = {};

        for (var locationName in totalLocations) {
          int locationNameIndex = 1;
          for (var subLocationName in totalLocations) {
            if(locationName == subLocationName) {
              locationNameIndex++;
            }
          }

          locationTimes[locationName] = locationNameIndex;
          await analyticsReference.
            doc(AppFirestoreCollectionConstants.analytics)
              .update({
                locationName: "$locationNameIndex"
              });
        }

        if(getEmailsAsText) {
          StringBuffer emailList = StringBuffer();
          for (var user in users) {
            if(user.email.isNotEmpty) {
              emailList.write("${user.email}, ");
            }
          }

          if(emailList.isNotEmpty) {
            String localPath = await CoreUtilities.getLocalPath();
            String emailListPath = "$localPath/${AppFlavour.appInUse.value}_email_list.txt";
            File txtFileRef = File(emailListPath);
            await txtFileRef.writeAsString(emailList.toString());
            AppUtilities.logger.i("Email List created to path $emailListPath successfully.");
          }

        }
      } catch (e) {
        logger.e(e.toString());
        AppUtilities.showSnackBar(AppTranslationConstants.notifications, "Hubo un error al actualizar las analíticas");
      }
      
      AppUtilities.showSnackBar(AppTranslationConstants.notifications, "Las analíticas han sido actualizadas");
  }

}
