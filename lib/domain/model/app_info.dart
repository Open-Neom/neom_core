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
  bool maintenanceMode;
  bool releaseRevisionEnabled;
  bool demoReleaseEnabled;
  bool showAds;

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
    this.maintenanceMode = false,
    this.releaseRevisionEnabled = false,
    this.demoReleaseEnabled = false,
    this.showAds = false,
  });


  @override
  String toString() {
    return 'AppInfo{version: $version, build: $build, googleLoginEnabled: $googleLoginEnabled, mediaPlayerEnabled: $mediaPlayerEnabled, orderNumber: $orderNumber, suggestedUrl: $suggestedUrl, hideNupale: $hideNupale, hideCasete: $hideCasete, hideWallet: $hideWallet, maintenanceMode: $maintenanceMode, releaseRevisionEnabled: $releaseRevisionEnabled, demoReleaseEnabled: $demoReleaseEnabled, showAds: $showAds}';
  }

  AppInfo.fromJSON(dynamic data):
    version = data["version"] ?? "",
    build = data["build"] ?? 0,
    googleLoginEnabled = data["googleLoginEnabled"] ?? true,
    mediaPlayerEnabled = data["mediaPlayerEnabled"] ?? true,
    orderNumber = data["orderNumber"] ?? 1,
    suggestedUrl = data["suggestedUrl"] ?? "",
    hideNupale = data["hideNupale"] ?? false,
    hideCasete = data["hideCasete"] ?? false,
    hideWallet = data["hideWallet"] ?? false,
    maintenanceMode = data["maintenanceMode"] ?? false,
    releaseRevisionEnabled = data["releaseRevisionEnabled"] ?? false,
    demoReleaseEnabled = data["demoReleaseEnabled"] ?? false,
    showAds = data["showAds"] ?? false;


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
      'maintenanceMode': maintenanceMode,
      'releaseRevisionEnabled': releaseRevisionEnabled,
      'demoReleaseEnabled': demoReleaseEnabled,
      'showAds': showAds,
    };
  }

}
