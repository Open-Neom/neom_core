/// Optional lifecycle contract for services that load an application account.
///
/// Authentication coordinators call this when the session changes or a login
/// attempt is abandoned. It invalidates local publication of pending results;
/// it does not cancel SDK requests or change the Firebase session.
abstract interface class AccountLoadLifecycle {
  void invalidateAccountLoad();
}
