

abstract class SettingsService {

  void setNewLanguage(String newLang);
  void setNewLocale();
  Future<void> verifyLocationPermission();
  Future<void> runAnalyticJobs();
  Future<void> runProfileJobs();

}
