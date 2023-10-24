// ignore_for_file: unused_import
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../core/data/firestore/app_info_firestore.dart';
import '../../../core/data/firestore/constants/app_firestore_constants.dart';
import '../../../core/data/implementations/shared_preference_controller.dart';
import '../../../core/data/implementations/user_controller.dart';
import '../../../core/domain/model/app_info.dart';
import '../../../core/ui/static/previous_version_page.dart';
import '../../../core/ui/static/splash_page.dart';
import '../../../core/utils/app_utilities.dart';
import '../../../core/utils/constants/app_analytics_constants.dart';
import '../../../core/utils/constants/app_constants.dart';
import '../../../core/utils/constants/app_page_id_constants.dart';
import '../../../core/utils/constants/app_route_constants.dart';
import '../../../core/utils/constants/message_translation_constants.dart';
import '../../../core/utils/core_utilities.dart';
import '../../../core/utils/enums/auth_status.dart';
import '../../domain/use_cases/login_service.dart';
import '../../utils/enums/login_method.dart';
import '../../utils/enums/signed_in_with.dart';
import '../on_going.dart';
import 'login_page.dart';


class LoginController extends GetxController implements LoginService {

  final logger = AppUtilities.logger;
  final userController = Get.find<UserController>();
  final sharedPreferenceController = Get.find<SharedPreferenceController>();

  final TextEditingController _emailController = TextEditingController();
  TextEditingController get emailController => _emailController;

  final TextEditingController _passwordController = TextEditingController();
  TextEditingController get passwordController => _passwordController;

  final Rx<AuthStatus> _authStatus = AuthStatus.notDetermined.obs;
  AuthStatus get authStatus => _authStatus.value;
  set authStatus(AuthStatus authStatus) => _authStatus.value = authStatus;

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  //TODO Verify if its not needed
  //final SignInWithApple _appleSignIn = SignInWithApple();

  String _userId = "";
  final String _fbAccessToken = "";
  fba.AuthCredential? credentials;

  fba.FirebaseAuth auth = fba.FirebaseAuth.instance;

  final Rxn<fba.User> _fbaUser = Rxn<fba.User>();
  fba.User get fbaUser => _fbaUser.value!;
  set fbaUser(fba.User? fbaUser) => _fbaUser.value = fbaUser;

  SignedInWith signedInWith = SignedInWith.notDetermined;

  LoginMethod loginMethod = LoginMethod.notDetermined;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  final Rxn<AppInfo> _appInfo = Rxn<AppInfo>();
  AppInfo get appInfo => _appInfo.value!;
  set appInfo(AppInfo appInfo) => _appInfo.value = appInfo;


  bool isIOS13 = false;

  @override
  void onInit() async {
    super.onInit();
    logger.d("");
    appInfo = AppInfo();
    fbaUser = auth.currentUser;
    ever(_fbaUser, handleAuthChanged);
    _fbaUser.bindStream(auth.authStateChanges());


    if(Platform.isIOS) {
      isIOS13 = AppUtilities.isDeviceSupportedVersion(isIOS: Platform.isIOS);
    } else if (Platform.isAndroid) {
      logger.i(Platform.version);
    }
  }

  @override
  void onReady() async {
    super.onReady();
    logger.d("");
    await getAppInfo();
    isLoading = false;
    update([AppPageIdConstants.login]);
  }

  @override
  Future<void> handleAuthChanged(user) async {
    logger.t("");
    authStatus = AuthStatus.waiting;

    try {
      if(auth.currentUser == null) {
        authStatus = AuthStatus.notLoggedIn;
        auth = fba.FirebaseAuth.instance;
      } else if (user == null) {
        authStatus = AuthStatus.notLoggedIn;
        user = auth.currentUser;
      } else {
        if(user.providerData.isNotEmpty){
          _userId = user.providerData.first.uid!;
          await userController.getUserById(_userId);
        }

        if (userController.user!.id.isEmpty) {
          switch(signedInWith) {
            case(SignedInWith.email):
              userController.getUserFromFirebase(user);
              break;
            case(SignedInWith.facebook):
              await userController.getUserFromFacebook(_fbAccessToken);
              break;
            case(SignedInWith.apple):
              userController.getUserFromFirebase(user);
              break;
            case(SignedInWith.google):
              userController.getUserFromFirebase(user);
              break;
            case(SignedInWith.spotify):
              break;
            case(SignedInWith.signUp):
              break;
            case(SignedInWith.notDetermined):
              authStatus = AuthStatus.notDetermined;
              break;
          }
        } else if(!userController.isNewUser && userController.user!.profiles.isEmpty) {
          logger.i("No Profiles found for $_userId. Please Login Again");
          authStatus = AuthStatus.notLoggedIn;
        } else {
          authStatus = AuthStatus.loggedIn;
        }

        if (userController.isNewUser && userController.user!.id.isNotEmpty) {
          authStatus = AuthStatus.loggedIn;
          Get.offAndToNamed(AppRouteConstants.introRequiredPermissions);
        } else {
          sharedPreferenceController.setFirstTime(false);
          Get.offAllNamed(AppRouteConstants.root);
        }
      }
    } catch (e) {
      logger.e(e.toString());
      Get.snackbar(
        MessageTranslationConstants.errorHandlingAuth,
        e.toString(),
        snackPosition: SnackPosition.bottom,
      );
      Get.offAllNamed(AppRouteConstants.root);
    } finally {
      isLoading = false;
    }

    update([AppPageIdConstants.login]);
  }

  @override
  Future<void> getAppInfo() async {
    appInfo = await AppInfoFirestore().retrieve();
    logger.i(appInfo.toString());
    update([AppPageIdConstants.login]);
  }


  @override
  Future<void> handleLogin(LoginMethod logMethod) async {

    isButtonDisabled = true;
    isLoading = true;
    update([AppPageIdConstants.login]);

    loginMethod = logMethod;

    try {
      switch (loginMethod) {
        case LoginMethod.facebook:
          break;
        case LoginMethod.spotify:
        //TODO
        // await spotifyLogin();
          break;
        case LoginMethod.apple:
          await appleLogin();
          break;
        case LoginMethod.google:
          await googleLogin();
          break;
        case LoginMethod.email:
          await emailLogin();
          break;
        case LoginMethod.notDetermined:
          break;
      }

    } catch (e) {
      logger.e(e.toString());
      isLoading = false;
    }

    isButtonDisabled = false;
    update([AppPageIdConstants.login]);

  }

  @override
  Future<void> emailLogin() async {

    //TODO
    //GigUtilities.kAnalytics.logLogin(loginMethod: GigAnalyticsConstants.email_login);

    fba.User? emailUser;
    try {
      fba.UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim()
      );

       if(userCredential.user != null) {
         emailUser = userCredential.user;
         fbaUser = emailUser;
         authStatus = AuthStatus.loggedIn;
         signedInWith = SignedInWith.email;
       }
    } on fba.FirebaseAuthException catch (e) {
      logger.e(e.toString());

      String errorMsg = "";
      switch (e.code) {
        case AppFirestoreConstants.wrongPassword:
          errorMsg = MessageTranslationConstants.invalidPassword;
          break;
        case AppFirestoreConstants.invalidEmail:
          errorMsg = MessageTranslationConstants.invalidEmailFormat;
          break;
        case AppFirestoreConstants.userNotFound:
          errorMsg = MessageTranslationConstants.userNotFound;
          break;
        case AppFirestoreConstants.unknown:
          errorMsg = MessageTranslationConstants.pleaseFillSignUpForm;
          break;

      }

      Get.snackbar(
        MessageTranslationConstants.errorLoginEmail.tr,
        errorMsg.tr,
        snackPosition: SnackPosition.bottom,
      );

    } catch (e) {
      logger.e(e.toString());
      Get.snackbar(
        MessageTranslationConstants.errorLoginEmail.tr,
        e.toString(),
        snackPosition: SnackPosition.bottom,
      );
    } finally {
      isButtonDisabled = false;
      if(emailUser == null) {
        isLoading = false;
      }
    }

    update([AppPageIdConstants.login]);
  }


  String generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }


  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }


  @override
  Future<void> appleLogin() async {

    logger.d("Entering Logging Method with Apple Account");

    fba.AuthCredential? oauthCredential;

    try {
      //TODO
      //await GigUtilities.kAnalytics.logLogin(loginMethod: GigAnalyticsConstants.apple_login);

       oauthCredential = await getAuthCredentials();

      if(oauthCredential != null) {
        fbaUser = (await auth.signInWithCredential(oauthCredential)).user;
        authStatus = AuthStatus.loggedIn;
        signedInWith = SignedInWith.apple;
      }

    } on SignInWithAppleAuthorizationException catch (e) {

      logger.e(e.toString());
      fbaUser = null;
      authStatus = AuthStatus.notLoggedIn;

      if(e.code != AuthorizationErrorCode.canceled) {
        Get.snackbar(
          MessageTranslationConstants.errorLoginApple.tr,
          MessageTranslationConstants.errorLoginApple.tr,
          snackPosition: SnackPosition.bottom,
        );
      }

    }  catch (e) {
      fbaUser = null;
      authStatus = AuthStatus.notLoggedIn;
      logger.e(e.toString());

      Get.snackbar(
        MessageTranslationConstants.errorLoginApple.tr,
        MessageTranslationConstants.errorLoginApple.tr,
        snackPosition: SnackPosition.bottom,
      );
    } finally {
      isLoading = false;
      isButtonDisabled = false;
      if(oauthCredential == null) {
        isButtonDisabled = false;
      }
    }

    update([AppPageIdConstants.login]);
  }


  @override
  Future<void> googleLogin() async {

    logger.i("Entering Logging Method with Google Account");

    try {

      //TODO
      //await GigUtilities.kAnalytics.logLogin(loginMethod: GigAnalyticsConstants.google_login);
       credentials = await getAuthCredentials();

      if(credentials != null) {
        fbaUser = (await auth.signInWithCredential(credentials!)).user;
        authStatus = AuthStatus.loggedIn;
        signedInWith = SignedInWith.google;
      }


    } catch (e) {
      fbaUser = null;
      authStatus = AuthStatus.notLoggedIn;
      logger.e(e.toString());
      Get.snackbar(
        MessageTranslationConstants.errorLoginGoogle.tr,
        MessageTranslationConstants.errorLoginGoogle.tr,
        snackPosition: SnackPosition.bottom,
      );
    } finally {
      isButtonDisabled = false;
      if(credentials == null) {
        isLoading = false;
      }
    }

    update([AppPageIdConstants.login]);
  }

  //TODO To Verify Implementation
  Future<void> googleLogout() async {
    try {
      await _googleSignIn.signOut();
    } catch (e){
      logger.e(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    logger.d("Entering signOut method");
    try {
      await auth.signOut();
      await googleLogout();
      clear();
      Get.offAllNamed(AppRouteConstants.login);
    } catch (e) {
      Get.snackbar(
        MessageTranslationConstants.errorSigningOut.tr,
        e.toString(),
        snackPosition: SnackPosition.bottom,
      );
    }

    logger.i("signOut method finished");
    update([AppPageIdConstants.login]);
  }


  @override
  Future<void> sendEmailVerification(GlobalKey<ScaffoldState> scaffoldKey) {
    throw UnimplementedError();
  }


  void clear() {
    fbaUser = null;
    authStatus = AuthStatus.notDetermined;
    isButtonDisabled = false;
  }


  Future<fba.AuthCredential?> getAuthCredentials() async {


    try {
      switch(loginMethod) {
        case(LoginMethod.email):
          credentials = fba.EmailAuthProvider.credential(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim()
          );
          break;
        case(LoginMethod.facebook):
          credentials = fba.FacebookAuthProvider.credential(_fbAccessToken);
          break;
        case(LoginMethod.apple):
        // To prevent replay attacks with the credential returned from Apple, we
        // include a nonce in the credential request. When signing in with
        // Firebase, the nonce in the id token returned by Apple, is expected to
        // match the sha256 hash of `rawNonce`.
          final rawNonce = generateNonce();
          final nonce = sha256ofString(rawNonce);

          AuthorizationCredentialAppleID appleCredential = await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: nonce,
          );
          credentials = fba.OAuthProvider("apple.com").credential(
            idToken: appleCredential.identityToken,
            rawNonce: rawNonce,
          );
          break;
        case(LoginMethod.google):
          final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
          GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
          credentials = fba.GoogleAuthProvider.credential(
              idToken: googleAuth.idToken,
              accessToken: googleAuth.accessToken
          );
          break;
        case(LoginMethod.spotify):
          break;
        case(LoginMethod.notDetermined):
          await signOut();
          break;
      }
    } catch (e) {
      logger.e(e.toString());
      AppUtilities.showSnackBar(
        title: MessageTranslationConstants.underConstruction.tr,
        message: e.toString(),
      );
    }

    update([AppPageIdConstants.login]);
    return credentials;
  }

  @override
  void setAuthStatus(AuthStatus status) {
    authStatus = status;
    update([AppPageIdConstants.login]);
  }

  @override
  Widget selectRootPage({required StatelessWidget homePage, required int appLastStableBuild}) {

    Widget rootPage = const LoginPage();

    if (appInfo.lastStableBuild > appLastStableBuild) {
      rootPage = const PreviousVersionPage();
    } else if(sharedPreferenceController.firstTime) {
      rootPage = const OnGoing();
      sharedPreferenceController.updateFirstTIme(false);
    } else if(authStatus == AuthStatus.loggingIn) {
      rootPage = const SplashPage();
    } else if (authStatus == AuthStatus.loggedIn
      && (userController.user?.id.isNotEmpty ?? false)
      && ((userController.user?.profiles.isNotEmpty ?? false)
            && (userController.user?.profiles.first.id.isNotEmpty ?? false)
        )
    ) {
      rootPage = homePage;
      isLoading = true;
    }

    return rootPage;
  }


  @override
  void setIsLoading(bool loading) {
    isLoading = loading;
    update([AppPageIdConstants.login]);
  }

}
