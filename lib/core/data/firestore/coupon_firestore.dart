import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/app_coupon.dart';
import '../../domain/repository/coupon_repository.dart';
import '../../utils/app_utilities.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class CouponFirestore implements CouponRepository {
  
  final couponsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.coupons);


  @override
  Future<String> insert(AppCoupon coupon) async {
    AppUtilities.logger.d("insert cupon: ${coupon.description}");
    String couponId = "";
    try {
      DocumentReference documentReference = await couponsReference
          .add(coupon.toJSON());
      couponId = documentReference.id;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return couponId;
  }
  
  @override
  Future<Map<String, AppCoupon>> getCoupons() async {
    AppUtilities.logger.d("getCoupons");
    Map<String, AppCoupon> coupons = {};

    try {
      QuerySnapshot snapshot = await couponsReference.get();

      for(var document in snapshot.docs) {
        AppCoupon coupon = AppCoupon.fromJSON(document.data());
        coupons[coupon.id] = coupon;
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return coupons;
  }


  @override
  Future<AppCoupon> getCouponByCode(String couponCode) async {
    AppUtilities.logger.d("Getting Coupon By Code");

    AppCoupon coupon = AppCoupon();

    try {
      QuerySnapshot snapshot = await couponsReference.get();

      for(var document in snapshot.docs) {
        AppCoupon coupon = AppCoupon.fromJSON(document.data());
        if(coupon.code == couponCode) coupon = coupon;
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return coupon;
  }

  @override
  Future<bool> addUsedBy(String couponId, String email) async {

      AppUtilities.logger.d("Incrementing usage count for coupon $couponId");

      try {
        DocumentSnapshot documentSnapshot = await couponsReference.doc(couponId).get();
        await documentSnapshot.reference.update({
          AppFirestoreConstants.orderIds: FieldValue.arrayUnion([email])
        });

        AppUtilities.logger.d("Coupon $couponId was updated to include usedBy $email");
        return true;
      } catch (e) {
        AppUtilities.logger.e(e.toString());
      }

      AppUtilities.logger.d("Coupon $couponId was not updated");
      return false;
  }

}
