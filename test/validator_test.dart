// Tests for Validator (email / name / username / password).
// These are the gatekeepers of every signup/login/profile flow.
// A bug here rejects good users OR lets bad input reach Firestore.
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/utils/validator.dart';
import 'package:neom_core/utils/enums/validation_error.dart';
import 'package:neom_core/utils/constants/core_constants.dart';

void main() {
  group('Validator.validateEmail / isEmail', () {
    test('empty returns pleaseEnterEmail', () {
      expect(Validator.validateEmail(''),
          ValidationError.pleaseEnterEmail.name);
    });

    test('missing @ is invalid', () {
      expect(Validator.isEmail('userdomain.com'), isFalse);
      expect(Validator.validateEmail('userdomain.com'),
          ValidationError.invalidEmailFormat.name);
    });

    test('bare local part a@b is invalid (no TLD)', () {
      expect(Validator.isEmail('a@b'), isFalse);
    });

    test('a@b.c (single-char TLD) is invalid under current regex', () {
      // Current regex requires {2,} TLD. Documenting the constraint.
      expect(Validator.isEmail('a@b.c'), isFalse);
    });

    test('a@b.co (2-char TLD) is valid', () {
      expect(Validator.isEmail('a@b.co'), isTrue);
    });

    test('tagged address user+tag@domain.com is valid', () {
      expect(Validator.isEmail('user+tag@domain.com'), isTrue);
    });

    test('double @ is invalid', () {
      expect(Validator.isEmail('a@@b.com'), isFalse);
    });

    test('space inside local part is invalid', () {
      expect(Validator.isEmail('hello world@example.com'), isFalse);
    });

    test('trailing dot in domain is invalid', () {
      expect(Validator.isEmail('user@example.com.'), isFalse);
    });

    test('IP-literal [1.2.3.4] is accepted by regex', () {
      expect(Validator.isEmail('user@[1.2.3.4]'), isTrue);
    });

    test('valid email returns empty error', () {
      expect(Validator.validateEmail('jane.doe@example.com'), '');
    });

    test('quoted local part "a b"@example.com is valid', () {
      expect(Validator.isEmail('"a b"@example.com'), isTrue);
    });
  });

  group('Validator.validateName', () {
    test('empty returns pleaseEnterFullName', () {
      expect(Validator.validateName(''),
          ValidationError.pleaseEnterFullName.name);
    });

    test('contains a digit → invalidName (any digit rejected)', () {
      expect(Validator.validateName('Jane42'),
          ValidationError.invalidName.name);
    });

    test('single char name is tooShort', () {
      expect(Validator.validateName('A'),
          ValidationError.usernameTooShort.name);
    });

    test('name of exactly minimumLength is accepted', () {
      final name = 'A' * CoreConstants.nameMinimumLength;
      expect(Validator.validateName(name), '');
    });

    test('name of maximumLength is accepted', () {
      final name = 'A' * CoreConstants.usernameMaximumLength;
      expect(Validator.validateName(name), '');
    });

    test('name over maximum returns tooLong', () {
      final name = 'A' * (CoreConstants.usernameMaximumLength + 1);
      expect(Validator.validateName(name),
          ValidationError.usernameTooLong.name);
    });
  });

  group('Validator.validateUsername', () {
    test('empty → pleaseEnterUsername', () {
      expect(Validator.validateUsername(''),
          ValidationError.pleaseEnterUsername.name);
    });

    test('purely numeric → invalidUsername', () {
      expect(Validator.validateUsername('12345'),
          ValidationError.invalidUsername.name);
    });

    test('alphanumeric with at least one letter is valid', () {
      // "abc1" has 4 chars (minimum is 4) and mixes letter+digit.
      expect(Validator.validateUsername('abc1'), '');
    });

    test('short alphanumeric → tooShort', () {
      expect(Validator.validateUsername('ab1'),
          ValidationError.usernameTooShort.name);
    });
  });

  group('Validator.validatePassword', () {
    test('empty password → pleaseEnterPassword', () {
      expect(Validator.validatePassword('', ''),
          ValidationError.pleaseEnterPassword.name);
    });

    test('too short password', () {
      expect(Validator.validatePassword('abc', 'abc'),
          ValidationError.passwordTooShort.name);
    });

    test('too long password', () {
      final long = 'a' * (CoreConstants.passwordMaximumLength + 1);
      expect(Validator.validatePassword(long, long),
          ValidationError.passwordTooLong.name);
    });

    test('mismatched confirmation', () {
      expect(Validator.validatePassword('abcdefgh', 'abcdefgX'),
          ValidationError.passwordsNotMatch.name);
    });

    test('valid matching password', () {
      expect(Validator.validatePassword('abcdefgh', 'abcdefgh'), '');
    });

    test('boundary: exactly min length', () {
      final p = 'a' * CoreConstants.passwordMinimumLength;
      expect(Validator.validatePassword(p, p), '');
    });

    test('boundary: exactly max length', () {
      final p = 'a' * CoreConstants.passwordMaximumLength;
      expect(Validator.validatePassword(p, p), '');
    });
  });
}
