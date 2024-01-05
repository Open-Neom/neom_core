import 'package:firebase_auth/firebase_auth.dart';

abstract class UserService {

  Future<void> createUser();
  Future<void> removeAccount();
  Future<void> getUserFromFacebook(String fbAccessToken);
  void getUserFromFirebase(User fbaUser);
  Future<void> getUserById(String userId);
  Future<void> createProfile();
  Future<void> getProfiles();
  Future<void> removeProfile();
  Future<void> reloadProfileItemlists();
  Future<void> reloadProfileChambers();

}
