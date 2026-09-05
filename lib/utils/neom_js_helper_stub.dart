/// Stub implementation of NeomJsHelper to satisfy native compilers.
class NeomJsHelper {
  NeomJsHelper._();

  static void hideLoadingSplash() {
    // No-op on native platforms
  }

  /// Whether the Google Maps JavaScript API is present.
  ///
  /// Native builds embed the Maps SDK, so this is always true there. On web it
  /// depends on the host page loading the Maps script; without it, rendering a
  /// `GoogleMap` throws `Cannot read properties of undefined (reading
  /// 'MapTypeId')` and takes the whole page down.
  static bool get isGoogleMapsAvailable => true;
}
