
import 'constants/core_constants.dart';
import 'enums/validation_error.dart';

class Validator {
  static const int _maxEmailLength = 254;
  static const int _maxLocalPartLength = 64;
  static const int _maxDomainLength = 253;
  static const int _maxDomainLabelLength = 63;

  static String validateEmail(String email) {
    if (email.isEmpty) {
      return ValidationError.pleaseEnterEmail.name;
    } else if (!isEmail(email)) {
      return ValidationError.invalidEmailFormat.name;
    }

    return "";
  }

  /// Linear-time O(N) RFC 5321/5322 email validation without nested regex
  /// quantifiers (immune to catastrophic backtracking / ReDoS).
  static bool isEmail(String email) {
    if (email.length < 3 || email.length > _maxEmailLength) {
      return false;
    }
    if (_containsControlChars(email)) {
      return false;
    }

    final int atIndex = email.lastIndexOf('@');
    if (atIndex <= 0 || atIndex >= email.length - 1) {
      return false;
    }

    final String local = email.substring(0, atIndex);
    final String domain = email.substring(atIndex + 1);
    if (local.length > _maxLocalPartLength || domain.length > _maxDomainLength) {
      return false;
    }

    return _isValidEmailLocalPart(local) && _isValidEmailDomain(domain);
  }

  static bool _isValidEmailLocalPart(String local) {
    if (local.isEmpty) return false;

    if (local.startsWith('"') && local.endsWith('"')) {
      if (local.length < 3) return false;
      for (int i = 1; i < local.length - 1; i++) {
        final int unit = local.codeUnitAt(i);
        if (unit < 0x20 || unit == 0x7F) return false;
        if (unit == 0x5C /* \ */) {
          i++;
          if (i >= local.length - 1) return false;
          continue;
        }
        if (unit == 0x22 /* " */) return false;
      }
      return true;
    }

    if (local.startsWith('.') || local.endsWith('.')) {
      return false;
    }

    bool previousWasDot = false;
    for (int i = 0; i < local.length; i++) {
      final int unit = local.codeUnitAt(i);
      if (unit == 0x2E /* . */) {
        if (previousWasDot) return false;
        previousWasDot = true;
        continue;
      }
      previousWasDot = false;
      if (_isForbiddenUnquotedLocalChar(unit)) {
        return false;
      }
    }
    return true;
  }

  static bool _isForbiddenUnquotedLocalChar(int unit) {
    if (unit <= 0x20 || unit == 0x7F) return true;
    switch (unit) {
      case 0x22: // "
      case 0x28: // (
      case 0x29: // )
      case 0x2C: // ,
      case 0x3A: // :
      case 0x3B: // ;
      case 0x3C: // <
      case 0x3E: // >
      case 0x40: // @
      case 0x5B: // [
      case 0x5C: // \
      case 0x5D: // ]
        return true;
      default:
        return false;
    }
  }

  static bool _isValidEmailDomain(String domain) {
    if (domain.isEmpty) return false;

    if (domain.startsWith('[') && domain.endsWith(']')) {
      final String ipv4 = domain.substring(1, domain.length - 1);
      final List<String> octets = ipv4.split('.');
      if (octets.length != 4) return false;
      for (final String octet in octets) {
        if (octet.isEmpty || octet.length > 3) return false;
        final int? val = int.tryParse(octet);
        if (val == null || val < 0 || val > 255) return false;
      }
      return true;
    }

    if (domain.startsWith('.') || domain.endsWith('.')) {
      return false;
    }

    final List<String> labels = domain.split('.');
    if (labels.length < 2) return false;

    for (int i = 0; i < labels.length; i++) {
      final String label = labels[i];
      if (label.isEmpty || label.length > _maxDomainLabelLength) {
        return false;
      }
      if (label.startsWith('-') || label.endsWith('-')) {
        return false;
      }
      final bool isTld = i == labels.length - 1;
      if (isTld && label.length < 2) {
        return false;
      }
      for (int j = 0; j < label.length; j++) {
        final int unit = label.codeUnitAt(j);
        final bool isAlpha =
            (unit >= 0x41 && unit <= 0x5A) || (unit >= 0x61 && unit <= 0x7A);
        final bool isDigit = unit >= 0x30 && unit <= 0x39;
        final bool isHyphen = unit == 0x2D;
        if (isTld) {
          if (!isAlpha) return false;
        } else {
          if (!isAlpha && !isDigit && !isHyphen) return false;
        }
      }
    }
    return true;
  }

  static bool _containsControlChars(String s) {
    for (int i = 0; i < s.length; i++) {
      final int unit = s.codeUnitAt(i);
      if (unit < 0x20 || unit == 0x7F) return true;
    }
    return false;
  }

  static String validateName(String name) {
    if (name.isEmpty) {
      return ValidationError.pleaseEnterFullName.name;
    } else if (_containsControlChars(name) || _isNumeric(name)) {
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
    } else if (_containsControlChars(username) || _isNumericOnly(username)) {
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
