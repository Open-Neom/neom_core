
import '../model/app_profile.dart';

abstract class SearchService {

  Map<String, AppProfile> get filteredProfiles;
  bool get isLoading;

  void setSearchParam(String param, {bool onlyByName = false});
  Future<void> loadProfiles({bool includeSelf = false});
  void sortByLocation();
  Future<void> loadItems();

}
