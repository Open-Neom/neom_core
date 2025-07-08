
import 'constants/core_constants.dart';
import 'enums/validation_error.dart';

class Validator {

  static String validateEmail(String email) {
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = RegExp(pattern);
    if(email.isEmpty) {
      return ValidationError.pleaseEnterEmail.name;
    } else if (!regex.hasMatch(email)) {
      return ValidationError.invalidEmailFormat.name;
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
      return ValidationError.pleaseEnterFullName.name;
    } else if (_isNumeric(name)) {
      return ValidationError.invalidName.name;
    } else if (name.length < CoreConstants.nameMinimumLength) {
      return ValidationError.usernameTooShort.name;
    } else if (name.length > CoreConstants.usernameMaximumLength) {
      return ValidationError.usernameTooLong.name;
    }

    return "";
  }


  static String validateUsername(String username) {
    if (username.isEmpty) {
      return ValidationError.pleaseEnterUsername.name;
    } else if (_isNumericOnly(username)) {
      return ValidationError.invalidUsername.name;
    } else if (username.length < CoreConstants.usernameMinimumLength) {
      return ValidationError.usernameTooShort.name;
    } else if (username.length > CoreConstants.usernameMaximumLength) {
      return ValidationError.usernameTooLong.name;
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
      return ValidationError.pleaseEnterPassword.name;
    } else if (password.length < CoreConstants.passwordMinimumLength) {
      return ValidationError.passwordTooShort.name;
    } else if (password.length > CoreConstants.passwordMaximumLength) {
      return ValidationError.passwordTooLong.name;
    } else if (password != confirmation) {
      return ValidationError.passwordsNotMatch.name;
    }

    return "";
  }

}
