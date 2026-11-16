import 'dart:js_interop';
import 'dart:js_interop_unsafe';

extension type _JSOrigin._(JSObject _) implements JSObject {
  external bool get opaque;
  external bool isSameSite(_JSOrigin other);
}

extension type _JSOriginConstructor._(JSObject _) implements JSObject {
  external _JSOrigin from(JSAny candidate);
}

extension type _JSUrl._(JSObject _) implements JSObject {
  external factory _JSUrl(String url);
  external String get origin;
  external String get protocol;
  external String get hostname;
}

/// Web implementation of NeomJsHelper using dart:js_interop (Dart2Wasm-ready).
class NeomJsHelper {
  NeomJsHelper._();

  /// Schemeful same-site check backed by the browser `Origin` API
  /// (`Origin.from()` + `isSameSite()`) and Public Suffix List, with a
  /// `new URL()` fallback that rejects `"null"` opaque origins and scheme downgrades.
  static bool isSameSiteWebUrl(String candidateUrl, String trustedOriginUrl) {
    try {
      if (globalContext.has('Origin')) {
        final originCtorVal = globalContext['Origin'];
        if (originCtorVal != null && originCtorVal.isA<JSObject>()) {
          final ctor = _JSOriginConstructor._(originCtorVal as JSObject);
          final candidateOrigin = ctor.from(candidateUrl.toJS);
          final trustedOrigin = ctor.from(trustedOriginUrl.toJS);
          return !candidateOrigin.opaque &&
              !trustedOrigin.opaque &&
              candidateOrigin.isSameSite(trustedOrigin);
        }
      }
      final candidateParsed = _JSUrl(candidateUrl);
      final trustedParsed = _JSUrl(trustedOriginUrl);
      final candOrigin = candidateParsed.origin;
      final trustOrigin = trustedParsed.origin;
      if (candOrigin.isEmpty ||
          candOrigin == 'null' ||
          trustOrigin.isEmpty ||
          trustOrigin == 'null') {
        return false;
      }
      if (candidateParsed.protocol != trustedParsed.protocol) return false;
      final candHost = candidateParsed.hostname.toLowerCase();
      final trustHost = trustedParsed.hostname.toLowerCase();
      return candHost.isNotEmpty &&
          trustHost.isNotEmpty &&
          (candHost == trustHost || candHost.endsWith('.$trustHost'));
    } catch (_) {
      return false;
    }
  }

  static void hideLoadingSplash() {
    try {
      if (globalContext.has('hideLoadingSplash')) {
        globalContext.callMethod<JSAny?>('hideLoadingSplash'.toJS);
      }
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
      final google = globalContext['google'];
      if (google == null || !google.isA<JSObject>()) return false;
      final maps = (google as JSObject)['maps'];
      if (maps == null || !maps.isA<JSObject>()) return false;
      final mapTypeId = (maps as JSObject)['MapTypeId'];
      return mapTypeId != null && !mapTypeId.isUndefinedOrNull;
    } catch (_) {
      return false;
    }
  }
}
