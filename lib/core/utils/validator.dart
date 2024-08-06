
import 'constants/app_constants.dart';
import 'constants/message_translation_constants.dart';

class Validator {

  static String validateEmail(String email) {
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = RegExp(pattern);
    if(email.isEmpty) {
      return MessageTranslationConstants.pleaseEnterEmail;
    } else if (!regex.hasMatch(email)) {
      return MessageTranslationConstants.invalidEmailFormat;
    }

    return "";
  }

  static bool isEmail(String email) {
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';

    return RegExp(pattern).hasMatch(email);
  }

  static String validateName(String name) {
    if (name.isEmpty) {
      return MessageTranslationConstants.pleaseEnterFullName;
    } else if (_isNumeric(name)) {
      return MessageTranslationConstants.invalidName;
    } else if (name.length < AppConstants.nameMinimumLength) {
      return MessageTranslationConstants.usernameAtLeast;
    } else if (name.length > AppConstants.usernameMaximumLength) {
      return MessageTranslationConstants.usernameCantExceed;
    }

    return "";
  }


  static String validateUsername(String username) {
    if (username.isEmpty) {
      return MessageTranslationConstants.pleaseEnterUsername;
    } else if (_isNumericOnly(username)) {
      return MessageTranslationConstants.invalidUsername;
    } else if (username.length < AppConstants.usernameMinimumLength) {
      return MessageTranslationConstants.usernameAtLeast;
    } else if (username.length > AppConstants.usernameMaximumLength) {
      return MessageTranslationConstants.usernameCantExceed;
    }

    return "";
  }


  static bool _isNumericOnly(String s) {

    int count = 0;
    for (int i = 0; i < s.length; i++) {
      if (double.tryParse(s[i]) != null) count++;
    }

    return (s.length == count)
        ? true : false;
  }


  static bool _isNumeric(String s) {
    for (int i = 0; i < s.length; i++) {
      if (double.tryParse(s[i]) != null) {
        return true;
      }
    }
    return false;
  }


  static String validatePassword(String password, String confirmation) {
    if (password.isEmpty) {
      return MessageTranslationConstants.pleaseEnterPassword;
    } else if (password.length < 6) {
      return MessageTranslationConstants.passwordAtLeast;
    } else if (password.length > 15) {
      return MessageTranslationConstants.passwordCantExceed;
    } else if (password != confirmation) {
      return MessageTranslationConstants.passwordConfirmNotMatch;
    }

    return "";
  }

}
