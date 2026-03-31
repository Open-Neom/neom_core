import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../../utils/platform/core_io.dart';

abstract class ImageEditorService {

  Future<File?> cropImage(File file, {double ratioX = 1, double ratioY = 1});

  /// Web crop — takes raw bytes, shows crop UI, returns cropped bytes.
  Future<Uint8List?> cropImageBytes(BuildContext context, Uint8List bytes, {double aspectRatio = 1.0}) async => null;

}
