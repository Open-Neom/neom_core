import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:geolocator/geolocator.dart';

import '../../app_flavour.dart';
import '../../domain/model/analytics/user_locations.dart';
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
  Future<List<UserLocations>> getUserLocations() async {
    AppUtilities.logger.d("Get all Users");

    List<UserLocations> userLocationsList = [];
    try {
      final userAnalyticsReference = analyticsReference.doc(AppFirestoreCollectionConstants.usersAnalytics);
      final userLocationsReferences = userAnalyticsReference.collection(AppFirestoreCollectionConstants.userLocations);
      QuerySnapshot querySnapshot = await userLocationsReferences.get();
      for (var queryDocumentSnapshot in querySnapshot.docs) {
        UserLocations userLocations = UserLocations.fromJSON(queryDocumentSnapshot.data());
        userLocations.dateId = queryDocumentSnapshot.id;
        userLocationsList.add(userLocations);
      }
      // userLocations = UserLocations.fromJSON(querySnapshot.data());
      // for (var queryDocumentSnapshot in querySnapshot.docs) {
      //   if (queryDocumentSnapshot.exists) {
      //     Map<String, dynamic> snapshots = queryDocumentSnapshot.data() as Map<String, dynamic>;
      //     snapshots.forEach((key, value) {
      //       AppAnalytics analytic = AppAnalytics(location: "", qty: 0);
      //       Map<String,dynamic> mapItem = {};
      //       mapItem["location"] = key;
      //
      //       if(value is int) {
      //         mapItem["qty"] = value;
      //       } else if(value is String) {
      //         mapItem["qty"] = int.parse(value);
      //       } else {
      //         mapItem["qty"] = 0;
      //       }
      //
      //
      //       analytic = AppAnalytics.fromJson(mapItem);
      //       analytics.add(analytic);
      //     });
      //   }
      // }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return userLocationsList;

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
  Future<void> setUserLocations({bool getEmailsAsText = false}) async {
    AppUtilities.startStopwatch(reference: "Setting UserAnalytics on DB");
      AppUtilities.logger.d("Setting App Analytics for fast access.");


      try {

        final userAnalyticsReference = analyticsReference.doc(AppFirestoreCollectionConstants.usersAnalytics);
        final userLocationsReferences = userAnalyticsReference.collection(AppFirestoreCollectionConstants.userLocations);
        /// List<AppUser> users = await UserFirestore().getAll();
        /// Map<String, AppProfile> profiles = await ProfileFirestore().retrieveAllProfiles();
        final now = DateTime.now();
        final dateId = "${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.year}";
        final userAnalyticsDocRef = userLocationsReferences.doc(dateId);

        // Ejecutar la obtención de usuarios y perfiles en paralelo.
        final results = await Future.wait([
          UserFirestore().getAll(),
          ProfileFirestore().retrieveAllProfiles(),
        ]);
        List<AppUser> users = results[0] as List<AppUser>;
        Map<String, AppProfile> profiles = results[1] as Map<String, AppProfile>;

        List<String> totalLocations = [];


        /// List<Position> positions = [];
        // for (var profile in profiles.values) {
        //   if(profile.position!.latitude > 0.000000) {
        //     positions.add(profile.position!);
        //   }
        // }

        // Filtrar perfiles que tengan una posición válida.
        List<Position> positions = profiles.values
            .where((profile) => profile.position != null && profile.position!.latitude > 0)
            .map((profile) => profile.position!)
            .toList();

        totalLocations = await AppUtilities.getAddressesFromPositions(positions);


        ///
        // await analyticsReference
        //     .doc(AppFirestoreCollectionConstants.analytics)
        //     .set({});

        await userLocationsReferences.doc(dateId)
            .set({
              AppFirestoreConstants.totalUsers: "${users.length}",
              AppFirestoreConstants.totalLocations: "${totalLocations.length}"
            });

        ///
        // Map<String, int> locationTimes = {};
        // // Recorrer la lista de ciudades y contar ocurrencias
        // for (var locationName in totalLocations) {
        //   // Si la ciudad ya está en el mapa, incrementar su contador
        //   if (locationTimes.containsKey(locationName)) {
        //     locationTimes[locationName] = locationTimes[locationName]! + 1;
        //   } else {
        //     // Si no está, inicializar con 1
        //     locationTimes[locationName] = 1;
        //   }
        // }

        Map<String, int> locationTimes = totalLocations.fold<Map<String, int>>(
          {}, (map, location) {
            map[location] = (map[location] ?? 0) + 1;
            return map;
          },
        );
        AppUtilities.logger.d("${locationTimes.length} different locations were found.");

        WriteBatch batch = FirebaseFirestore.instance.batch();
        locationTimes.forEach((locationName, locationCount) async {
          batch.update(
            userAnalyticsDocRef,
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
