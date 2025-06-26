class AppInfo {

  String version;
  int build;

  bool googleLoginEnabled;
  bool mediaPlayerEnabled;

  int orderNumber;
  String suggestedUrl;

  bool hideNupale;
  bool hideCasete;
  bool hideWallet;

  ///DEPRECATED
  //bool coinPromo;
  // int coinAmount;
  // bool fbLoginEnabled;

  AppInfo({
    this.version = "",
    this.build = 0,
    this.googleLoginEnabled = true,
    this.mediaPlayerEnabled = true,
    this.orderNumber = 1,
    this.suggestedUrl = "",
    this.hideNupale = false,
    this.hideCasete = false,
    this.hideWallet = false,
  });


  @override
  String toString() {
    return 'AppInfo{version: $version, build: $build, googleLoginEnabled: $googleLoginEnabled, mediaPlayerEnabled: $mediaPlayerEnabled, orderNumber: $orderNumber, suggestedUrl: $suggestedUrl, hideNupale: $hideNupale, hideCasete: $hideCasete, hideWallet: $hideWallet}';
  }

  AppInfo.fromJSON(data):
    version = data["version"] ?? "",
    build = data["build"] ?? 0,
    googleLoginEnabled = data["googleLoginEnabled"] ?? true,
    mediaPlayerEnabled = data["mediaPlayerEnabled"] ?? true,
    orderNumber = data["orderNumber"] ?? 1,
    suggestedUrl = data["suggestedUrl"] ?? "",
    hideNupale = data["hideNupale"] ?? false,
    hideCasete = data["hideCasete"] ?? false,
    hideWallet = data["hideWallet"] ?? false;


  Map<String, dynamic> toJSON() {
    return <String, dynamic> {
      'version': version,
      'build': build,
      'googleLoginEnabled': googleLoginEnabled,
      'mediaPlayerEnabled': mediaPlayerEnabled,
      'suggestedUrl': suggestedUrl,
      'orderNumber': orderNumber,
      'hideNupale': hideNupale,
      'hideCasete': hideCasete,
      'hideWallet': hideWallet,
    };
  }

}
