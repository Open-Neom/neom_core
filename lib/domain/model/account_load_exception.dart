/// Account loading failed; this is never evidence that an account is new.
/// Keep this exception free of email addresses, document paths and SDK details.
class AccountLoadException implements Exception {
  const AccountLoadException();

  @override
  String toString() => 'AccountLoadException: account could not be loaded';
}
