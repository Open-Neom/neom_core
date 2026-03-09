/// Stub serialization for in-app purchase details on web.
/// IAP is not available on web, so all operations return empty/null.
library;

Map<String, dynamic> googlePlayPurchaseDetailsToJSON(dynamic purchaseDetails) => {};

Map<String, dynamic> appStorePurchaseDetailsToJSON(dynamic purchaseDetails) => {};

dynamic googlePlayPurchaseDetailsFromJSON(Map<dynamic, dynamic> data) => null;

dynamic appStorePurchaseDetailsFromJSON(Map<dynamic, dynamic> data) => null;
