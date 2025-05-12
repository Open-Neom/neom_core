

class AppGoogleUtilities {

  static const String fcmGoogleAPIUrl = "https://fcm.googleapis.com/fcm/send";

  /// Método o getter para obtener el URL de FCM usando dinámicamente el projectId
  // static String getFcmGoogleAPIUrl() {
  //   final projectId = AppFlavour.getFirebaseProjectId();
  //   return "https://fcm.googleapis.com/v1/projects/$projectId/messages:send";
  // }

  // static const String myProjectId = "myProjectId";
  // static const String fcmGoogleAPIUrl = "https://fcm.googleapis.com/v1/projects/$myProjectId/messages:send";

}
