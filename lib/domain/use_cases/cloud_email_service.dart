/// Abstract interface for cloud email operations.
///
/// Implemented by neom_cloud's GoogleGmailController.
/// Consumed by neom_ia (SAIA), neom_erp, etc. via Sint DI.
abstract class CloudEmailService {
  bool get isAuthenticated;

  Future<String> createDraft({
    required String to,
    required String subject,
    required String body,
  });

  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String body,
  });
}
