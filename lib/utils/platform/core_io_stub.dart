import 'dart:typed_data';

/// Stub File class for web platform.
/// Provides the same API surface as dart:io File.
class File {
  final String path;

  File(this.path);

  factory File.fromUri(Uri uri) => File(uri.path);

  bool existsSync() => false;
  int lengthSync() => 0;
  Uint8List readAsBytesSync() => Uint8List(0);
  Future<Uint8List> readAsBytes() async => Uint8List(0);
  Stream<List<int>> readAsBytes_asStream() => Stream.value(Uint8List(0));
  Future<File> create({bool recursive = false}) async => this;
  Future<File> writeAsBytes(List<int> bytes, {bool flush = false}) async => this;
  Future<File> writeAsString(String contents) async => this;
  Future<String> readAsString() async => '';
  Future<bool> exists() async => false;
  Future<int> length() async => 0;
  Future<void> delete({bool recursive = false}) async {}
  Uri get uri => Uri.parse(path);
}

/// Stub Directory class for web platform.
class Directory {
  final String path;

  Directory(this.path);

  Future<bool> exists() async => false;
  bool existsSync() => false;
  Future<Directory> create({bool recursive = false}) async => this;
}

/// Stub Platform class for web platform.
class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isMacOS => false;
  static bool get isWindows => false;
  static bool get isLinux => false;
  static bool get isFuchsia => false;
  static String get operatingSystemVersion => '';
  static String get version => '';
}

/// No-op exit function for web.
void exit(int code) {}
