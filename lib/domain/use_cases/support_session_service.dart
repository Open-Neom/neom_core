/// Contract for end-of-support-session handling, kept in neom_core so the inbox
/// depends only on this interface. The implementation (neom_ia) reads the
/// conversation, asks the AI for what's still UNRESOLVED, and emails the user a
/// summary via the Google email service — the same one used by Email Marketing.
abstract class SupportSessionService {

  /// Called when the user leaves their own support room. If there's pending /
  /// unresolved context, generates an AI summary and emails it to [userEmail].
  /// No-op when everything was resolved or there was no real conversation.
  Future<void> onUserLeftSupport({
    required String userProfileId,
    required String userEmail,
  });
}
