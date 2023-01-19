import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/app_profile.dart';
import '../../domain/model/app_user.dart';
import '../../domain/repository/user_repository.dart';
import '../../utils/app_utilities.dart';
import '../../utils/enums/app_currency.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'profile_firestore.dart';

class UserFirestore implements UserRepository {

  var logger = AppUtilities.logger;
  final userReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.users);


  @override
  Future<bool> insert(AppUser user) async {
    String userId = user.id.toLowerCase();
    logger.i("Inserting user $userId to Firestore");

    Map<String,dynamic> userJSON = user.toJSON();
    logger.d(userJSON.toString());

    DocumentReference documentReferencer = userReference.doc(userId);

    try {
      await documentReferencer.set(userJSON)
          .whenComplete(() => logger.i('User added to the database'))
          .catchError((e) => logger.e(e));

      logger.d("User ${user.toString()} inserted successfully.");
      return true;

    } catch (e) {
      await remove(userId) ? logger.i("User rollback") : logger.e(e.toString());
      return false;
    }
  }


  @override
  Future<List<AppUser>> getAll() async {
    logger.d("Get all Users");

    List<AppUser> users = [];
    try {
      QuerySnapshot querySnapshot = await userReference.get();
      for (var queryDocumentSnapshot in querySnapshot.docs) {
        if (queryDocumentSnapshot.exists) {
          AppUser user = AppUser.fromJSON(queryDocumentSnapshot.data());
          user.id = queryDocumentSnapshot.id;
          users.add(user);
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return users;
  }


  @override
  Future<AppUser> getById(userId) async {
    logger.d("Start Id $userId");
    AppUser user = AppUser();
    try {
        DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
        if (documentSnapshot.exists) {
          user = AppUser.fromJSON(documentSnapshot.data());
          user.id = documentSnapshot.id;

          AppProfile profile = AppProfile();

          if(user.currentProfileId.isNotEmpty) {
             profile = await ProfileFirestore().retrieve(user.currentProfileId);
             if(profile.id.isNotEmpty) {
               profile = await ProfileFirestore().getProfileFeatures(profile);
               user.profiles = [profile];
             } else {
               logger.d("Profile not found");
             }
          } else {
             user.profiles = await ProfileFirestore().retrieveProfiles(userId);
             if(user.profiles.isNotEmpty && user.profiles.first.id.isNotEmpty) {
               user.profiles.first = await ProfileFirestore()
                   .getProfileFeatures(user.profiles.first);
             }
          }
        } else {
          logger.i("No user found");
        }
    } catch (e) {
      logger.e(e.toString());
    }

    return user;
  }


  @override
  Future<bool> remove(String userId) async {
    logger.d("Removing User $userId from Firestore");

    try {
      await userReference.doc(userId).delete();
      logger.d("User $userId removed successfully.");
    } catch (e) {
      logger.e(e);
      return false;
    }

    return true;
  }


  @override
  Future<bool> updateAndroidNotificationToken(String userId, String token) async {
    logger.d("Updating Android Notification Token for User $userId");

    try {
      await userReference.doc(userId).update({AppFirestoreConstants.androidNotificationToken: token});
      logger.d("User $userId removed successfully.");
      return true;
    } catch (e) {
      logger.e(e);
      return false;
    }
  }


  @override
  Future<bool> isAvailableEmail(String email) async {

    logger.d("Verify if email $email is already in use");

    try {
      QuerySnapshot querySnapshot = await userReference
          .where(AppFirestoreConstants.email, isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        logger.i("Email already in use");
        return false;
      }

      logger.d("Email is available");
      return true;

    } catch (e) {
      logger.e(e.toString());
      rethrow;
    }
  }


  @override
  Future<bool> isAvailablePhone(String phoneNumber) async {

    logger.d("Verify if phoneNumber $phoneNumber is available");

    try {
      QuerySnapshot querySnapshot = await userReference.where(
          AppFirestoreConstants.phoneNumber,
          isEqualTo: phoneNumber).get();

      if (querySnapshot.docs.isNotEmpty) {
        logger.i("Phone number already in use");
        return false;
      }

      logger.d("No phoneNumber found");
      return true;

    } catch (e) {
      logger.e(e.toString());
      rethrow;
    }
  }


  @override
  Future<bool> addToWallet(String userId, double amount, {AppCurrency appCurrency = AppCurrency.appCoin}) async {
    logger.d("Entering addToWalletMethod");

    AppUser user = AppUser();
    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      if (documentSnapshot.exists) {
        user = AppUser.fromJSON(documentSnapshot.data());
        user.id = documentSnapshot.id;
        user.wallet.amount = user.wallet.amount + amount;

        await documentSnapshot.reference.update({
          AppFirestoreConstants.wallet: jsonEncode(user.wallet)
        });

        logger.d("User Wallet updated");
        return true;
      } else {
        logger.i("No user found");
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return false;
  }


  Future<bool> subtractFromWallet(String userId, double amount, {AppCurrency appCurrency = AppCurrency.appCoin}) async {
    logger.d("Subtraction $amount Aopcoins from UserId $userId");
    AppUser user = AppUser();
    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      if (documentSnapshot.exists) {
        user = AppUser.fromJSON(documentSnapshot.data());
        user.id = documentSnapshot.id;
        user.wallet.amount = user.wallet.amount - amount;

        await documentSnapshot.reference.update({
          AppFirestoreConstants.wallet: user.wallet.toJSON()
        });

        logger.i("User Wallet updated for user $userId");
        return true;
      } else {
        logger.i("No user found");
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> updatePhotoUrl(String userId, String photoUrl) async {
    logger.d("");

    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      await documentSnapshot.reference.update({AppFirestoreConstants.photoUrl: photoUrl});

    } catch (e) {
      logger.e(e.toString());
      return false;
    }

    return true;
  }



  @override
  Future<bool> addOrderId({required String userId, required String orderId}) async {
    logger.d("Order $orderId would be added to User $userId");

    try {
      DocumentSnapshot documentSnapshot = await userReference
          .doc(userId).get();

      await documentSnapshot.reference.update({
        AppFirestoreConstants.orderIds: FieldValue.arrayUnion([orderId])
      });
      logger.d("Order $orderId is now at User $userId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> removeOrderId({required String userId, required String orderId}) async {
    logger.d("Order $orderId would be removed from User $userId");

    try {
      DocumentSnapshot documentSnapshot = await userReference
          .doc(userId).get();

      await documentSnapshot.reference.update({
        AppFirestoreConstants.orderIds: FieldValue.arrayRemove([orderId])
      });
      logger.d("Order $orderId was removed from User $userId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> updateFcmToken(String userId, String fcmToken) async {
    logger.d("updating Firebase Cloud Messaging Token for User $userId");

    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      await documentSnapshot.reference.update({AppFirestoreConstants.fcmToken: fcmToken});
      logger.i("FCM Token successfully updated for User $userId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    return false;
  }

  @override
  Future<void> updateLastTimeOn(String userId) async {
    logger.d("updating LastTimeOn for user $userId");

    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      await documentSnapshot.reference.update({AppFirestoreConstants.lastTimeOn: DateTime.now().millisecondsSinceEpoch});
      logger.i("LastTimeOn successfully updated for User $userId");
    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  Future<String> retrieveFcmToken(String userId) async {
    logger.d("Retrieving Firebase Cloud Messaging Token for User $userId device");

    String fcmToken = "";
    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      fcmToken = AppUser.fromJSON(documentSnapshot.data()).fcmToken;
      logger.i("FCM Token $fcmToken retrieved");
    } catch (e) {
      logger.e(e.toString());
    }

    return fcmToken;
  }

  @override
  Future<bool> updateSpotifyToken(String userId, String spotifyToken) async {
    logger.d("updating Spotify Access Token for User $userId");

    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      await documentSnapshot.reference.update({AppFirestoreConstants.spotifyToken: spotifyToken});
      logger.i("Spotify Token successfully updated for User $userId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    return false;
  }

  Future<AppProfile> updateCurrentProfile(String userId, String currentProfileId) async {
    logger.d("updating current profile $userId");
    AppProfile profile = AppProfile();
    try {
      DocumentSnapshot documentSnapshot = await userReference.doc(userId).get();
      await documentSnapshot.reference.update({AppFirestoreConstants.currentProfileId: currentProfileId});
      logger.i("CurrentProfileId successfully updated for User $userId");
      profile = await ProfileFirestore().retrieveFull(currentProfileId);
    } catch (e) {
      logger.e(e.toString());
    }

    return profile;
  }

}
