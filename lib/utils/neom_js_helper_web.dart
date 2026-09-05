import 'dart:js' as js;

/// Web implementation of NeomJsHelper using dart:js.
class NeomJsHelper {
  NeomJsHelper._();

  static void hideLoadingSplash() {
    try {
      js.context.callMethod('hideLoadingSplash');
    } catch (_) {
      // ignore
    }
  }

  /// Whether the Google Maps JavaScript API finished loading.
  ///
  /// `google_maps_flutter_web` needs the host page to include the Maps script;
  /// when it is missing, building a `GoogleMap` throws while reading
  /// `google.maps.MapTypeId` and replaces the page with an error box.
  static bool get isGoogleMapsAvailable {
    try {
      final google = js.context['google'];
      if (google == null) return false;
      final maps = google['maps'];
      return maps != null && maps['MapTypeId'] != null;
    } catch (_) {
      return false;
    }
  }
}
