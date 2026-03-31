import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/nupale/royalty_payout.dart';
import '../../utils/enums/royalty_payout_status.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';

class RoyaltyPayoutFirestore {

  final royaltyPayoutsReference = FirebaseFirestore.instance
      .collection(AppFirestoreCollectionConstants.royaltyPayouts);

  Future<String> insert(RoyaltyPayout payout) async {
    AppConfig.logger.d("Inserting royalty payout for ${payout.ownerEmail}");

    try {
      if (payout.id.isNotEmpty) {
        await royaltyPayoutsReference.doc(payout.id).set(payout.toJSON());
      } else {
        DocumentReference ref = await royaltyPayoutsReference.add(payout.toJSON());
        payout.id = ref.id;
        await royaltyPayoutsReference.doc(payout.id).update({'id': payout.id});
      }
      AppConfig.logger.d("RoyaltyPayout ${payout.id} inserted for ${payout.ownerEmail}");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RoyaltyPayoutFirestore.insert');
    }

    return payout.id;
  }

  Future<List<RoyaltyPayout>> fetchByOwner(String ownerEmail) async {
    AppConfig.logger.d("Fetching royalty payouts for $ownerEmail");
    List<RoyaltyPayout> payouts = [];

    try {
      QuerySnapshot querySnapshot = await royaltyPayoutsReference
          .where('ownerEmail', isEqualTo: ownerEmail)
          .orderBy('createdTime', descending: true)
          .get();

      for (var doc in querySnapshot.docs) {
        payouts.add(RoyaltyPayout.fromJSON(doc.data()));
      }
      AppConfig.logger.d("Found ${payouts.length} payouts for $ownerEmail");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RoyaltyPayoutFirestore.fetchByOwner');
    }

    return payouts;
  }

  Future<List<RoyaltyPayout>> fetchByMonth(int month, int year) async {
    AppConfig.logger.d("Fetching royalty payouts for $month/$year");
    List<RoyaltyPayout> payouts = [];

    try {
      QuerySnapshot querySnapshot = await royaltyPayoutsReference
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();

      for (var doc in querySnapshot.docs) {
        payouts.add(RoyaltyPayout.fromJSON(doc.data()));
      }
      AppConfig.logger.d("Found ${payouts.length} payouts for $month/$year");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RoyaltyPayoutFirestore.fetchByMonth');
    }

    return payouts;
  }

  Future<bool> updateStatus(String payoutId, RoyaltyPayoutStatus status) async {
    AppConfig.logger.d("Updating payout $payoutId status to ${status.name}");

    try {
      await royaltyPayoutsReference.doc(payoutId).update({
        'status': status.name,
      });
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RoyaltyPayoutFirestore.updateStatus');
    }

    return false;
  }

  Future<RoyaltyPayout?> fetchByOwnerAndMonth(String ownerEmail, int month, int year) async {
    AppConfig.logger.d("Checking existing payout for $ownerEmail $month/$year");

    try {
      QuerySnapshot querySnapshot = await royaltyPayoutsReference
          .where('ownerEmail', isEqualTo: ownerEmail)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return RoyaltyPayout.fromJSON(querySnapshot.docs.first.data());
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RoyaltyPayoutFirestore.fetchByOwnerAndMonth');
    }

    return null;
  }

  /// Fetches all unclaimed payouts across all owners (for admin view).
  Future<List<RoyaltyPayout>> fetchUnclaimed() async {
    AppConfig.logger.d("Fetching all unclaimed royalty payouts");
    List<RoyaltyPayout> payouts = [];

    try {
      QuerySnapshot querySnapshot = await royaltyPayoutsReference
          .where('status', isEqualTo: RoyaltyPayoutStatus.unclaimed.name)
          .orderBy('createdTime', descending: true)
          .get();

      for (var doc in querySnapshot.docs) {
        payouts.add(RoyaltyPayout.fromJSON(doc.data()));
      }
      AppConfig.logger.d("Found ${payouts.length} unclaimed payouts");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RoyaltyPayoutFirestore.fetchUnclaimed');
    }

    return payouts;
  }

  /// Fetches payouts by owner email and status.
  Future<List<RoyaltyPayout>> fetchByOwnerAndStatus(
      String ownerEmail, RoyaltyPayoutStatus status) async {
    AppConfig.logger.d("Fetching payouts for $ownerEmail with status ${status.name}");
    List<RoyaltyPayout> payouts = [];

    try {
      QuerySnapshot querySnapshot = await royaltyPayoutsReference
          .where('ownerEmail', isEqualTo: ownerEmail)
          .where('status', isEqualTo: status.name)
          .orderBy('createdTime', descending: true)
          .get();

      for (var doc in querySnapshot.docs) {
        payouts.add(RoyaltyPayout.fromJSON(doc.data()));
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RoyaltyPayoutFirestore.fetchByOwnerAndStatus');
    }

    return payouts;
  }

  /// Updates the appCoinsDeposited field after a successful claim.
  Future<bool> updateAppCoinsDeposited(String payoutId, double amount) async {
    AppConfig.logger.d("Updating appCoinsDeposited for $payoutId to $amount");

    try {
      await royaltyPayoutsReference.doc(payoutId).update({
        'appCoinsDeposited': amount,
      });
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RoyaltyPayoutFirestore.updateAppCoinsDeposited');
    }

    return false;
  }

  /// Fetches all payouts (for admin view / statistics).
  Future<List<RoyaltyPayout>> fetchAll() async {
    AppConfig.logger.d("Fetching all royalty payouts");
    List<RoyaltyPayout> payouts = [];

    try {
      QuerySnapshot querySnapshot = await royaltyPayoutsReference
          .orderBy('createdTime', descending: true)
          .get();

      for (var doc in querySnapshot.docs) {
        payouts.add(RoyaltyPayout.fromJSON(doc.data()));
      }
      AppConfig.logger.d("Found ${payouts.length} total payouts");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RoyaltyPayoutFirestore.fetchAll');
    }

    return payouts;
  }
}
