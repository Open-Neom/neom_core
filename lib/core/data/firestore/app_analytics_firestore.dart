import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_flavour.dart';
import '../../domain/model/app_coupon.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/app_user.dart';
import '../../domain/repository/app_analytics_repository.dart';
import '../../utils/app_utilities.dart';
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
        List<String> totalLocations = [];

        for (var user in users) {
          totalLocations.addAll(await getProfilesLocation(user.id));
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
          for (var subLocatioName in totalLocations) {
            if(locationName == subLocatioName) {
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
      }
  }

  Future<List<String>> getProfilesLocation(String userId) async {

    List<String> locations = [];
    List<AppProfile> profiles = await ProfileFirestore().retrieveProfiles(userId);

    //for (var profile in profiles) {

      // if(profile.type == GigProfileType.musician) {
      //   profile.instruments = await InstrumentFirestore().retrieveInstruments(profile.id);
      //   if(profile.instruments!.isEmpty) {
      //     logger.w("Instruments not found");
      //   }
      // }
      //
      // if(profile.type == GigProfileType.host) {
      //   profile.places = await GigPlaceFirestore().retrievePlaces(profile.id);
      //   if(profile.places!.isEmpty) {
      //     logger.w("Places not found");
      //   }
      // }
      //
      // if(profile.type == GigProfileType.facilitator) {
      //   profile.facilities = await GigFacilityFirestore().retrieveFacilities(profile.id);
      //   if(profile.facilities!.isEmpty) {
      //     logger.w("Facilities not found");
      //   }
      // }
      //
      // profile.genres = await GigGenreFirestore().retrieveGenres(profile.id);
      // profile.itemlists = await ItemlistFirestore().retrieveItemlists(profile.id);
      //
      // if(profile.genres!.isEmpty) logger.d("Genres not found");
      // if(profile.itemlists!.isEmpty) logger.d("Itemlists not found");

    //}

    if(profiles.isEmpty) {
      logger.d("Profile not found");
    } else {

      for (var profile in profiles) {
        if(profile.position!.latitude > 0.000000) {
          locations.add(await AppUtilities.getAddressFromPlacerMark(profile.position!));
        }
      }
    }

    return locations;
  }

}
