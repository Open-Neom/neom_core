import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/utils/platform/core_io.dart' as core_io;
import 'package:neom_core/utils/platform/core_io_stub.dart' as core_io_stub;

void main() {
  group('Core IO Platform Separation Tests', () {
    test('Verify Process and ProcessResult stub behavior on Web (core_io_stub)', () async {
      // Create a stub ProcessResult directly to test constructor and field values
      final stubResult = core_io_stub.ProcessResult(12345, 0, 'stdout_output', 'stderr_output');
      expect(stubResult.pid, equals(12345));
      expect(stubResult.exitCode, equals(0));
      expect(stubResult.stdout, equals('stdout_output'));
      expect(stubResult.stderr, equals('stderr_output'));

      // Verify that calling Process.run on the stub resolves instantly with code 0 and empty output
      final runResult = await core_io_stub.Process.run('ffmpeg', ['-version']);
      expect(runResult.pid, equals(0));
      expect(runResult.exitCode, equals(0));
      expect(runResult.stdout, equals(''));
      expect(runResult.stderr, equals(''));
    });

    test('Verify active Platform wrapper exports Process on VM environment', () async {
      // In VM tests, core_io resolves to core_io_io, which re-exports dart:io's Process.
      // Let's verify that we can execute Process.run through the wrapper in tests.
      // We will try running a simple process command (e.g. echo) that exists on Unix-like OS (Mac/Linux).
      try {
        final result = await core_io.Process.run('echo', ['hello']);
        expect(result.exitCode, equals(0));
        expect(result.stdout.toString().trim(), equals('hello'));
      } catch (e) {
        // If system doesn't have echo command (unlikely on macOS), we at least assert it's a compile-safe function
        fail('Failed to run echo process: $e');
      }
    });
  });
}
