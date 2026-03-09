import 'dart:io';

import 'package:flutter/services.dart';

/// Exits the app on mobile platforms.
void coreExitApp() {
  if (Platform.isAndroid) {
    SystemNavigator.pop();
  } else if (Platform.isIOS) {
    exit(0);
  }
}
