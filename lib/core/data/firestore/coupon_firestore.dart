import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/app_coupon.dart';
import '../../domain/repository/coupon_repository.dart';
import '../../utils/app_utilities.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class CouponFirestore implements CouponRepository {

  var logger = AppUtilities.logger;
  final couponsReference = FirebaseFirestore.instance
      .collection(AppFirestoreCollectionConstants.coupons);


  @override
  Future<Map<String, AppCoupon>> getCoupons() async {
    logger.d("");
    Map<String, AppCoupon> coupons = {};

    try {
      QuerySnapshot snapshot = await couponsReference.get();

      for (int i = 0; i < snapshot.docs.length; i++) {
        AppCoupon coupon = AppCoupon.fromDocumentSnapshot(snapshot.docs.elementAt(i));
        coupons[coupon.id] = coupon;
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return coupons;
  }


  @override
  Future<AppCoupon> getCouponByCode(String couponCode) async {
    logger.d("Getting Coupon By Code");

    AppCoupon coupon = AppCoupon();

    try {
      QuerySnapshot snapshot = await couponsReference.get();

      for (int i = 0; i < snapshot.docs.length; i++) {
        AppCoupon coupon = AppCoupon.fromDocumentSnapshot(snapshot.docs.elementAt(i));
        if(coupon.code == couponCode) coupon = coupon;
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return coupon;
  }

  @override
  Future<bool> incrementUsageCount(String couponId) async {

      logger.d("Incrementing usage count for coupon $couponId");

      try {

        await couponsReference.get()
            .then((querySnapshot) async {
          for (var document in querySnapshot.docs) {
            if(document.id == couponId) {
              AppCoupon coupon = AppCoupon.fromDocumentSnapshot(document);
              coupon.usageCount = coupon.usageCount + 1;
              await document.reference.update({
                AppFirestoreConstants.usageCount: coupon.usageCount
              });

              logger.d("Coupon $couponId was updated to usageCount ${coupon.usageCount}");
            }
          }
        });

        return true;
      } catch (e) {
        logger.e(e.toString());
      }

      logger.d("Coupon $couponId was not updated");
      return false;
  }


  @override
  Future<String> insert(AppCoupon coupon) async {
    logger.d("");
    String couponId = "";
    try {
      DocumentReference documentReference = await couponsReference
          .add(coupon.toJSON());
      couponId = documentReference.id;
    } catch (e) {
      logger.e(e.toString());
    }

    return couponId;
  }

}
