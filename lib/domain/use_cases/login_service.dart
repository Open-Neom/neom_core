import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/enums/auth_status.dart';
import '../../utils/enums/signed_in_with.dart';

abstract class LoginService {

  Future<void> handleAuthChanged(User user);
  void setAuthStatus(AuthStatus status);
  AuthStatus getAuthStatus();

  Future<void> setAuthCredentials();
  AuthCredential? getAuthCredentials();
  Future<void> deleteFbaUser(AuthCredential credential);
  void setIsLoading(bool loading);

  Future<void> appleLogin();
  Future<void> googleLogin();
  Future<void> emailLogin();

  Future<void> signOut();
  Future<void> sendEmailVerification(GlobalKey<ScaffoldState> scaffoldKey);

  Future<void> verifyPhoneNumber(String phoneNumber);
  Future<bool> validateSmsCode(String smsCode);
  void setIsPhoneAuth(bool value);

  SignedInWith get signedInWith;
  set signedInWith(SignedInWith signedInWith);

  fba.FirebaseAuth get auth;

  fba.User? get fbaUser;
  set fbaUser(fba.User? fbaUser);

}
