/// CLI utilities for rendering command help and executing commands.
library;

import 'dart:convert';
import 'dart:io';

import 'package:vyrax_cli/src/init_command.dart';
import 'package:vyrax_core/vyrax_core.dart';
import 'package:vyrax_engine/vyrax_engine.dart';
import 'package:vyrax_rules/vyrax_rules.dart';
import 'package:yaml/yaml.dart';

/// Current CLI version.
const String cliVersion = '0.2.1';

/// Returns the current help output for the Vyrax CLI.
String buildHelpMessage() {
  final buffer = StringBuffer()
    ..writeln('Vyrax - Flutter Architecture & Performance Analyzer')
    ..writeln('')
    ..writeln('Usage: vyrax <command> [arguments]')
    ..writeln('')
    ..writeln('Current support:')
    ..writeln('  init          Inspect project and generate vyrax.yaml')
    ..writeln('                Options: --project <path>')
    ..writeln('  analyze       Analyze a Flutter project')
    ..writeln(
      '                Options: --project <path>, --format <text|json>, --changed, --staged, --against <branch>, --no-report, --report-path <path>, [directory|file]',
    )
    ..writeln('  version       Show CLI version')
    ..writeln('  --help, -h    Show this help message')
    ..writeln('  --version, -v Show CLI version')
    ..writeln('')
    ..writeln('Planned commands:')
    ..writeln('  init, doctor, score, explain, fix');

  return buffer.toString();
}

/// Returns a human-readable version string for the CLI.
String buildVersionMessage() => 'vyrax_cli $cliVersion';

/// Executes the `vyrax init` command.
Future<int> runInitCommand(List<String> arguments) async {
  final projectPath = _resolveProjectPath(arguments);
  ProjectContext context;
  try {
    context = parseProjectContext(projectPath);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    return 3;
  }

  if (!context.isFlutterProject) {
    stderr.writeln('This directory does not appear to be a Flutter project.');
    return 1;
  }

  final findings = inspectProject(context);
  stdout.writeln(renderInitSummary(findings));

  final configFile = File('$projectPath/vyrax.yaml');
  final prompt = configFile.existsSync()
      ? 'vyrax.yaml already exists.\n\nOverwrite?\n\n(Y/n)'
      : 'Generate vyrax.yaml?\n\n(Y/n)';

  final shouldGenerate = await confirmGeneration(prompt);
  if (!shouldGenerate) {
    stdout.writeln('Cancelled.');
    return 0;
  }

  configFile.writeAsStringSync(buildVyraxYaml(findings));
  stdout.writeln('Created vyrax.yaml at $projectPath');
  stdout.writeln('Default rules enabled: ${defaultRuleCount()}');
  return 0;
}

/// Executes the `vyrax analyze` command.
Future<int> runAnalyzeCommand(List<String> arguments) async {
  final projectPath = _resolveTargetProjectPath(arguments);
  if (projectPath == null) {
    return 3;
  }

  final target = await _resolveAnalyzeTarget(projectPath, arguments);
  if (!target.isOk) {
    if (target.message != null && target.message!.isNotEmpty) {
      stderr.writeln(target.message);
    }
    return target.exitCode;
  }

  return _runAnalyzeForProject(projectPath, arguments, target: target.value!);
}

Future<int> _runAnalyzeForProject(
  String projectPath,
  List<String> arguments, {
  required _AnalyzeTarget target,
}) async {
  final start = DateTime.now();
  final config = _loadConfiguration(projectPath);
  final outputFormat = _resolveOutputFormat(arguments, config);
  final enabledRules = _resolveEnabledRules(config);
  final severityOverrides = _resolveSeverityOverrides(config);
  final reportOptions = _resolveAnalyzeReportOptions(arguments, config);

  final rules = createDefaultRules()
      .where((rule) => enabledRules[rule.id] ?? true)
      .toList(growable: false);

  stderr.writeln('Info: analyzing project at $projectPath');
  stderr.writeln(
    'Info: scope ${target.scope.name}${target.selectedFiles == null ? '' : ' (${target.selectedFiles!.length} Dart files)'}',
  );

  const engine = DefaultVyraxAnalyzerEngine();
  final context = DefaultVyraxRuleContext(
    configuration: VyraxConfiguration(values: config),
    projectPath: projectPath,
  );

  final selectedFiles = target.selectedFiles;
  if (selectedFiles != null) {
    AnalysisFileSelection.setSelectedDartFiles(selectedFiles);
  } else {
    AnalysisFileSelection.clearSelectedDartFiles();
  }

  List<VyraxIssue> rawIssues;
  try {
    rawIssues = await engine.run(context: context, rules: rules);
  } finally {
    AnalysisFileSelection.clearSelectedDartFiles();
  }
  final issues = rawIssues
      .map((issue) {
        final override = severityOverrides[issue.id];
        if (override == null) {
          return issue;
        }
        return VyraxIssue(
          id: issue.id,
          title: issue.title,
          description: issue.description,
          severity: override,
          category: issue.category,
          file: issue.file,
          line: issue.line,
          impact: issue.impact,
          recommendation: issue.recommendation,
          documentationUrl: issue.documentationUrl,
        );
      })
      .toList(growable: false);
  final qualityScores = computeQualityScores(issues);
  final overallScore = computeOverallQualityScore(qualityScores);
  final elapsedMs = DateTime.now().difference(start).inMilliseconds;

  final textOutput = _renderText(
    issues,
    elapsedMs,
    rules.length,
    qualityScores,
    overallScore,
  );
  if (outputFormat == 'json') {
    stdout.writeln(
      _renderJson(issues, elapsedMs, rules.length, qualityScores, overallScore),
    );
  } else {
    stdout.writeln(textOutput);
  }

  _writeAnalyzeTextReport(
    projectPath: projectPath,
    generatedAt: start,
    textOutput: textOutput,
    options: reportOptions,
  );

  return _resolveExitCode(issues);
}

final class _AnalyzeReportOptions {
  const _AnalyzeReportOptions({required this.enabled, required this.path});

  final bool enabled;
  final String? path;
}

_AnalyzeReportOptions _resolveAnalyzeReportOptions(
  List<String> arguments,
  Map<String, Object?> config,
) {
  if (arguments.contains('--no-report')) {
    return const _AnalyzeReportOptions(enabled: false, path: null);
  }

  final argPath = _parseReportPathArg(arguments);
  if (argPath != null) {
    return _AnalyzeReportOptions(enabled: true, path: argPath);
  }

  final output = config['output'];
  if (output is Map<String, Object?>) {
    final report = output['report'];
    if (report is Map<String, Object?>) {
      final enabled = report['enabled'];
      final path = report['path'];
      return _AnalyzeReportOptions(
        enabled: enabled is bool ? enabled : true,
        path: path is String && path.trim().isNotEmpty ? path.trim() : null,
      );
    }
  }

  return const _AnalyzeReportOptions(enabled: true, path: null);
}

String? _parseReportPathArg(List<String> arguments) {
  for (var i = 0; i < arguments.length; i++) {
    if (arguments[i] == '--report-path' && i + 1 < arguments.length) {
      final value = arguments[i + 1].trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
  }
  return null;
}

void _writeAnalyzeTextReport({
  required String projectPath,
  required DateTime generatedAt,
  required String textOutput,
  required _AnalyzeReportOptions options,
}) {
  if (!options.enabled) {
    return;
  }

  final reportPath = options.path == null
      ? '$projectPath/vyrax-reports/analyze-${_timestampForFilename(generatedAt)}.txt'
      : _resolveReportPath(projectPath, options.path!);

  final reportFile = File(reportPath);
  reportFile.parent.createSync(recursive: true);
  reportFile.writeAsStringSync(textOutput);
  stderr.writeln('Info: analysis report written to $reportPath');
}

String _resolveReportPath(String projectPath, String configuredPath) {
  final file = File(configuredPath);
  if (file.isAbsolute) {
    return file.path;
  }
  return '$projectPath/$configuredPath';
}

String _timestampForFilename(DateTime value) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  return '${value.year}${twoDigits(value.month)}${twoDigits(value.day)}-${twoDigits(value.hour)}${twoDigits(value.minute)}${twoDigits(value.second)}';
}

bool _looksLikeFlutterProject(String pubspecContent) =>
    pubspecContent.contains('sdk: flutter') ||
    pubspecContent.contains('\nflutter:');

String _resolveProjectPath(List<String> arguments) {
  for (var i = 0; i < arguments.length; i++) {
    if (arguments[i] == '--project' && i + 1 < arguments.length) {
      return Directory(arguments[i + 1]).absolute.path;
    }
  }
  return Directory.current.path;
}

String? _resolveTargetProjectPath(List<String> arguments) {
  final projectPath = _resolveProjectPath(arguments);
  final pubspec = File('$projectPath/pubspec.yaml');
  if (pubspec.existsSync() &&
      _looksLikeFlutterProject(pubspec.readAsStringSync())) {
    return projectPath;
  }

  final discovered = _discoverFlutterProjects(projectPath);
  if (discovered.length == 1) {
    stderr.writeln(
      'Info: detected Flutter project at ${discovered.single.path}. Using it for this command.',
    );
    return discovered.single.path;
  }

  if (discovered.length > 1) {
    stderr.writeln('Current directory is not a Flutter project.');
    stderr.writeln('Multiple Flutter projects were found:');
    for (final directory in discovered) {
      stderr.writeln('- ${directory.path}');
    }
    stderr.writeln('Use --project <path> to choose one.');
    return null;
  }

  stderr.writeln(
    'Not a Flutter project. Could not detect Flutter in pubspec.yaml.',
  );
  return null;
}

enum _AnalysisScope { project, changed, staged, branch, directory, file }

final class _AnalyzeTarget {
  const _AnalyzeTarget({required this.scope, required this.selectedFiles});

  final _AnalysisScope scope;
  final List<String>? selectedFiles;
}

final class _TargetResolution {
  const _TargetResolution._({
    required this.isOk,
    required this.exitCode,
    this.message,
    this.value,
  });

  const _TargetResolution.ok(_AnalyzeTarget value)
    : this._(isOk: true, exitCode: 0, value: value);

  const _TargetResolution.error(int exitCode, String message)
    : this._(isOk: false, exitCode: exitCode, message: message);

  final bool isOk;
  final int exitCode;
  final String? message;
  final _AnalyzeTarget? value;
}

Future<_TargetResolution> _resolveAnalyzeTarget(
  String projectPath,
  List<String> arguments,
) async {
  final request = _parseAnalyzeScopeRequest(arguments);
  if (request == null) {
    return const _TargetResolution.error(
      3,
      'Invalid analyze options. Use only one scope selector: --changed, --staged, --against <branch>, or a single directory/file path.',
    );
  }

  switch (request.scope) {
    case _AnalysisScope.project:
      return const _TargetResolution.ok(
        _AnalyzeTarget(scope: _AnalysisScope.project, selectedFiles: null),
      );
    case _AnalysisScope.changed:
      final changed = await _resolveChangedFiles(projectPath);
      if (!changed.isOk) {
        return changed.toErrorResolution();
      }
      if (changed.files.isEmpty) {
        return const _TargetResolution.error(
          0,
          'No modified Dart files found.',
        );
      }
      return _TargetResolution.ok(
        _AnalyzeTarget(
          scope: _AnalysisScope.changed,
          selectedFiles: changed.files,
        ),
      );
    case _AnalysisScope.staged:
      final staged = await _resolveStagedFiles(projectPath);
      if (!staged.isOk) {
        return staged.toErrorResolution();
      }
      if (staged.files.isEmpty) {
        return const _TargetResolution.error(0, 'No staged Dart files found.');
      }
      return _TargetResolution.ok(
        _AnalyzeTarget(
          scope: _AnalysisScope.staged,
          selectedFiles: staged.files,
        ),
      );
    case _AnalysisScope.branch:
      final branchName = request.branchName;
      if (branchName == null || branchName.isEmpty) {
        return const _TargetResolution.error(
          3,
          'Missing branch name. Use: vyrax analyze --against <branch>',
        );
      }
      final branch = await _resolveBranchDiffFiles(projectPath, branchName);
      if (!branch.isOk) {
        return branch.toErrorResolution();
      }
      if (branch.files.isEmpty) {
        return const _TargetResolution.error(
          0,
          'No modified Dart files found.',
        );
      }
      return _TargetResolution.ok(
        _AnalyzeTarget(
          scope: _AnalysisScope.branch,
          selectedFiles: branch.files,
        ),
      );
    case _AnalysisScope.directory:
    case _AnalysisScope.file:
      final pathValue = request.pathValue;
      if (pathValue == null || pathValue.isEmpty) {
        return const _TargetResolution.error(3, 'Missing analyze path.');
      }

      final resolved = _resolveInputPath(projectPath, pathValue);
      if (!resolved.existsSync()) {
        return _TargetResolution.error(3, 'Path not found: $pathValue');
      }

      if (resolved is File) {
        if (!resolved.path.endsWith('.dart')) {
          return const _TargetResolution.error(0, 'No Dart files found.');
        }
        return _TargetResolution.ok(
          _AnalyzeTarget(
            scope: _AnalysisScope.file,
            selectedFiles: <String>[resolved.absolute.path],
          ),
        );
      }

      if (resolved is! Directory) {
        return _TargetResolution.error(
          3,
          'Path is not a directory: $pathValue',
        );
      }

      final files = _collectDartFilesInDirectory(resolved);
      if (files.isEmpty) {
        return const _TargetResolution.error(0, 'No Dart files found.');
      }
      return _TargetResolution.ok(
        _AnalyzeTarget(scope: _AnalysisScope.directory, selectedFiles: files),
      );
  }
}

final class _AnalyzeScopeRequest {
  const _AnalyzeScopeRequest({
    required this.scope,
    this.branchName,
    this.pathValue,
  });

  final _AnalysisScope scope;
  final String? branchName;
  final String? pathValue;
}

_AnalyzeScopeRequest? _parseAnalyzeScopeRequest(List<String> arguments) {
  final selectors = <String>[];
  var wantsChanged = false;
  var wantsStaged = false;
  String? againstBranch;
  String? positional;

  for (var index = 0; index < arguments.length; index++) {
    final arg = arguments[index];
    if (arg == '--project' ||
        arg == '--format' ||
        arg == '--report-path' ||
        arg == '--against') {
      index++;
      continue;
    }
    if (arg == '--changed') {
      wantsChanged = true;
      selectors.add('--changed');
      continue;
    }
    if (arg == '--staged') {
      wantsStaged = true;
      selectors.add('--staged');
      continue;
    }
    if (arg == '--no-report') {
      continue;
    }
    if (!arg.startsWith('-')) {
      positional ??= arg;
      selectors.add('path');
    }
  }

  for (var index = 0; index < arguments.length; index++) {
    if (arguments[index] == '--against' && index + 1 < arguments.length) {
      againstBranch = arguments[index + 1];
      selectors.add('--against');
      break;
    }
  }

  final uniqueSelectors = selectors.toSet();
  if (uniqueSelectors.length > 1) {
    return null;
  }

  if (wantsChanged) {
    return const _AnalyzeScopeRequest(scope: _AnalysisScope.changed);
  }
  if (wantsStaged) {
    return const _AnalyzeScopeRequest(scope: _AnalysisScope.staged);
  }
  if (againstBranch != null) {
    return _AnalyzeScopeRequest(
      scope: _AnalysisScope.branch,
      branchName: againstBranch,
    );
  }
  if (positional != null) {
    final maybeFile = File(positional);
    final scope = maybeFile.path.endsWith('.dart')
        ? _AnalysisScope.file
        : _AnalysisScope.directory;
    return _AnalyzeScopeRequest(scope: scope, pathValue: positional);
  }

  return const _AnalyzeScopeRequest(scope: _AnalysisScope.project);
}

FileSystemEntity _resolveInputPath(String projectPath, String pathValue) {
  final file = File(pathValue);
  if (file.isAbsolute) {
    if (file.existsSync()) {
      return file;
    }
    final directory = Directory(pathValue);
    return directory;
  }

  final absolute = '$projectPath/$pathValue';
  final localFile = File(absolute);
  if (localFile.existsSync()) {
    return localFile;
  }
  return Directory(absolute);
}

List<String> _collectDartFilesInDirectory(Directory root) {
  if (!root.existsSync()) {
    return const <String>[];
  }

  return root
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) {
        final path = file.path;
        return !path.contains('/.dart_tool/') &&
            !path.contains('/build/') &&
            !path.contains('/.git/') &&
            !path.contains('/.idea/');
      })
      .map((file) => file.absolute.path)
      .toSet()
      .toList(growable: false)
    ..sort();
}

final class _FileResolution {
  const _FileResolution({
    this.message,
    this.exitCode = 0,
    this.files = const [],
  });

  final String? message;
  final int exitCode;
  final List<String> files;

  bool get isOk => message == null;

  _TargetResolution toErrorResolution() =>
      _TargetResolution.error(exitCode, message ?? 'Unknown error');
}

Future<_FileResolution> _resolveChangedFiles(String projectPath) async {
  final gitReady = await _isGitRepository(projectPath);
  if (!gitReady) {
    return const _FileResolution(
      exitCode: 1,
      message:
          'No Git repository found.\n\nUse:\n\nvyrax analyze\n\nto analyze the entire project.',
    );
  }

  final unstaged = await _gitPaths(projectPath, const ['diff', '--name-only']);
  final staged = await _gitPaths(projectPath, const [
    'diff',
    '--cached',
    '--name-only',
  ]);
  final untracked = await _gitPaths(projectPath, const [
    'ls-files',
    '--others',
    '--exclude-standard',
  ]);

  final merged = <String>{...unstaged, ...staged, ...untracked};
  final files = _resolveDartFilesFromGitPaths(projectPath, merged.toList());
  return _FileResolution(files: files);
}

Future<_FileResolution> _resolveStagedFiles(String projectPath) async {
  final gitReady = await _isGitRepository(projectPath);
  if (!gitReady) {
    return const _FileResolution(
      exitCode: 1,
      message:
          'No Git repository found.\n\nUse:\n\nvyrax analyze\n\nto analyze the entire project.',
    );
  }

  final staged = await _gitPaths(projectPath, const [
    'diff',
    '--cached',
    '--name-only',
  ]);
  final files = _resolveDartFilesFromGitPaths(projectPath, staged);
  return _FileResolution(files: files);
}

Future<_FileResolution> _resolveBranchDiffFiles(
  String projectPath,
  String branchName,
) async {
  final gitReady = await _isGitRepository(projectPath);
  if (!gitReady) {
    return const _FileResolution(
      exitCode: 1,
      message:
          'No Git repository found.\n\nUse:\n\nvyrax analyze\n\nto analyze the entire project.',
    );
  }

  final branchExists = await _gitExitCode(projectPath, [
    'rev-parse',
    '--verify',
    '--quiet',
    '$branchName^{commit}',
  ]);
  if (branchExists != 0) {
    return _FileResolution(
      exitCode: 1,
      message: 'Branch "$branchName" not found.',
    );
  }

  final changed = await _gitPaths(projectPath, [
    'diff',
    '--name-only',
    '$branchName...HEAD',
  ]);
  final files = _resolveDartFilesFromGitPaths(projectPath, changed);
  return _FileResolution(files: files);
}

Future<bool> _isGitRepository(String projectPath) async {
  final code = await _gitExitCode(projectPath, const [
    'rev-parse',
    '--is-inside-work-tree',
  ]);
  return code == 0;
}

Future<int> _gitExitCode(String projectPath, List<String> args) async {
  final result = await Process.run('git', ['-C', projectPath, ...args]);
  return result.exitCode;
}

Future<List<String>> _gitPaths(String projectPath, List<String> args) async {
  final result = await Process.run('git', ['-C', projectPath, ...args]);
  if (result.exitCode != 0) {
    return const <String>[];
  }

  return result.stdout
      .toString()
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

List<String> _resolveDartFilesFromGitPaths(
  String projectPath,
  List<String> paths,
) {
  final files = <String>{};
  for (final path in paths) {
    if (!path.endsWith('.dart')) {
      continue;
    }
    final absolute = File('$projectPath/$path').absolute;
    if (!absolute.existsSync()) {
      continue;
    }
    final absolutePath = absolute.path;
    if (absolutePath.contains('/.dart_tool/') ||
        absolutePath.contains('/build/') ||
        absolutePath.contains('/.git/') ||
        absolutePath.contains('/.idea/')) {
      continue;
    }
    files.add(absolutePath);
  }

  final sorted = files.toList(growable: false);
  sorted.sort();
  return sorted;
}

List<Directory> _discoverFlutterProjects(String rootPath) {
  final root = Directory(rootPath);
  if (!root.existsSync()) {
    return const <Directory>[];
  }

  final projects = <Directory>[];
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('/pubspec.yaml')) {
      continue;
    }

    final content = entity.readAsStringSync();
    if (!_looksLikeFlutterProject(content)) {
      continue;
    }

    final parent = entity.parent.path;
    if (parent.contains('/.dart_tool/') || parent.contains('/build/')) {
      continue;
    }
    projects.add(entity.parent);
  }

  return projects;
}

Map<String, Object?> _loadConfiguration(String projectPath) {
  final file = File('$projectPath/vyrax.yaml');
  if (!file.existsSync()) {
    return <String, Object?>{};
  }

  final yaml = loadYaml(file.readAsStringSync());
  final map = _toEncodable(yaml);
  return map is Map<String, Object?> ? map : <String, Object?>{};
}

Object? _toEncodable(Object? value) {
  if (value is YamlMap) {
    return value.map(
      (key, dynamic v) => MapEntry(key.toString(), _toEncodable(v)),
    );
  }
  if (value is YamlList) {
    return value.map(_toEncodable).toList(growable: false);
  }
  return value;
}

String _resolveOutputFormat(
  List<String> arguments,
  Map<String, Object?> config,
) {
  final argFormat = _parseFormatArg(arguments);
  if (argFormat != null) {
    return argFormat;
  }
  final output = config['output'];
  if (output is Map<String, Object?>) {
    final value = output['format'];
    if (value is String && (value == 'text' || value == 'json')) {
      return value;
    }
  }
  return 'text';
}

String? _parseFormatArg(List<String> arguments) {
  for (var i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    if (arg == '--format' && i + 1 < arguments.length) {
      final value = arguments[i + 1];
      if (value == 'text' || value == 'json') {
        return value;
      }
    }
  }
  return null;
}

Map<String, bool> _resolveEnabledRules(Map<String, Object?> config) {
  final rules = config['rules'];
  if (rules is! Map<String, Object?>) {
    return <String, bool>{};
  }

  final enabled = <String, bool>{};
  for (final entry in rules.entries) {
    final canonicalRuleId = _canonicalRuleId(entry.key);
    if (canonicalRuleId == null) {
      continue;
    }
    final value = entry.value;
    if (value is Map<String, Object?> && value['enabled'] is bool) {
      enabled[canonicalRuleId] = value['enabled'] as bool;
    }
  }
  return enabled;
}

Map<String, VyraxSeverity> _resolveSeverityOverrides(
  Map<String, Object?> config,
) {
  final rules = config['rules'];
  if (rules is! Map<String, Object?>) {
    return <String, VyraxSeverity>{};
  }

  final overrides = <String, VyraxSeverity>{};
  for (final entry in rules.entries) {
    final canonicalRuleId = _canonicalRuleId(entry.key);
    if (canonicalRuleId == null) {
      continue;
    }
    final value = entry.value;
    if (value is Map<String, Object?> && value['severity'] is String) {
      final severity = _severityFromString(value['severity'] as String);
      if (severity != null) {
        overrides[canonicalRuleId] = severity;
      }
    }
  }
  return overrides;
}

String? _canonicalRuleId(String configuredKey) {
  final normalized = configuredKey
      .toLowerCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');
  const aliases = <String, String>{
    'vyx001': 'VYX001',
    'future_inside_build': 'VYX001',
    'future_in_build': 'VYX001',
    'vyx002': 'VYX002',
    'network_inside_build': 'VYX002',
    'network_in_build': 'VYX002',
    'vyx003': 'VYX003',
    'multiple_public_classes': 'VYX003',
    'vyx004': 'VYX004',
    'build_complexity': 'VYX004',
    'vyx005': 'VYX005',
    'large_consumer_scope': 'VYX005',
    'consumer_scope': 'VYX005',
    'vyx006': 'VYX006',
    'setstate_with_state_management': 'VYX006',
    'set_state_with_state_management': 'VYX006',
    'avoid_setstate_with_state_management': 'VYX006',
    'avoid_setstate': 'VYX006',
    'vyx007': 'VYX007',
    'unbounded_scrollable_in_column': 'VYX007',
    'scroll_inside_column': 'VYX007',
    'layout_unbounded_scroll': 'VYX007',
    'vyx008': 'VYX008',
    'clean_without_use_cases': 'VYX008',
    'clean_architecture_without_use_cases': 'VYX008',
    'vyx009': 'VYX009',
    'presentation_depends_on_data_layer': 'VYX009',
    'ui_depends_on_data_layer': 'VYX009',
    'vyx010': 'VYX010',
    'direct_external_package_in_presentation': 'VYX010',
    'missing_handlers_in_presentation': 'VYX010',
    'vyx011': 'VYX011',
    'singleton_overuse': 'VYX011',
    'overused_singletons': 'VYX011',
    'vyx012': 'VYX012',
    'missing_internationalization': 'VYX012',
    'missing_i18n': 'VYX012',
    'vyx013': 'VYX013',
    'broad_reactive_rebuild_scope': 'VYX013',
    'large_reactive_scope': 'VYX013',
    'reactive_rebuild_scope': 'VYX013',
    'vyx014': 'VYX014',
    'error_model_without_factory_mapper': 'VYX014',
    'error_without_factory': 'VYX014',
    'missing_error_factory': 'VYX014',
    'vyx015': 'VYX015',
    'hardcoded_ui_text': 'VYX015',
    'hardcoded_text': 'VYX015',
    'missing_text_localization': 'VYX015',
    'vyx016': 'VYX016',
    'repeated_magic_numbers': 'VYX016',
    'magic_numbers': 'VYX016',
    'repeated_numeric_literals': 'VYX016',
    'vyx017': 'VYX017',
    'large_file': 'VYX017',
    'file_too_large': 'VYX017',
    'max_lines_per_file': 'VYX017',
    'vyx018': 'VYX018',
    'solid_single_responsibility': 'VYX018',
    'single_responsibility': 'VYX018',
    'srp': 'VYX018',
    'vyx019': 'VYX019',
    'solid_open_closed': 'VYX019',
    'open_closed': 'VYX019',
    'ocp': 'VYX019',
    'vyx020': 'VYX020',
    'solid_dependency_inversion': 'VYX020',
    'dependency_inversion': 'VYX020',
    'dip': 'VYX020',
    'vyx021': 'VYX021',
    'solid_opportunity': 'VYX021',
    'solid_feedback': 'VYX021',
    'vyx022': 'VYX022',
    'widget_lifecycle': 'VYX022',
    'async_lifecycle': 'VYX022',
    'lifecycle_misuse': 'VYX022',
    'vyx023': 'VYX023',
    'widget_tree': 'VYX023',
    'widget_tree_complexity': 'VYX023',
    'tree_topology': 'VYX023',
  };

  return aliases[normalized];
}

VyraxSeverity? _severityFromString(String value) {
  switch (value.toLowerCase()) {
    case 'info':
      return VyraxSeverity.info;
    case 'warning':
      return VyraxSeverity.warning;
    case 'error':
      return VyraxSeverity.error;
    case 'critical':
      return VyraxSeverity.critical;
    default:
      return null;
  }
}

int _resolveExitCode(List<VyraxIssue> issues) {
  final hasError = issues.any(
    (issue) =>
        issue.severity == VyraxSeverity.error ||
        issue.severity == VyraxSeverity.critical,
  );
  if (hasError) {
    return 2;
  }

  final hasWarning = issues.any(
    (issue) => issue.severity == VyraxSeverity.warning,
  );
  if (hasWarning) {
    return 1;
  }

  return 0;
}

String _renderText(
  List<VyraxIssue> issues,
  int elapsedMs,
  int ruleCount,
  Map<String, double> qualityScores,
  double overallScore,
) {
  final summary = _summary(issues);
  final severityOrder = <VyraxSeverity>[
    VyraxSeverity.critical,
    VyraxSeverity.error,
    VyraxSeverity.warning,
    VyraxSeverity.info,
  ];

  final grouped = <VyraxSeverity, List<VyraxIssue>>{
    for (final severity in severityOrder) severity: <VyraxIssue>[],
  };
  for (final issue in issues) {
    grouped[issue.severity]!.add(issue);
  }

  final buffer = StringBuffer()
    ..writeln('Analyzing Flutter project...')
    ..writeln('')
    ..writeln('Rules executed: $ruleCount')
    ..writeln('--------------------------------');

  for (final severity in severityOrder) {
    final entries = grouped[severity]!;
    if (entries.isEmpty) {
      continue;
    }

    buffer
      ..writeln('')
      ..writeln('${severity.name.toUpperCase()} (${entries.length})')
      ..writeln('--------------------------------');

    for (final issue in entries) {
      buffer
        ..writeln('')
        ..writeln('${issue.id} ${issue.title}')
        ..writeln(issue.location)
        ..writeln('')
        ..writeln(issue.description);

      if (issue.impact != null) {
        buffer
          ..writeln('')
          ..writeln('Impact: ${issue.impact}');
      }

      if (issue.recommendation != null) {
        buffer
          ..writeln('')
          ..writeln('Recommendation: ${issue.recommendation}');
      }

      buffer.writeln('--------------------------------');
    }
  }

  buffer
    ..writeln('')
    ..writeln('Summary')
    ..writeln('Overall: ${overallScore.toStringAsFixed(1)}%')
    ..writeln(
      'Performance: ${qualityScores['performance']!.toStringAsFixed(1)}%',
    )
    ..writeln(
      'Maintainability: ${qualityScores['maintainability']!.toStringAsFixed(1)}%',
    )
    ..writeln(
      'Testability: ${qualityScores['testability']!.toStringAsFixed(1)}%',
    )
    ..writeln('Critical: ${summary['critical']}')
    ..writeln('Errors: ${summary['error']}')
    ..writeln('Warnings: ${summary['warning']}')
    ..writeln('Info: ${summary['info']}')
    ..writeln('Time: ${(elapsedMs / 1000).toStringAsFixed(2)}s');

  return buffer.toString();
}

String _renderJson(
  List<VyraxIssue> issues,
  int elapsedMs,
  int ruleCount,
  Map<String, double> qualityScores,
  double overallScore,
) {
  final payload = <String, Object?>{
    'summary': _summary(issues),
    'scores': <String, Object?>{
      'overallPercent': double.parse(overallScore.toStringAsFixed(1)),
      'performancePercent': double.parse(
        qualityScores['performance']!.toStringAsFixed(1),
      ),
      'maintainabilityPercent': double.parse(
        qualityScores['maintainability']!.toStringAsFixed(1),
      ),
      'testabilityPercent': double.parse(
        qualityScores['testability']!.toStringAsFixed(1),
      ),
    },
    'rulesExecuted': ruleCount,
    'timeMs': elapsedMs,
    'issues': issues
        .map(
          (issue) => <String, Object?>{
            'id': issue.id,
            'severity': issue.severity.name,
            'category': issue.category.name,
            'file': issue.file,
            'line': issue.line,
            'title': issue.title,
            'description': issue.description,
            'impact': issue.impact,
            'recommendation': issue.recommendation,
            'documentation': issue.documentationUrl,
          },
        )
        .toList(growable: false),
  };

  return const JsonEncoder.withIndent('  ').convert(payload);
}

Map<String, int> _summary(List<VyraxIssue> issues) {
  var critical = 0;
  var error = 0;
  var warning = 0;
  var info = 0;

  for (final issue in issues) {
    switch (issue.severity) {
      case VyraxSeverity.critical:
        critical++;
        break;
      case VyraxSeverity.error:
        error++;
        break;
      case VyraxSeverity.warning:
        warning++;
        break;
      case VyraxSeverity.info:
        info++;
        break;
    }
  }

  return <String, int>{
    'critical': critical,
    'error': error,
    'warning': warning,
    'info': info,
  };
}
