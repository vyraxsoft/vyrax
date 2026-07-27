/// CLI utilities for rendering command help and executing commands.
library;

import 'dart:convert';
import 'dart:io';

import 'package:vyrax_cli/src/init_command.dart';
import 'package:vyrax_core/vyrax_core.dart';
import 'package:vyrax_engine/vyrax_engine.dart';
import 'package:vyrax_rules/vyrax_rules.dart';
import 'package:yaml/yaml.dart';

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
    ..writeln('                Options: --project <path>, --format <text|json>')
    ..writeln('  --help, -h    Show this help message')
    ..writeln('')
    ..writeln('Planned commands:')
    ..writeln('  init, doctor, score, explain, fix');

  return buffer.toString();
}

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
  return 0;
}

/// Executes the `vyrax analyze` command.
Future<int> runAnalyzeCommand(List<String> arguments) async {
  final projectPath = _resolveTargetProjectPath(arguments);
  if (projectPath == null) {
    return 3;
  }

  return _runAnalyzeForProject(projectPath, arguments);
}

Future<int> _runAnalyzeForProject(
  String projectPath,
  List<String> arguments,
) async {
  final config = _loadConfiguration(projectPath);
  final outputFormat = _resolveOutputFormat(arguments, config);
  final enabledRules = _resolveEnabledRules(config);
  final severityOverrides = _resolveSeverityOverrides(config);

  final rules = createMvpRules()
      .where((rule) => enabledRules[rule.id] ?? true)
      .toList(growable: false);

  stderr.writeln('Info: analyzing project at $projectPath');

  const engine = DefaultVyraxAnalyzerEngine();
  final context = DefaultVyraxRuleContext(
    configuration: VyraxConfiguration(values: config),
    projectPath: projectPath,
  );

  final start = DateTime.now();
  final rawIssues = await engine.run(context: context, rules: rules);
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
  final elapsedMs = DateTime.now().difference(start).inMilliseconds;

  if (outputFormat == 'json') {
    stdout.writeln(_renderJson(issues, elapsedMs, rules.length));
  } else {
    stdout.writeln(_renderText(issues, elapsedMs, rules.length));
  }

  return _resolveExitCode(issues);
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

String _renderText(List<VyraxIssue> issues, int elapsedMs, int ruleCount) {
  final summary = _summary(issues);
  final buffer = StringBuffer()
    ..writeln('Analyzing Flutter project...')
    ..writeln('')
    ..writeln('Rules executed: $ruleCount')
    ..writeln('--------------------------------');

  for (final issue in issues) {
    buffer
      ..writeln('')
      ..writeln('${issue.severity.name.toUpperCase()} ${issue.id}')
      ..writeln(issue.title)
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

  buffer
    ..writeln('')
    ..writeln('Summary')
    ..writeln('Critical: ${summary['critical']}')
    ..writeln('Errors: ${summary['error']}')
    ..writeln('Warnings: ${summary['warning']}')
    ..writeln('Info: ${summary['info']}')
    ..writeln('Time: ${(elapsedMs / 1000).toStringAsFixed(2)}s');

  return buffer.toString();
}

String _renderJson(List<VyraxIssue> issues, int elapsedMs, int ruleCount) {
  final payload = <String, Object?>{
    'summary': _summary(issues),
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
