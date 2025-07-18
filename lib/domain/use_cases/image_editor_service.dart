import 'dart:io';

abstract class ImageEditorService {

  Future<File?> cropImage(File file, {double ratioX = 1, double ratioY = 1});

}
