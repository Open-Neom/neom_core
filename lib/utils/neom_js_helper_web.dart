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
}
