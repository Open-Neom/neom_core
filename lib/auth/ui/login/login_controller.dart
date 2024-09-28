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
import '../../../core/utils/validator.dart';
import '../../domain/use_cases/login_service.dart';
import '../../utils/enums/login_method.dart';
import '../../utils/enums/signed_in_with.dart';
import '../on_going.dart';
import 'login_page.dart';


class LoginController extends GetxController implements LoginService {

  final userController = Get.find<UserController>();
  final sharedPreferenceController = Get.find<SharedPreferenceController>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final Rx<AuthStatus> authStatus = AuthStatus.notDetermined.obs;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  //TODO Verify if its not needed
  //final SignInWithApple _appleSignIn = SignInWithApple();

  String _userId = "";
  final String _fbAccessToken = "";
  fba.AuthCredential? credentials;

  fba.FirebaseAuth auth = fba.FirebaseAuth.instance;
  final Rxn<fba.User> fbaUser = Rxn<fba.User>();
  
  SignedInWith signedInWith = SignedInWith.notDetermined;
  LoginMethod loginMethod = LoginMethod.notDetermined;
  
  final RxBool isLoading = true.obs;
  final RxBool isButtonDisabled = false.obs;
  final Rx<AppInfo> appInfo = AppInfo().obs;

  bool isPhoneAuth = false;
  String phoneVerificationId = '';

  bool isIOS13OrHigher = false;

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.t("onInit Login Controller");
    appInfo.value = AppInfo();
    fbaUser.value = auth.currentUser;
    ever(fbaUser, handleAuthChanged);
    fbaUser.bindStream(auth.authStateChanges());

    if(Platform.isIOS) {
      isIOS13OrHigher = AppUtilities.isDeviceSupportedVersion(isIOS: Platform.isIOS);
    } else if (Platform.isAndroid) {
      AppUtilities.logger.t(Platform.version);
    }
  }

  @override
  void onReady() async {
    super.onReady();
    AppUtilities.logger.t("onReady Login Controller");
    await getAppInfo();
    isLoading.value = false;
    update([AppPageIdConstants.login]);
  }

  @override
  Future<void> handleAuthChanged(user) async {
    AppUtilities.logger.d("handleAuthChanged");
    authStatus.value = AuthStatus.waiting;

    if(isPhoneAuth) return;

    try {
      if(auth.currentUser == null) {
        authStatus.value = AuthStatus.notLoggedIn;
        auth = fba.FirebaseAuth.instance;
      } else if (user == null) {
        authStatus.value = AuthStatus.notLoggedIn;
        user = auth.currentUser;
      } else {
        if(user.providerData.isNotEmpty){
          _userId = user.providerData.first.uid!;
          if(Validator.isEmail(_userId)) {
            await userController.getUserByEmail(_userId);
          } else {
            await userController.getUserById(_userId);
          }

        }

        if (userController.user.id.isEmpty) {
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
              authStatus.value = AuthStatus.notDetermined;
              break;
          }
        } else if(!userController.isNewUser && userController.user.profiles.isEmpty) {
          AppUtilities.logger.i("No Profiles found for $_userId. Please Login Again");
          authStatus.value = AuthStatus.notLoggedIn;
        } else {
          authStatus.value = AuthStatus.loggedIn;
        }

        if (userController.isNewUser && userController.user.id.isNotEmpty) {
          authStatus.value = AuthStatus.loggedIn;
          Get.toNamed(AppRouteConstants.introRequiredPermissions);
        } else {
          sharedPreferenceController.setFirstTime(false);
          Get.offAllNamed(AppRouteConstants.root);
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
      AppUtilities.showSnackBar(
        title: MessageTranslationConstants.errorHandlingAuth,
        message: e.toString()
      );
      Get.offAllNamed(AppRouteConstants.root);
    } finally {
      isLoading.value = false;
    }

    update([AppPageIdConstants.login]);
  }

  @override
  Future<void> getAppInfo() async {
    appInfo.value = await AppInfoFirestore().retrieve();
    AppUtilities.logger.i(appInfo.value.toString());
    update([AppPageIdConstants.login]);
  }


  @override
  Future<void> handleLogin(LoginMethod logMethod) async {

    isButtonDisabled.value = true;
    isLoading.value = true;
    update([AppPageIdConstants.login]);

    loginMethod = logMethod;

    try {
      switch (loginMethod) {
        case LoginMethod.email:
          await emailLogin();
          break;
        case LoginMethod.google:
          await googleLogin();
          break;
        case LoginMethod.apple:
          await appleLogin();
          break;
        case LoginMethod.facebook:
          break;
        case LoginMethod.spotify:
          break;
        case LoginMethod.notDetermined:
          break;
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
      isLoading.value = false;
    }

    isButtonDisabled.value = false;
    update([AppPageIdConstants.login]);
  }

  @override
  Future<void> emailLogin() async {

    //TODO
    //GigUtilities.kAnalytics.logLogin(loginMethod: GigAnalyticsConstants.email_login);

    fba.User? emailUser;
    try {
      fba.UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim()
      );

       if(userCredential.user != null) {
         emailUser = userCredential.user;
         fbaUser.value = emailUser;
         authStatus.value = AuthStatus.loggedIn;
         signedInWith = SignedInWith.email;
       }
    } on fba.FirebaseAuthException catch (e) {
      AppUtilities.logger.e(e.toString());

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

      AppUtilities.showSnackBar(
          title: MessageTranslationConstants.errorLoginEmail.tr,
          message: errorMsg.tr
      );
    } catch (e) {
      AppUtilities.logger.e(e.toString());
      AppUtilities.showSnackBar(
          title: MessageTranslationConstants.errorLoginEmail.tr,
          message: e.toString(),
      );
    } finally {
      isButtonDisabled.value = false;
      if(emailUser == null) {
        isLoading.value = false;
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

    AppUtilities.logger.d("Entering Logging Method with Apple Account");

    fba.AuthCredential? oauthCredential;

    try {
      //TODO
      //await GigUtilities.kAnalytics.logLogin(loginMethod: GigAnalyticsConstants.apple_login);

       oauthCredential = await getAuthCredentials();

      if(oauthCredential != null) {
        fba.UserCredential userCredential = await auth.signInWithCredential(oauthCredential);
        fbaUser.value = userCredential.user;
        authStatus.value = AuthStatus.loggedIn;
        signedInWith = SignedInWith.apple;
      }

    } on SignInWithAppleAuthorizationException catch (e) {

      AppUtilities.logger.e(e.toString());
      fbaUser.value = null;
      authStatus.value = AuthStatus.notLoggedIn;

      if(e.code != AuthorizationErrorCode.canceled) {
        AppUtilities.showSnackBar(
          title: MessageTranslationConstants.errorLoginApple.tr,
          message: MessageTranslationConstants.errorLoginApple.tr,
        );
      }

    } catch (e) {
      fbaUser.value = null;
      authStatus.value = AuthStatus.notLoggedIn;
      AppUtilities.logger.e(e.toString());

      AppUtilities.showSnackBar(
        title: MessageTranslationConstants.errorLoginApple.tr,
        message: MessageTranslationConstants.errorLoginApple.tr,
      );
    } finally {
      isButtonDisabled.value = false;
      isLoading.value = false;
      ///DEPRECATED
      // if(oauthCredential == null) {
      //   isLoading.value = false;
      // }
    }

    update([AppPageIdConstants.login]);
  }


  @override
  Future<void> googleLogin() async {

    AppUtilities.logger.i("Entering Logging Method with Google Account");

    try {

      //TODO
      //await GigUtilities.kAnalytics.logLogin(loginMethod: GigAnalyticsConstants.google_login);
       credentials = await getAuthCredentials();

      if(credentials != null) {
        fbaUser.value = (await auth.signInWithCredential(credentials!)).user;
        authStatus.value = AuthStatus.loggedIn;
        signedInWith = SignedInWith.google;
      }


    } catch (e) {
      fbaUser.value = null;
      authStatus.value = AuthStatus.notLoggedIn;
      AppUtilities.logger.e(e.toString());

      AppUtilities.showSnackBar(
        title: MessageTranslationConstants.errorLoginGoogle.tr,
        message: MessageTranslationConstants.errorLoginGoogle.tr,
      );
    } finally {
      isButtonDisabled.value = false;
      if(credentials == null) {
        isLoading.value = false;
      }
    }

    update([AppPageIdConstants.login]);
  }

  //TODO To Verify Implementation
  Future<void> googleLogout() async {
    try {
      await _googleSignIn.signOut();
    } catch (e){
      AppUtilities.logger.e(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    AppUtilities.logger.d("Entering signOut method");
    try {
      await auth.signOut();
      await googleLogout();
      clear();
      Get.offAllNamed(AppRouteConstants.login);
    } catch (e) {
      AppUtilities.showSnackBar(
        title: MessageTranslationConstants.errorSigningOut.tr,
        message: e.toString(),
      );
    }

    AppUtilities.logger.i("signOut method finished");
    update([AppPageIdConstants.login]);
  }


  @override
  Future<void> sendEmailVerification(GlobalKey<ScaffoldState> scaffoldKey) {
    throw UnimplementedError();
  }


  void clear() {
    fbaUser.value = null;
    authStatus.value = AuthStatus.notDetermined;
    isButtonDisabled.value = false;
  }


  Future<fba.AuthCredential?> getAuthCredentials() async {


    try {
      switch(loginMethod) {
        case(LoginMethod.email):
          credentials = fba.EmailAuthProvider.credential(
              email: emailController.text.trim(),
              password: passwordController.text.trim()
          );
          break;
        case(LoginMethod.facebook):
          credentials = fba.FacebookAuthProvider.credential(_fbAccessToken);
          break;
        case(LoginMethod.apple):
          final rawNonce = generateNonce();
          final nonce = sha256ofString(rawNonce);

          AuthorizationCredentialAppleID appleCredential = await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: nonce, // Pass hashed nonce to Apple
          );

          AppUtilities.logger.d('Apple idToken: ${appleCredential.identityToken}');
          AppUtilities.logger.d('Apple nonce: $nonce');
          AppUtilities.logger.d('Apple rawNonce: $rawNonce');


          credentials = fba.OAuthProvider("apple.com").credential(
            idToken: appleCredential.identityToken,
            accessToken: appleCredential.authorizationCode,
            rawNonce: rawNonce, // Pass raw nonce to Firebase
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
      AppUtilities.logger.e(e.toString());
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
    authStatus.value = status;
    update([AppPageIdConstants.login]);
  }

  @override
  Widget selectRootPage({required StatelessWidget homePage, required int appLastStableBuild}) {

    Widget rootPage = const LoginPage();

    if (appInfo.value.lastStableBuild > appLastStableBuild) {
      rootPage = const PreviousVersionPage();
    } else if(sharedPreferenceController.firstTime) {
      rootPage = const OnGoing();
      sharedPreferenceController.updateFirstTIme(false);
    } else if(authStatus.value == AuthStatus.loggingIn) {
      rootPage = const SplashPage();
    } else if (authStatus.value == AuthStatus.loggedIn
      && (userController.user.id.isNotEmpty)
      && ((userController.user.profiles.isNotEmpty)
            && (userController.user.profiles.first.id.isNotEmpty)
        )
    ) {
      rootPage = homePage;
      isLoading.value = true;
    }

    return rootPage;
  }

  @override
  void setIsLoading(bool loading) {
    isLoading.value = loading;
    update([AppPageIdConstants.login]);
  }

  Future<void> verifyPhoneNumber(String phoneNumber) async {
    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (fba.PhoneAuthCredential credential) async {
        // Si el número es automáticamente verificado
        await auth.signInWithCredential(credential);
      },
      verificationFailed: (fba.FirebaseAuthException e) {
        // Manejar errores, por ejemplo si el formato del número es incorrecto
        if (e.code == 'invalid-phone-number') {
          AppUtilities.logger.d('El número de teléfono no es válido.');
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        phoneVerificationId = verificationId;
        // Guardar el `verificationId` y pedir al usuario que ingrese el código enviado por SMS
        AppUtilities.logger.d('Código de verificación enviado with verificationId $verificationId');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Manejar el tiempo de espera si no se recibe el código automáticamente
        AppUtilities.logger.d('Tiempo de espera para la verificación agotado');
      },
    );
  }

  Future<bool> validateSmsCode(String smsCode) async {
    fba.PhoneAuthCredential credential = fba.PhoneAuthProvider.credential(
      verificationId: phoneVerificationId,
      smsCode: smsCode,
    );

    try {
      // Autenticación con las credenciales del código SMS
      await auth.signInWithCredential(credential);
      isPhoneAuth = true;
      return true;
    } catch(e) {
      AppUtilities.logger.e(e.toString());
    }
    return false;
  }


}
