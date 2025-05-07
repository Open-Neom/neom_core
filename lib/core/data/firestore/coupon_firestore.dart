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
  Future<bool> insert(AppCoupon coupon) async {
    AppUtilities.logger.d("insert cupon: ${coupon.description}");
    String couponId = "";

    // Verificar que el código del cupón no esté vacío antes de usarlo como ID
    if (coupon.code.isEmpty) {
      AppUtilities.logger.e("Coupon code is empty, cannot create it with no code.");
      return false; // Retornar cadena vacía o manejar el error apropiadamente
    } else {
      coupon.id = coupon.code;
    }

    try {
      await couponsReference.doc(coupon.code).set(coupon.toJSON());
      AppUtilities.logger.i("Coupon inserted with ID (code): $couponId");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return true;
  }
  
  @override
  Future<Map<String, AppCoupon>> fetchAll() async {
    AppUtilities.logger.d("fetchAll");
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
  Future<AppCoupon?> getCouponByCode(String couponCode) async {
    AppUtilities.logger.d("Getting Coupon By Code $couponCode");

    AppCoupon? coupon;

    try {
      QuerySnapshot querySnapshot = await couponsReference.where(FieldPath.documentId, isEqualTo: couponCode).get();

      if (querySnapshot.docs.isNotEmpty) {
        coupon = AppCoupon.fromJSON(querySnapshot.docs.first.data());
        coupon.id = querySnapshot.docs.first.id;
      } else {
        AppUtilities.logger.d("No coupon found with code $couponCode");
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
          AppFirestoreConstants.usedBy: FieldValue.arrayUnion([email])
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
