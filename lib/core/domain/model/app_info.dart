class AppInfo {

  String id;
  String version;
  int lastStableBuild;
  bool coinPromo;
  int coinAmount;
  bool fbLoginEnabled;
  bool googleLoginEnabled;
  bool mediaPlayerEnabled;
  int orderNumber;
  String suggestedUrl;

  AppInfo({
    this.id = "",
    this.version = "",
    this.lastStableBuild = 0,
    this.coinPromo = false,
    this.fbLoginEnabled = false,
    this.googleLoginEnabled = true,
    this.mediaPlayerEnabled = true,
    this.coinAmount = 10,
    this.orderNumber = 1,
    this.suggestedUrl = ""
  });


  @override
  String toString() {
    return 'AppInfo{id: $id, version: $version, lastStableBuild: $lastStableBuild, coinPromo: $coinPromo, coinAmount: $coinAmount, fbLoginEnabled: $fbLoginEnabled, orderNumber: $orderNumber, suggestedUrl: $suggestedUrl}';
  }

  AppInfo.fromJSON(data):
    id = data["id"] ?? "",
    version = data["version"] ?? "",
    lastStableBuild = data["lastStableBuild"] ?? 0,
    coinPromo = data["coinPromo"] ?? true,
    coinAmount = data["coinAmount"] ?? 0,
    fbLoginEnabled = data["fbLoginEnabled"] ?? false,
    googleLoginEnabled = data["googleLoginEnabled"] ?? true,
    mediaPlayerEnabled = data["mediaPlayerEnabled"] ?? true,
    orderNumber = data["orderNumber"] ?? 1,
    suggestedUrl = data["suggestedUrl"] ?? "";


  Map<String, dynamic> toJSON() {
    return <String, dynamic> {
      'version': version,
      'lastStableBuild': lastStableBuild,
      'coinPromo': coinPromo,
      'coinAmount': coinAmount,
      'fbLoginEnabled': fbLoginEnabled,
      'googleLoginEnabled': googleLoginEnabled,
      'mediaPlayerEnabled': mediaPlayerEnabled,
      'suggestedUrl': suggestedUrl,
    };
  }

}
