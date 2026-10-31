/// Safe diagnostics for an authenticated account that could not be loaded.
/// Values contain no addresses, document paths, tokens or SDK messages.
enum AccountLoadFailure {
  unknown,
  duplicateAccount,
  missingProfile,
  permissionDenied,
  unavailable,
  timeout,
  invalidData,
}

/// Account loading failed; this is never evidence that an account is new.
class AccountLoadException implements Exception {
  const AccountLoadException({this.reason = AccountLoadFailure.unknown});

  final AccountLoadFailure reason;

  @override
  String toString() => 'AccountLoadException: ${reason.name}';
}
