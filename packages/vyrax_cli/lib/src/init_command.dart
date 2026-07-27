import 'dart:io';

import 'package:yaml/yaml.dart';

/// Parsed context extracted from a Flutter project's pubspec.
final class ProjectContext {
  /// Creates a [ProjectContext].
  const ProjectContext({
    required this.projectPath,
    required this.name,
    required this.flutterSdkConstraint,
    required this.dartSdkConstraint,
    required this.dependencyNames,
    required this.devDependencyNames,
    required this.isFlutterProject,
  });

  /// Absolute path to the project root.
  final String projectPath;

  /// Package name declared in `pubspec.yaml`.
  final String name;

  /// Flutter SDK constraint from `environment.flutter`.
  final String flutterSdkConstraint;

  /// Dart SDK constraint from `environment.sdk`.
  final String dartSdkConstraint;

  /// Dependency names declared in `dependencies`.
  final Set<String> dependencyNames;

  /// Dependency names declared in `dev_dependencies`.
  final Set<String> devDependencyNames;

  /// Whether this project depends on the Flutter SDK.
  final bool isFlutterProject;
}

/// Result of inferred project characteristics used by `vyrax init`.
final class InitFindings {
  /// Creates an [InitFindings].
  const InitFindings({
    required this.context,
    required this.stateManagement,
    required this.dependencyInjection,
    required this.networking,
    required this.routing,
    required this.serialization,
    required this.architecture,
    required this.architectureConfidence,
    required this.qualityTools,
  });

  /// Parsed project context used as inspection input.
  final ProjectContext context;

  /// Detected state-management solution.
  final String stateManagement;

  /// Detected dependency-injection solution.
  final String dependencyInjection;

  /// Detected networking client/stack.
  final String networking;

  /// Detected routing solution.
  final String routing;

  /// Detected model serialization approach.
  final String serialization;

  /// Detected architecture style.
  final String architecture;

  /// Confidence score for the architecture detection.
  final String architectureConfidence;

  /// Additional quality tools detected in the project.
  final List<String> qualityTools;
}

/// Parses and validates project metadata from `pubspec.yaml`.
ProjectContext parseProjectContext(String projectPath) {
  final pubspecFile = File('$projectPath/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    throw const FormatException('pubspec.yaml was not found.');
  }

  final raw = pubspecFile.readAsStringSync();
  final Object? parsed;
  try {
    parsed = loadYaml(raw);
  } catch (error) {
    throw FormatException('pubspec.yaml could not be parsed: $error');
  }

  if (parsed is! YamlMap) {
    throw const FormatException('pubspec.yaml must contain a YAML mapping.');
  }

  final name = parsed['name']?.toString() ?? 'unknown';
  final environment = parsed['environment'];
  var flutterSdkConstraint = 'unknown';
  var dartSdkConstraint = 'unknown';
  if (environment is YamlMap) {
    final flutter = environment['flutter'];
    if (flutter != null) {
      flutterSdkConstraint = flutter.toString();
    }
    final dart = environment['sdk'];
    if (dart != null) {
      dartSdkConstraint = dart.toString();
    }
  }

  final dependencyNames = _dependencyNames(parsed['dependencies']);
  final devDependencyNames = _dependencyNames(parsed['dev_dependencies']);
  final isFlutterProject = _isFlutterDependency(parsed['dependencies']);

  return ProjectContext(
    projectPath: projectPath,
    name: name,
    flutterSdkConstraint: flutterSdkConstraint,
    dartSdkConstraint: dartSdkConstraint,
    dependencyNames: dependencyNames,
    devDependencyNames: devDependencyNames,
    isFlutterProject: isFlutterProject,
  );
}

/// Infers architecture, stack, and quality characteristics from a project context.
InitFindings inspectProject(ProjectContext context) {
  final allDeps = <String>{
    ...context.dependencyNames,
    ...context.devDependencyNames,
  };

  final architecture = _detectArchitecture(context.projectPath);
  final qualityTools = _detectQualityTools(context.projectPath, allDeps);

  return InitFindings(
    context: context,
    stateManagement: _detectStateManagement(allDeps),
    dependencyInjection: _detectDependencyInjection(allDeps),
    networking: _detectNetworking(allDeps),
    routing: _detectRouting(allDeps),
    serialization: _detectSerialization(allDeps),
    architecture: architecture.$1,
    architectureConfidence: architecture.$2,
    qualityTools: qualityTools,
  );
}

/// Renders a human-readable summary before write confirmation.
String renderInitSummary(InitFindings findings) {
  String marker(String value) => value == 'unknown' ? '?' : '✓';

  final buffer = StringBuffer()
    ..writeln('Flutter project detected')
    ..writeln('')
    ..writeln('Project')
    ..writeln(findings.context.name)
    ..writeln('')
    ..writeln('Flutter')
    ..writeln(findings.context.flutterSdkConstraint)
    ..writeln('')
    ..writeln('Dart')
    ..writeln(findings.context.dartSdkConstraint)
    ..writeln('')
    ..writeln('----------------------------')
    ..writeln('')
    ..writeln('Detected Stack')
    ..writeln('')
    ..writeln('State Management')
    ..writeln(
      '${marker(findings.stateManagement)} ${_pretty(findings.stateManagement)}',
    )
    ..writeln('')
    ..writeln('Dependency Injection')
    ..writeln(
      '${marker(findings.dependencyInjection)} ${_pretty(findings.dependencyInjection)}',
    )
    ..writeln('')
    ..writeln('Networking')
    ..writeln('${marker(findings.networking)} ${_pretty(findings.networking)}')
    ..writeln('')
    ..writeln('Routing')
    ..writeln('${marker(findings.routing)} ${_pretty(findings.routing)}')
    ..writeln('')
    ..writeln('Serialization')
    ..writeln(
      '${marker(findings.serialization)} ${_pretty(findings.serialization)}',
    )
    ..writeln('')
    ..writeln('Architecture')
    ..writeln(
      '${marker(findings.architecture)} ${_pretty(findings.architecture)}',
    )
    ..writeln('')
    ..writeln('Confidence')
    ..writeln(_pretty(findings.architectureConfidence));

  if (findings.qualityTools.isNotEmpty) {
    buffer
      ..writeln('')
      ..writeln('Quality Tools');
    for (final tool in findings.qualityTools) {
      buffer.writeln('✓ ${_pretty(tool)}');
    }
  }

  return buffer.toString();
}

/// Builds the generated `vyrax.yaml` content.
String buildVyraxYaml(InitFindings findings) =>
    '''project:
  name: ${findings.context.name}

flutter:
  sdk: "${findings.context.flutterSdkConstraint}"

architecture:
  type: ${findings.architecture}
  confidence: ${findings.architectureConfidence}

state_management:
  type: ${findings.stateManagement}

dependency_injection:
  type: ${findings.dependencyInjection}

network:
  client: ${findings.networking}

routing:
  type: ${findings.routing}

serialization:
  model_generator: ${findings.serialization}

rules:
  future_inside_build:
    enabled: true
  network_inside_build:
    enabled: true
  multiple_public_classes:
    enabled: true
  build_complexity:
    enabled: true
  large_consumer_scope:
    enabled: true
  set_state_with_state_management:
    enabled: true
  unbounded_scrollable_in_column:
    enabled: true
  clean_architecture_without_use_cases:
    enabled: true
  presentation_depends_on_data_layer:
    enabled: true
  direct_external_package_in_presentation:
    enabled: true
  singleton_overuse:
    enabled: true
  missing_internationalization:
    enabled: true
  broad_reactive_rebuild_scope:
    enabled: true
  error_model_without_factory_mapper:
    enabled: true
  hardcoded_ui_text:
    enabled: true
  repeated_magic_numbers:
    enabled: true
  large_file:
    enabled: true
  solid_single_responsibility:
    enabled: true
  solid_open_closed:
    enabled: true
  solid_dependency_inversion:
    enabled: true
  solid_opportunity:
    enabled: true
  widget_lifecycle:
    enabled: true
  widget_tree_complexity:
    enabled: true

limits:
  max_lines_per_file: 300

output:
  format: text
''';

/// Asks the user for confirmation and accepts yes/no style answers.
Future<bool> confirmGeneration(String prompt) async {
  while (true) {
    stdout.writeln(prompt);
    final input = stdin.readLineSync();
    if (input == null) {
      return false;
    }

    final normalized = input.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'y' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'n' || normalized == 'no') {
      return false;
    }
    stdout.writeln('Please answer with Y or N.');
  }
}

Set<String> _dependencyNames(Object? section) {
  if (section is! YamlMap) {
    return <String>{};
  }

  return section.keys.map((key) => key.toString().toLowerCase()).toSet();
}

bool _isFlutterDependency(Object? dependencies) {
  if (dependencies is! YamlMap) {
    return false;
  }

  final flutter = dependencies['flutter'];
  if (flutter is YamlMap) {
    return flutter['sdk']?.toString() == 'flutter';
  }
  return false;
}

String _detectStateManagement(Set<String> deps) {
  if (deps.contains('flutter_riverpod') ||
      deps.contains('hooks_riverpod') ||
      deps.contains('riverpod')) {
    return 'riverpod';
  }
  if (deps.contains('flutter_bloc') || deps.contains('bloc')) {
    return 'bloc';
  }
  if (deps.contains('provider')) {
    return 'provider';
  }
  if (deps.contains('get')) {
    return 'getx';
  }
  if (deps.contains('mobx') || deps.contains('flutter_mobx')) {
    return 'mobx';
  }
  if (deps.contains('flutter_redux')) {
    return 'redux';
  }
  return 'unknown';
}

String _detectDependencyInjection(Set<String> deps) {
  if (deps.contains('get_it')) {
    return 'get_it';
  }
  if (deps.contains('injectable')) {
    return 'injectable';
  }
  if (deps.contains('kiwi')) {
    return 'kiwi';
  }
  if (deps.contains('provider')) {
    return 'provider';
  }
  if (deps.contains('riverpod') ||
      deps.contains('hooks_riverpod') ||
      deps.contains('flutter_riverpod')) {
    return 'riverpod';
  }
  return 'unknown';
}

String _detectNetworking(Set<String> deps) {
  if (deps.contains('dio')) {
    return 'dio';
  }
  if (deps.contains('http')) {
    return 'http';
  }
  if (deps.contains('chopper')) {
    return 'chopper';
  }
  if (deps.contains('retrofit')) {
    return 'retrofit';
  }
  if (deps.contains('graphql_flutter')) {
    return 'graphql_flutter';
  }
  return 'unknown';
}

String _detectRouting(Set<String> deps) {
  if (deps.contains('go_router')) {
    return 'go_router';
  }
  if (deps.contains('auto_route')) {
    return 'auto_route';
  }
  if (deps.contains('beamer')) {
    return 'beamer';
  }
  if (deps.contains('fluro')) {
    return 'fluro';
  }
  return 'navigator';
}

String _detectSerialization(Set<String> deps) {
  if (deps.contains('freezed')) {
    return 'freezed';
  }
  if (deps.contains('json_serializable')) {
    return 'json_serializable';
  }
  if (deps.contains('built_value')) {
    return 'built_value';
  }
  return 'unknown';
}

(String, String) _detectArchitecture(String projectPath) {
  final cleanMarkers = <String>['domain', 'data', 'presentation'];
  final hasAllClean = cleanMarkers.every(
    (segment) =>
        Directory('$projectPath/lib/$segment').existsSync() ||
        Directory('$projectPath/$segment').existsSync(),
  );
  if (hasAllClean) {
    return ('clean', 'high');
  }

  final featureFirst =
      Directory('$projectPath/lib/features').existsSync() ||
      Directory('$projectPath/features').existsSync();
  if (featureFirst) {
    return ('feature_first', 'medium');
  }

  final mvvm =
      Directory('$projectPath/lib/view_models').existsSync() ||
      Directory('$projectPath/view_models').existsSync();
  if (mvvm) {
    return ('mvvm', 'medium');
  }

  final mvc =
      Directory('$projectPath/lib/controllers').existsSync() ||
      Directory('$projectPath/controllers').existsSync();
  if (mvc) {
    return ('mvc', 'low');
  }

  return ('unknown', 'low');
}

List<String> _detectQualityTools(String projectPath, Set<String> deps) {
  final detected = <String>[];
  if (deps.contains('flutter_lints')) {
    detected.add('flutter_lints');
  }
  if (deps.contains('custom_lint')) {
    detected.add('custom_lint');
  }
  if (deps.contains('build_runner')) {
    detected.add('build_runner');
  }
  if (deps.contains('very_good_analysis')) {
    detected.add('very_good_analysis');
  }
  if (File('$projectPath/melos.yaml').existsSync()) {
    detected.add('melos');
  }
  return detected;
}

String _pretty(String value) {
  if (value == 'unknown') {
    return 'Unknown';
  }

  return value
      .split('_')
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
