import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:vyrax_cli/src/init_command.dart';
import 'package:vyrax_cli/vyrax_cli.dart';

void main() {
  test('help message contains usage', () {
    expect(buildHelpMessage(), contains('Usage: vyrax <command> [arguments]'));
    expect(buildHelpMessage(), contains('analyze'));
    expect(buildHelpMessage(), contains('init'));
    expect(buildHelpMessage(), contains('--version, -v'));
    expect(buildHelpMessage(), contains('--no-report'));
  });

  test('version message contains current cli version', () {
    expect(buildVersionMessage(), 'vyrax_cli 0.2.1');
  });

  test('detects Riverpod state management', () {
    final findings = inspectProject(
      _context(deps: {'flutter', 'flutter_riverpod'}),
    );
    expect(findings.stateManagement, 'riverpod');
  });

  test('detects dependency injection package', () {
    final findings = inspectProject(_context(deps: {'flutter', 'get_it'}));
    expect(findings.dependencyInjection, 'get_it');
  });

  test('detects networking package', () {
    final findings = inspectProject(_context(deps: {'flutter', 'dio'}));
    expect(findings.networking, 'dio');
  });

  test('falls back to Navigator routing', () {
    final findings = inspectProject(_context(deps: {'flutter'}));
    expect(findings.routing, 'navigator');
  });

  test('detects serialization package', () {
    final findings = inspectProject(
      _context(deps: {'flutter', 'json_serializable'}),
    );
    expect(findings.serialization, 'json_serializable');
  });

  test('detects clean architecture with high confidence', () {
    final temp = Directory.systemTemp.createTempSync('vyrax-clean-');
    try {
      Directory('${temp.path}/lib/domain').createSync(recursive: true);
      Directory('${temp.path}/lib/data').createSync(recursive: true);
      Directory('${temp.path}/lib/presentation').createSync(recursive: true);

      final findings = inspectProject(
        _context(path: temp.path, deps: {'flutter'}),
      );

      expect(findings.architecture, 'clean');
      expect(findings.architectureConfidence, 'high');
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  test('detects quality tools from dependencies and melos file', () {
    final temp = Directory.systemTemp.createTempSync('vyrax-quality-');
    try {
      File('${temp.path}/melos.yaml').writeAsStringSync('name: workspace');
      final findings = inspectProject(
        _context(
          path: temp.path,
          deps: {'flutter', 'build_runner'},
          devDeps: {'flutter_lints', 'custom_lint', 'very_good_analysis'},
        ),
      );

      expect(
        findings.qualityTools,
        containsAll(<String>[
          'flutter_lints',
          'custom_lint',
          'build_runner',
          'very_good_analysis',
          'melos',
        ]),
      );
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  test('parseProjectContext identifies non-flutter project', () {
    final temp = Directory.systemTemp.createTempSync('vyrax-pubspec-');
    try {
      File('${temp.path}/pubspec.yaml').writeAsStringSync('''
name: plain_dart
environment:
  sdk: ^3.9.0
dependencies:
  collection: ^1.18.0
''');

      final context = parseProjectContext(temp.path);
      expect(context.isFlutterProject, isFalse);
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  test(
    'init cancels and does not create vyrax.yaml when user answers no',
    () async {
      final temp = Directory.systemTemp.createTempSync('vyrax-init-cancel-');
      try {
        _writeFlutterPubspec(temp.path);

        final result = await _runCli([
          'init',
          '--project',
          temp.path,
        ], stdinText: 'n\n');

        expect(result.exitCode, 0);
        expect(result.stdoutOutput, contains('Generate vyrax.yaml?'));
        expect(result.stdoutOutput, contains('Cancelled.'));
        expect(File('${temp.path}/vyrax.yaml').existsSync(), isFalse);
      } finally {
        temp.deleteSync(recursive: true);
      }
    },
  );

  test('init creates vyrax.yaml when user confirms', () async {
    final temp = Directory.systemTemp.createTempSync('vyrax-init-generate-');
    try {
      _writeFlutterPubspec(temp.path);

      final result = await _runCli([
        'init',
        '--project',
        temp.path,
      ], stdinText: 'y\n');

      final generated = File('${temp.path}/vyrax.yaml');
      expect(result.exitCode, 0);
      expect(result.stdoutOutput, contains('Created vyrax.yaml at'));
      expect(result.stdoutOutput, contains('Default rules enabled: 23'));
      expect(generated.existsSync(), isTrue);
      expect(generated.readAsStringSync(), contains('project:'));
      expect(generated.readAsStringSync(), contains('rules:'));
      expect(
        generated.readAsStringSync(),
        contains('broad_reactive_rebuild_scope:'),
      );
      expect(generated.readAsStringSync(), contains('solid_opportunity:'));
      expect(generated.readAsStringSync(), contains('widget_tree_complexity:'));
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  test(
    'init does not overwrite existing vyrax.yaml when user answers no',
    () async {
      final temp = Directory.systemTemp.createTempSync('vyrax-init-overwrite-');
      try {
        _writeFlutterPubspec(temp.path);
        final existing = File('${temp.path}/vyrax.yaml');
        const sentinel = 'sentinel: keep_this';
        existing.writeAsStringSync(sentinel);

        final result = await _runCli([
          'init',
          '--project',
          temp.path,
        ], stdinText: 'n\n');

        expect(result.exitCode, 0);
        expect(result.stdoutOutput, contains('vyrax.yaml already exists.'));
        expect(existing.readAsStringSync(), sentinel);
      } finally {
        temp.deleteSync(recursive: true);
      }
    },
  );

  test('init overwrites existing vyrax.yaml when user answers yes', () async {
    final temp = Directory.systemTemp.createTempSync(
      'vyrax-init-overwrite-yes-',
    );
    try {
      _writeFlutterPubspec(temp.path);
      final existing = File('${temp.path}/vyrax.yaml');
      const sentinel = 'sentinel: replace_this';
      existing.writeAsStringSync(sentinel);

      final result = await _runCli([
        'init',
        '--project',
        temp.path,
      ], stdinText: 'y\n');

      final updated = existing.readAsStringSync();
      expect(result.exitCode, 0);
      expect(result.stdoutOutput, contains('vyrax.yaml already exists.'));
      expect(result.stdoutOutput, contains('Created vyrax.yaml at'));
      expect(updated, isNot(sentinel));
      expect(updated, contains('project:'));
      expect(updated, contains('rules:'));
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  test('init returns 1 for non-flutter project', () async {
    final temp = Directory.systemTemp.createTempSync('vyrax-init-non-flutter-');
    try {
      File('${temp.path}/pubspec.yaml').writeAsStringSync('''
name: plain_dart
environment:
  sdk: ^3.9.0
dependencies:
  collection: ^1.18.0
''');

      final result = await _runCli([
        'init',
        '--project',
        temp.path,
      ], stdinText: 'y\n');

      expect(result.exitCode, 1);
      expect(
        result.stderrOutput,
        contains('This directory does not appear to be a Flutter project.'),
      );
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  test('analyze writes a txt report by default', () async {
    final temp = Directory.systemTemp.createTempSync('vyrax-analyze-report-');
    try {
      _writeFlutterPubspec(temp.path);
      Directory('${temp.path}/lib').createSync(recursive: true);
      File('${temp.path}/lib/main.dart').writeAsStringSync('''
import 'package:flutter/widgets.dart';

void main() {
  runApp(const SizedBox.shrink());
}
''');

      final result = await _runCli([
        'analyze',
        '--project',
        temp.path,
      ], stdinText: '');

      expect(result.exitCode, inInclusiveRange(0, 2));
      final reportsDir = Directory('${temp.path}/vyrax-reports');
      expect(reportsDir.existsSync(), isTrue);
      final reportFiles = reportsDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.txt'))
          .toList(growable: false);
      expect(reportFiles, isNotEmpty);
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  test('analyze can disable report generation from config', () async {
    final temp = Directory.systemTemp.createTempSync(
      'vyrax-analyze-no-report-',
    );
    try {
      _writeFlutterPubspec(temp.path);
      Directory('${temp.path}/lib').createSync(recursive: true);
      File('${temp.path}/lib/main.dart').writeAsStringSync('''
import 'package:flutter/widgets.dart';

void main() {
  runApp(const SizedBox.shrink());
}
''');
      File('${temp.path}/vyrax.yaml').writeAsStringSync('''
output:
  format: text
  report:
    enabled: false
''');

      final result = await _runCli([
        'analyze',
        '--project',
        temp.path,
      ], stdinText: '');

      expect(result.exitCode, inInclusiveRange(0, 2));
      final reportsDir = Directory('${temp.path}/vyrax-reports');
      expect(reportsDir.existsSync(), isFalse);
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  test(
    'analyze --changed returns 1 when project is not a Git repository',
    () async {
      final temp = Directory.systemTemp.createTempSync(
        'vyrax-analyze-changed-no-git-',
      );
      try {
        _writeFlutterPubspec(temp.path);
        Directory('${temp.path}/lib').createSync(recursive: true);
        File('${temp.path}/lib/main.dart').writeAsStringSync('void main() {}');

        final result = await _runCli([
          'analyze',
          '--project',
          temp.path,
          '--changed',
        ], stdinText: '');

        expect(result.exitCode, 1);
        expect(result.stderrOutput, contains('No Git repository found.'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    },
  );

  test(
    'analyze --changed returns 0 when no modified Dart files exist',
    () async {
      final temp = Directory.systemTemp.createTempSync(
        'vyrax-analyze-changed-empty-',
      );
      try {
        _writeFlutterPubspec(temp.path);
        Directory('${temp.path}/lib').createSync(recursive: true);
        File('${temp.path}/lib/main.dart').writeAsStringSync('void main() {}');
        _initGitRepo(temp.path);
        _commitAll(temp.path, message: 'baseline');

        final result = await _runCli([
          'analyze',
          '--project',
          temp.path,
          '--changed',
        ], stdinText: '');

        expect(result.exitCode, 0);
        expect(result.stderrOutput, contains('No modified Dart files found.'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    },
  );

  test('analyze --staged returns 0 when no staged Dart files exist', () async {
    final temp = Directory.systemTemp.createTempSync(
      'vyrax-analyze-staged-empty-',
    );
    try {
      _writeFlutterPubspec(temp.path);
      Directory('${temp.path}/lib').createSync(recursive: true);
      File('${temp.path}/lib/main.dart').writeAsStringSync('void main() {}');
      _initGitRepo(temp.path);

      final result = await _runCli([
        'analyze',
        '--project',
        temp.path,
        '--staged',
      ], stdinText: '');

      expect(result.exitCode, 0);
      expect(result.stderrOutput, contains('No staged Dart files found.'));
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  test('analyze --against returns 1 when branch does not exist', () async {
    final temp = Directory.systemTemp.createTempSync(
      'vyrax-analyze-against-missing-',
    );
    try {
      _writeFlutterPubspec(temp.path);
      Directory('${temp.path}/lib').createSync(recursive: true);
      File('${temp.path}/lib/main.dart').writeAsStringSync('void main() {}');
      _initGitRepo(temp.path);

      final result = await _runCli([
        'analyze',
        '--project',
        temp.path,
        '--against',
        'develop',
      ], stdinText: '');

      expect(result.exitCode, 1);
      expect(result.stderrOutput, contains('Branch "develop" not found.'));
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  test('analyze supports directory scope input', () async {
    final temp = Directory.systemTemp.createTempSync(
      'vyrax-analyze-directory-',
    );
    try {
      _writeFlutterPubspec(temp.path);
      Directory('${temp.path}/lib/features/auth').createSync(recursive: true);
      File(
        '${temp.path}/lib/features/auth/login_page.dart',
      ).writeAsStringSync('void main() {}');

      final result = await _runCli([
        'analyze',
        '--project',
        temp.path,
        'lib/features/auth',
      ], stdinText: '');

      expect(result.exitCode, inInclusiveRange(0, 2));
      expect(result.stderrOutput, contains('scope directory'));
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  test('analyze supports file scope input', () async {
    final temp = Directory.systemTemp.createTempSync('vyrax-analyze-file-');
    try {
      _writeFlutterPubspec(temp.path);
      Directory('${temp.path}/lib/features/auth').createSync(recursive: true);
      File(
        '${temp.path}/lib/features/auth/login_page.dart',
      ).writeAsStringSync('void main() {}');

      final result = await _runCli([
        'analyze',
        '--project',
        temp.path,
        'lib/features/auth/login_page.dart',
      ], stdinText: '');

      expect(result.exitCode, inInclusiveRange(0, 2));
      expect(result.stderrOutput, contains('scope file'));
    } finally {
      temp.deleteSync(recursive: true);
    }
  });
}

ProjectContext _context({
  String path = '/tmp/project',
  Set<String> deps = const {'flutter'},
  Set<String> devDeps = const {},
}) => ProjectContext(
  projectPath: path,
  name: 'sample_app',
  flutterSdkConstraint: '^3.35.0',
  dartSdkConstraint: '^3.9.0',
  dependencyNames: deps,
  devDependencyNames: devDeps,
  isFlutterProject: true,
);

void _writeFlutterPubspec(String path) {
  File('$path/pubspec.yaml').writeAsStringSync('''
name: sample_app
environment:
  sdk: ^3.9.0
  flutter: ">=3.35.0"
dependencies:
  flutter:
    sdk: flutter
''');
}

Future<_CliRunResult> _runCli(
  List<String> args, {
  required String stdinText,
}) async {
  final process = await Process.start(Platform.resolvedExecutable, [
    'run',
    'bin/vyrax_cli.dart',
    ...args,
  ], workingDirectory: Directory.current.path);

  process.stdin.write(stdinText);
  await process.stdin.close();

  final stdoutFuture = process.stdout.transform(utf8.decoder).join();
  final stderrFuture = process.stderr.transform(utf8.decoder).join();
  final exitCode = await process.exitCode;

  return _CliRunResult(
    exitCode: exitCode,
    stdoutOutput: await stdoutFuture,
    stderrOutput: await stderrFuture,
  );
}

void _initGitRepo(String path) {
  final init = Process.runSync('git', ['init'], workingDirectory: path);
  if (init.exitCode != 0) {
    throw StateError('git init failed: ${init.stderr}');
  }

  Process.runSync('git', [
    'config',
    'user.email',
    'test@vyrax.dev',
  ], workingDirectory: path);
  Process.runSync('git', [
    'config',
    'user.name',
    'Vyrax Tests',
  ], workingDirectory: path);
}

void _commitAll(String path, {required String message}) {
  final add = Process.runSync('git', ['add', '.'], workingDirectory: path);
  if (add.exitCode != 0) {
    throw StateError('git add failed: ${add.stderr}');
  }

  final commit = Process.runSync('git', [
    'commit',
    '-m',
    message,
  ], workingDirectory: path);
  if (commit.exitCode != 0) {
    throw StateError('git commit failed: ${commit.stderr}');
  }
}

final class _CliRunResult {
  const _CliRunResult({
    required this.exitCode,
    required this.stdoutOutput,
    required this.stderrOutput,
  });

  final int exitCode;
  final String stdoutOutput;
  final String stderrOutput;
}
