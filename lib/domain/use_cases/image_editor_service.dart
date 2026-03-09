import '../../utils/platform/core_io.dart';

abstract class ImageEditorService {

  Future<File?> cropImage(File file, {double ratioX = 1, double ratioY = 1});

}
