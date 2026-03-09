// ignore_for_file: implementation_imports

import 'package:enum_to_string/enum_to_string.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/src/types/google_play_purchase_details.dart';
import 'package:in_app_purchase_storekit/src/types/app_store_purchase_details.dart';

/// Serializes GooglePlayPurchaseDetails to JSON map.
Map<String, dynamic> googlePlayPurchaseDetailsToJSON(dynamic purchaseDetails) {
  final pd = purchaseDetails as GooglePlayPurchaseDetails?;
  return {
    'purchaseId': pd?.purchaseID ?? "",
    'productId': pd?.productID ?? "",
    'transactionDate': pd?.transactionDate ?? "",
    'status': pd?.status.name ?? PurchaseStatus.error.name,
    'verificationData': {
      'localVerificationData': pd?.verificationData.localVerificationData ?? "",
      'serverVerificationData': pd?.verificationData.serverVerificationData ?? "",
      'source': pd?.verificationData.source ?? "",
    }
  };
}

/// Serializes AppStorePurchaseDetails to JSON map.
Map<String, dynamic> appStorePurchaseDetailsToJSON(dynamic purchaseDetails) {
  final pd = purchaseDetails as AppStorePurchaseDetails?;
  return {
    'purchaseId': pd?.purchaseID ?? "",
    'productId': pd?.productID ?? "",
    'transactionDate': pd?.transactionDate ?? "",
    'status': pd?.status.name ?? PurchaseStatus.error.name,
    'verificationData': {
      'localVerificationData': pd?.verificationData.localVerificationData ?? "",
      'serverVerificationData': pd?.verificationData.serverVerificationData ?? "",
      'source': pd?.verificationData.source ?? "",
    }
  };
}

/// Deserializes GooglePlayPurchaseDetails from JSON map.
dynamic googlePlayPurchaseDetailsFromJSON(Map<dynamic, dynamic> data) {
  if (data.isEmpty) return null;
  return GooglePlayPurchaseDetails(
    purchaseID: data["purchaseId"] ?? "",
    productID: data["productId"] ?? "",
    transactionDate: data["transactionDate"] ?? "",
    status: EnumToString.fromString(PurchaseStatus.values, data["status"] ?? PurchaseStatus.error.name)
        ?? PurchaseStatus.error,
    verificationData: PurchaseVerificationData(
      localVerificationData: data["verificationData"]?["localVerificationData"] ?? "",
      serverVerificationData: data["verificationData"]?["serverVerificationData"] ?? "",
      source: data["verificationData"]?["source"] ?? "",
    ),
    billingClientPurchase: PurchaseWrapper(
      orderId: data["billingClientPurchase"]?["orderId"] ?? "",
      packageName: data["billingClientPurchase"]?["packageName"] ?? "",
      purchaseTime: data["billingClientPurchase"]?["purchaseTime"] ?? 0,
      purchaseToken: data["billingClientPurchase"]?["purchaseToken"] ?? "",
      signature: data["billingClientPurchase"]?["signature"] ?? "",
      products: data["billingClientPurchase"]?["products"]?.cast<String>() ?? [],
      isAutoRenewing: data["billingClientPurchase"]?["isAutoRenewing"] ?? false,
      originalJson: data["billingClientPurchase"]?["originalJson"] ?? "",
      developerPayload: data["billingClientPurchase"]?["developerPayload"] ?? "",
      isAcknowledged: data["billingClientPurchase"]?["isAcknowledged"] ?? false,
      purchaseState: EnumToString.fromString(PurchaseStateWrapper.values, (data["billingClientPurchase"]?["purchaseState"]
          ?? PurchaseStateWrapper.unspecified_state.name)) ?? PurchaseStateWrapper.unspecified_state,
      obfuscatedAccountId: data["billingClientPurchase"]?["obfuscatedAccountId"] ?? "",
      obfuscatedProfileId: data["billingClientPurchase"]?["obfuscatedProfileId"] ?? "",
    ),
  );
}

/// Deserializes AppStorePurchaseDetails from JSON map.
dynamic appStorePurchaseDetailsFromJSON(Map<dynamic, dynamic> data) {
  return null;
}
