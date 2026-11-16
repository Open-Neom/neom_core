import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/app_coupon.dart';
import '../../domain/repository/coupon_repository.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'core_firestore_guard.dart';

class CouponFirestore implements CouponRepository {
  
  CollectionReference<Map<String, dynamic>> get couponsReference =>
      FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.coupons);


  @override
  Future<bool> insert(AppCoupon coupon) async {
    AppConfig.logger.d("insert cupon: ${coupon.description}");
    final cleanCode = coupon.code.trim();

    if (!CoreFirestoreGuard.isSafeDocId(cleanCode)) {
      AppConfig.logger.e("Coupon code is empty or invalid, cannot create coupon.");
      return false;
    }
    coupon.code = cleanCode;
    coupon.id = cleanCode;

    try {
      await couponsReference.doc(cleanCode).set(coupon.toJSON());
      AppConfig.logger.i("Coupon inserted with ID (code): $cleanCode");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'insert');
      return false;
    }
  }

  /// OPTIMIZED: Added limit to prevent scanning entire coupon collection
  /// For most use cases, only active coupons are needed
  @override
  Future<Map<String, AppCoupon>> fetchAll({int limit = 100, bool onlyActive = false}) async {
    final safeLimit = CoreFirestoreGuard.clampLimit(limit, defaultLimit: 100, maxLimit: 500);
    AppConfig.logger.d("fetchAll coupons (limit: $safeLimit, onlyActive: $onlyActive)");
    Map<String, AppCoupon> coupons = {};

    try {
      Query query = couponsReference;

      // OPTIMIZATION: Filter active coupons server-side if needed
      if (onlyActive) {
        query = query.where(AppFirestoreConstants.isActive, isEqualTo: true);
      }

      QuerySnapshot snapshot = await query.limit(safeLimit).get();

      for(var document in snapshot.docs) {
        AppCoupon coupon = AppCoupon.fromJSON(document.data());
        if (coupon.id.isEmpty) coupon.id = document.id;
        coupons[coupon.id] = coupon;
      }

      AppConfig.logger.d("${coupons.length} coupons found");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'fetchAll');
    }

    return coupons;
  }


  @override
  Future<AppCoupon?> getCouponByCode(String couponCode) async {
    final cleanCode = couponCode.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanCode)) return null;
    AppConfig.logger.d("Getting Coupon By Code $cleanCode");

    AppCoupon? coupon;

    try {
      final doc = await couponsReference.doc(cleanCode).get();

      if (doc.exists && doc.data() != null) {
        coupon = AppCoupon.fromJSON(doc.data());
        coupon.id = doc.id;
      } else {
        AppConfig.logger.d("No coupon found with code $cleanCode");
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'getCouponByCode');
    }

    return coupon;
  }

  /// OPTIMIZED: Direct document update instead of get() then update()
  @override
  Future<bool> addUsedBy(String couponId, String email) async {
      final cleanId = couponId.trim();
      final cleanEmail = email.trim();
      if (!CoreFirestoreGuard.isSafeDocId(cleanId) || cleanEmail.isEmpty || cleanEmail.length > 256) {
        return false;
      }

      AppConfig.logger.d("Incrementing usage count for coupon $cleanId");

      try {
        // OPTIMIZATION: Direct update without reading first
        await couponsReference.doc(cleanId).update({
          AppFirestoreConstants.usedBy: FieldValue.arrayUnion([cleanEmail])
        });

        AppConfig.logger.d("Coupon $cleanId was updated to include usedBy $cleanEmail");
        return true;
      } catch (e, st) {
        NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'addUsedBy');
      }

      AppConfig.logger.d("Coupon $cleanId was not updated");
      return false;
  }

}
