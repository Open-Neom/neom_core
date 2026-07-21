import 'dart:typed_data';

abstract class FileSystemEntity {
  final String path;
  FileSystemEntity(this.path);
}

/// Stub FileStat class for web platform.
/// Mirrors the dart:io FileStat fields used across the codebase.
class FileStat {
  final DateTime modified;
  final int size;
  const FileStat(this.modified, this.size);
}

/// Stub File class for web platform.
/// Provides the same API surface as dart:io File.
class File extends FileSystemEntity {
  File(String path) : super(path);

  factory File.fromUri(Uri uri) => File(uri.path);

  Future<FileStat> stat() async =>
      FileStat(DateTime.fromMillisecondsSinceEpoch(0), 0);
  FileStat statSync() => FileStat(DateTime.fromMillisecondsSinceEpoch(0), 0);
  Directory get parent {
    final idx = path.lastIndexOf('/');
    return Directory(idx > 0 ? path.substring(0, idx) : '.');
  }

  bool existsSync() => false;
  int lengthSync() => 0;
  Uint8List readAsBytesSync() => Uint8List(0);
  Future<Uint8List> readAsBytes() async => Uint8List(0);
  Stream<List<int>> readAsBytesAsStream() => Stream.value(Uint8List(0));
  Future<File> create({bool recursive = false}) async => this;
  Future<File> writeAsBytes(List<int> bytes, {bool flush = false}) async => this;
  Future<File> writeAsString(String contents) async => this;
  Future<String> readAsString() async => '';
  Future<bool> exists() async => false;
  Future<int> length() async => 0;
  Future<void> delete({bool recursive = false}) async {}
  void deleteSync({bool recursive = false}) {}
  Future<File> copy(String newPath) async => File(newPath);
  Future<File> rename(String newPath) async => File(newPath);
  Stream<List<int>> openRead([int? start, int? end]) => Stream.value(Uint8List(0));
  Uri get uri => Uri.parse(path);

  @override
  String toString() => "File: '$path'";
}

/// Stub Directory class for web platform.
class Directory extends FileSystemEntity {
  Directory(String path) : super(path);

  Future<bool> exists() async => false;
  bool existsSync() => false;
  Future<Directory> create({bool recursive = false}) async => this;
  Stream<FileSystemEntity> list({bool recursive = false, bool followLinks = true}) => const Stream.empty();
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

/// Stub Process class for web.
class Process {
  static Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
  }) async {
    return ProcessResult(0, 0, '', '');
  }
}

/// Stub ProcessResult class for web.
class ProcessResult {
  final int pid;
  final int exitCode;
  final dynamic stdout;
  final dynamic stderr;

  ProcessResult(this.pid, this.exitCode, this.stdout, this.stderr);
}
