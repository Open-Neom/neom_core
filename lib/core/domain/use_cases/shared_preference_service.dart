
import '../../utils/enums/app_locale.dart';

abstract class SharedPreferenceService {

  Future<void> readLocal();
  Future<void> writeLocal();
  Future<void> updateLocale(AppLocale languageCode);
  Future<void> setFirstTime(bool fTime);
  void setLocale(AppLocale locale);
  Future<void> updateFirstTIme(bool isFirstTime);

}
