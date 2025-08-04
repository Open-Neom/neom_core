import '../../domain/model/app_profile.dart';

abstract class AppDrawerService {

  void updateProfile(AppProfile profile);
  Future<void> initializeSubscriptionService();

}
