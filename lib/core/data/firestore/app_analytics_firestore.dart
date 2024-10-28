import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:geolocator/geolocator.dart';

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
  
  final analyticsReference = FirebaseFirestore.instance
      .collection(AppFirestoreCollectionConstants.analytics);

  @override
  Future<List<AppAnalytics>> getAnalytics() async {
    AppUtilities.logger.d("Get all Users");

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

            if(value is int) {
              mapItem["qty"] = value;
            } else if(value is String) {
              mapItem["qty"] = int.parse(value);
            } else {
              mapItem["qty"] = 0;
            }


            analytic = AppAnalytics.fromJson(mapItem);
            analytics.add(analytic);
          });
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return analytics;

  }
  
  @override
  Future<Map<String, AppCoupon>> getUserAnalytics() async {
    AppUtilities.logger.d("");
    Map<String, AppCoupon> coupons = {};
    return coupons;
  }


  @override
  Future<AppCoupon> getAnalyticsByType(String couponCode) async {
    return AppCoupon();

  }

  @override
  Future<void> setUserAnalytics({bool getEmailsAsText = false}) async {
    AppUtilities.startStopwatch(reference: "Setting UserAnalytics on DB");
      AppUtilities.logger.d("Setting App Analytics for fast access.");


      try {

        List<AppUser> users = await UserFirestore().getAll();
        Map<String, AppProfile> profiles = await ProfileFirestore().retrieveAllProfiles();
        List<String> totalLocations = [];

        List<Position> positions = [];
        for (var profile in profiles.values) {
          if(profile.position!.latitude > 0.000000) {
            positions.add(profile.position!);
          }
        }
        totalLocations = await AppUtilities.getAddressesFromPositions(positions);


        await analyticsReference
            .doc(AppFirestoreCollectionConstants.analytics)
            .set({});

        await analyticsReference
            .doc(AppFirestoreCollectionConstants.analytics)
            .set({
              AppFirestoreConstants.totalUsers: "${users.length}",
              AppFirestoreConstants.totalLocations: "${totalLocations.length}"
            });

        WriteBatch batch = FirebaseFirestore.instance.batch();
        Map<String, int> locationTimes = {};

        // Recorrer la lista de ciudades y contar ocurrencias
        for (var locationName in totalLocations) {
          // Si la ciudad ya está en el mapa, incrementar su contador
          if (locationTimes.containsKey(locationName)) {
            locationTimes[locationName] = locationTimes[locationName]! + 1;
          } else {
            // Si no está, inicializar con 1
            locationTimes[locationName] = 1;
          }
        }

        AppUtilities.logger.d("${locationTimes.length} different locations were found.");

        locationTimes.forEach((locationName, locationCount) {
          batch.update(
            analyticsReference.doc(AppFirestoreCollectionConstants.analytics),
            {locationName: "$locationCount"},
          );
        });

        await batch.commit();

        await getUserEmailsAsText(getEmailsAsText, users);

      } catch (e) {
        AppUtilities.logger.e(e.toString());
        AppUtilities.showSnackBar(title: AppTranslationConstants.analytics,
            message: "Hubo un error al actualizar las analíticas");
      }
      
      AppUtilities.showSnackBar(title: AppTranslationConstants.analytics,
          message: "Las analíticas han sido actualizadas");

    AppUtilities.stopStopwatch();
  }

  Future<void> getUserEmailsAsText(bool getEmailsAsText, List<AppUser> users) async {

    if(getEmailsAsText || true) {
      StringBuffer emailList = StringBuffer();

      List<List<dynamic>> rows = [];
      rows.add(['Email']);


      for (var user in users) {
        if(user.email.isNotEmpty && !user.email.contains("@privaterelay.appleid.com")) {
          emailList.write("${user.email}, ");
          rows.add([user.email]);

        }
      }

      if(emailList.isNotEmpty) {
        String localPath = await CoreUtilities.getLocalPath();
        String emailListPath = "$localPath/${AppFlavour.getAppName()}_email_list.txt";
        File txtFileRef = File(emailListPath);
        await txtFileRef.writeAsString(emailList.toString());
        CoreUtilities.copyToClipboard(text: emailList.toString());
        AppUtilities.logger.i("Email List created to path $emailListPath successfully and copied to Clipboard.");

        String csv = const ListToCsvConverter().convert(rows);
        String emailCsvPath = '$localPath/${AppFlavour.getAppName()}_emails_list.csv';
        // Create the CSV file
        File csvFile = File(emailCsvPath);
        // Write the CSV contents to the file
        await csvFile.writeAsString(csv);
        AppUtilities.logger.i("Email CSV created to path $emailListPath successfully and copied to Clipboard.");

      }
    }
  }

}
