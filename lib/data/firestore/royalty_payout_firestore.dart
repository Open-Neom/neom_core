import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/nupale/royalty_payout.dart';
import '../../utils/enums/royalty_payout_status.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'core_firestore_guard.dart';

class RoyaltyPayoutFirestore {

  CollectionReference<Map<String, dynamic>> get royaltyPayoutsReference =>
      FirebaseFirestore.instance
          .collection(AppFirestoreCollectionConstants.royaltyPayouts);

  Future<String> insert(RoyaltyPayout payout) async {
    AppConfig.logger.d("Inserting royalty payout for ${payout.ownerEmail}");

    try {
      final cleanId = payout.id.trim();
      if (cleanId.isNotEmpty) {
        if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return '';
        await royaltyPayoutsReference.doc(cleanId).set(payout.toJSON());
      } else {
        final ref = royaltyPayoutsReference.doc();
        payout.id = ref.id;
        await ref.set(payout.toJSON());
      }
      AppConfig.logger.d("RoyaltyPayout ${payout.id} inserted for ${payout.ownerEmail}");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RoyaltyPayoutFirestore.insert');
    }

    return payout.id;
  }

  Future<List<RoyaltyPayout>> fetchByOwner(String ownerEmail) async {
    final cleanEmail = ownerEmail.trim();
    if (cleanEmail.isEmpty || cleanEmail.length > 256) return [];
    AppConfig.logger.d("Fetching royalty payouts for $cleanEmail");
    List<RoyaltyPayout> payouts = [];

    try {
      QuerySnapshot querySnapshot = await royaltyPayoutsReference
          .where('ownerEmail', isEqualTo: cleanEmail)
          .orderBy('createdTime', descending: true)
          .limit(500)
          .get();

      for (var doc in querySnapshot.docs) {
        payouts.add(RoyaltyPayout.fromJSON(doc.data()));
      }
      AppConfig.logger.d("Found ${payouts.length} payouts for $cleanEmail");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RoyaltyPayoutFirestore.fetchByOwner');
    }

    return payouts;
  }

  Future<List<RoyaltyPayout>> fetchByMonth(int month, int year) async {
    if (month < 1 || month > 12 || year < 2000 || year > 2100) return [];
    AppConfig.logger.d("Fetching royalty payouts for $month/$year");
    List<RoyaltyPayout> payouts = [];

    try {
      QuerySnapshot querySnapshot = await royaltyPayoutsReference
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .limit(500)
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
    final cleanId = payoutId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.d("Updating payout $cleanId status to ${status.name}");

    try {
      await royaltyPayoutsReference.doc(cleanId).update({
        'status': status.name,
      });
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'RoyaltyPayoutFirestore.updateStatus');
    }

    return false;
  }

  Future<RoyaltyPayout?> fetchByOwnerAndMonth(String ownerEmail, int month, int year) async {
    final cleanEmail = ownerEmail.trim();
    if (cleanEmail.isEmpty || month < 1 || month > 12 || year < 2000 || year > 2100) {
      return null;
    }
    AppConfig.logger.d("Checking existing payout for $cleanEmail $month/$year");

    try {
      QuerySnapshot querySnapshot = await royaltyPayoutsReference
          .where('ownerEmail', isEqualTo: cleanEmail)
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
          .limit(500)
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
    final cleanEmail = ownerEmail.trim();
    if (cleanEmail.isEmpty || cleanEmail.length > 256) return [];
    AppConfig.logger.d("Fetching payouts for $cleanEmail with status ${status.name}");
    List<RoyaltyPayout> payouts = [];

    try {
      QuerySnapshot querySnapshot = await royaltyPayoutsReference
          .where('ownerEmail', isEqualTo: cleanEmail)
          .where('status', isEqualTo: status.name)
          .orderBy('createdTime', descending: true)
          .limit(500)
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
    final cleanId = payoutId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    if (!amount.isFinite || amount < 0 || amount > 1e9) return false;
    AppConfig.logger.d("Updating appCoinsDeposited for $cleanId to $amount");

    try {
      await royaltyPayoutsReference.doc(cleanId).update({
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
          .limit(500)
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
