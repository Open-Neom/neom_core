class AppInfo {

  String id;
  String version;
  bool coinPromo;
  double coinAmount;
  bool fbLoginEnabled;
  int orderNumber;
  String suggestedUrl;

  AppInfo({
    this.id = "",
    this.version = "",
    this.coinPromo = true,
    this.fbLoginEnabled = false,
    this.coinAmount = 10.00,
    this.orderNumber = 1,
    this.suggestedUrl = ""
  });

  @override
  String toString() {
    return 'AppInfo{id: $id, version: $version, coinPromo: $coinPromo, coinAmount: $coinAmount, fbLoginEnabled: $fbLoginEnabled, orderNumber: $orderNumber, suggestedUrl: $suggestedUrl}';
  }

  AppInfo.fromJSON(data):
    id = data["id"] ?? "",
    version = data["version"] ?? "",
    coinPromo = data["coinPromo"] ?? true,
    coinAmount = double.parse(data["coinAmount"].toString()),
    fbLoginEnabled = data["fbLoginEnabled"] ?? false,
    orderNumber = data["orderNumber"] ?? 1,
    suggestedUrl = data["suggestedUrl"] ?? "";


  Map<String, dynamic> toJSON() {
    return <String, dynamic> {
      'version': version,
      'coinPromo': coinPromo,
      'coinAmount': coinAmount,
      'fbLoginEnabled': fbLoginEnabled,
      'suggestedUrl': suggestedUrl,
    };
  }

}
