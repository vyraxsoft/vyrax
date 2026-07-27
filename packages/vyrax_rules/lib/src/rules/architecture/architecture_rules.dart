import 'dart:io';

import 'package:vyrax_core/vyrax_core.dart';
import 'package:vyrax_rules/src/rule_helpers.dart';

/// Detects overly complex `build` methods.
final class BuildComplexityRule implements VyraxRule {
  /// Creates a [BuildComplexityRule].
  const BuildComplexityRule();

  @override
  String get id => 'VYX004';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.architecture;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final block in collectBuildBlocks(source)) {
        final widgets = RegExp(
          r'\b[A-Z][A-Za-z0-9_]*\s*\(',
        ).allMatches(block.content).length;
        final conditions = RegExp(
          r'\bif\s*\(',
        ).allMatches(block.content).length;
        final builders = RegExp(
          r'\b[A-Za-z0-9_]*Builder\s*\(',
        ).allMatches(block.content).length;

        final isComplex = widgets > 24 || conditions > 4 || builders > 4;
        if (!isComplex) {
          continue;
        }

        final line = lineFromOffset(source, block.startOffset);
        issues.add(
          VyraxIssue(
            id: id,
            title: 'Build complexity',
            description:
                'build() seems too complex (widgets: $widgets, conditions: $conditions, builders: $builders).',
            severity: VyraxSeverity.warning,
            category: category,
            file: relativePath(context.projectPath, file.path),
            line: line,
            impact:
                'Complex build methods reduce readability and increase regressions.',
            recommendation:
                'Split UI into smaller widgets and move logic outside build().',
            documentationUrl: 'https://github.com/vyraxsoft/vyrax',
          ),
        );
      }
    }

    return issues;
  }
}

/// Detects scrollable widgets inside `Column` without proper constraints.
final class UnboundedScrollableInColumnRule implements VyraxRule {
  /// Creates a [UnboundedScrollableInColumnRule].
  const UnboundedScrollableInColumnRule();

  @override
  String get id => 'VYX007';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.widgets;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);
    final columnPattern = RegExp(r'Column\s*\([\s\S]{0,1600}\)');
    final scrollablePattern = RegExp(
      r'(SingleChildScrollView|ListView|GridView|CustomScrollView)\s*\(',
    );
    final boundedScrollablePattern = RegExp(
      r'(Expanded|Flexible)\s*\([\s\S]{0,160}(SingleChildScrollView|ListView|GridView|CustomScrollView)\s*\(',
    );

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final columnMatch in columnPattern.allMatches(source)) {
        final snippet = columnMatch.group(0);
        if (snippet == null) {
          continue;
        }

        if (!scrollablePattern.hasMatch(snippet)) {
          continue;
        }
        if (boundedScrollablePattern.hasMatch(snippet)) {
          continue;
        }

        final line = lineFromOffset(source, columnMatch.start);
        issues.add(
          VyraxIssue(
            id: id,
            title: 'Scrollable in Column without bounds',
            description:
                'Detected a scrollable widget inside Column without Expanded/Flexible constraints.',
            severity: VyraxSeverity.warning,
            category: category,
            file: relativePath(context.projectPath, file.path),
            line: line,
            impact:
                'This can cause overflow, layout exceptions, or hidden content on smaller screens.',
            recommendation:
                'Wrap the scrollable with Expanded/Flexible, or use a sliver-based layout to ensure bounded height.',
            documentationUrl: 'https://github.com/vyraxsoft/vyrax',
          ),
        );
      }
    }

    return issues;
  }
}

/// Detects clean architecture projects without a use case layer.
final class CleanArchitectureWithoutUseCasesRule implements VyraxRule {
  /// Creates a [CleanArchitectureWithoutUseCasesRule].
  const CleanArchitectureWithoutUseCasesRule();

  @override
  String get id => 'VYX008';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.architecture;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final architectureType = _configuredArchitecture(
      context.configuration.values,
    );
    if (architectureType != 'clean') {
      return const <VyraxIssue>[];
    }

    final useCasesDir = RegExp(
      r'(^|/)(domain|feature[s]?/.*/domain)/(use_case|use_cases|usecase|usecases)(/|$)',
    );
    final useCaseFile = RegExp(r'(_use_case\.dart$|_usecase\.dart$)');
    final files = collectDartFiles(context.projectPath);
    final hasUseCases = files.any(
      (file) =>
          useCasesDir.hasMatch(file.path) || useCaseFile.hasMatch(file.path),
    );

    if (hasUseCases) {
      return const <VyraxIssue>[];
    }

    return <VyraxIssue>[
      VyraxIssue(
        id: id,
        title: 'Clean architecture without use cases',
        description:
            'Project is configured as clean architecture but no use case layer was detected.',
        severity: VyraxSeverity.warning,
        category: category,
        file: 'pubspec.yaml',
        line: 1,
        impact:
            'Skipping use cases increases coupling between UI and data details, making testing and evolution harder.',
        recommendation:
            'Introduce a domain use case layer (for example `domain/use_cases/*`) and route feature flows through use cases.',
        documentationUrl: 'https://github.com/vyraxsoft/vyrax',
      ),
    ];
  }
}

/// Detects imports from data layer directly inside presentation code.
final class PresentationDependsOnDataLayerRule implements VyraxRule {
  /// Creates a [PresentationDependsOnDataLayerRule].
  const PresentationDependsOnDataLayerRule();

  @override
  String get id => 'VYX009';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.architecture;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);
    final presentationPath = RegExp(r'(^|/)(presentation|ui|view[s]?)(/|$)');
    final dataImport = RegExp(
      r'''import\s+['"][^'"]*(/|package:[^/]+/).*data/[^'"]*['"];''',
    );

    for (final file in files) {
      if (!presentationPath.hasMatch(file.path)) {
        continue;
      }

      final source = file.readAsStringSync();
      final match = dataImport.firstMatch(source);
      if (match == null) {
        continue;
      }

      final line = lineFromOffset(source, match.start);
      issues.add(
        VyraxIssue(
          id: id,
          title: 'Presentation depends on data layer',
          description:
              'Detected a presentation file importing directly from a data layer path.',
          severity: VyraxSeverity.warning,
          category: category,
          file: relativePath(context.projectPath, file.path),
          line: line,
          impact:
              'UI becomes coupled to infrastructure details, which increases mocking friction and regression risk.',
          recommendation:
              'Depend on domain abstractions/use cases from presentation and keep data access behind repositories/adapters.',
          documentationUrl: 'https://github.com/vyraxsoft/vyrax',
        ),
      );
    }

    return issues;
  }
}

/// Detects projects that appear to miss internationalization setup.
final class MissingInternationalizationRule implements VyraxRule {
  /// Creates a [MissingInternationalizationRule].
  const MissingInternationalizationRule();

  @override
  String get id => 'VYX012';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.architecture;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final files = collectDartFiles(context.projectPath);
    final hasL10nArtifacts = files.any((file) {
      final path = file.path;
      return path.contains('/l10n/') ||
          path.endsWith('/app_localizations.dart') ||
          path.endsWith('/generated/l10n.dart');
    });

    final rootPubspec = _readRootPubspec(context.projectPath);
    final hasFlutterLocalizations = rootPubspec.contains(
      'flutter_localizations:',
    );
    final hasIntlPackage = rootPubspec.contains('intl:');
    final hasGenerateFlag = rootPubspec.contains('generate: true');

    if (hasL10nArtifacts ||
        hasFlutterLocalizations ||
        hasIntlPackage ||
        hasGenerateFlag) {
      return const <VyraxIssue>[];
    }

    return <VyraxIssue>[
      VyraxIssue(
        id: id,
        title: 'Internationalization not detected',
        description:
            'No i18n setup was detected (l10n files, flutter_localizations, or intl references).',
        severity: VyraxSeverity.info,
        category: category,
        file: 'pubspec.yaml',
        line: 1,
        impact:
            'Lack of internationalization can limit market reach and delay localization work when the app grows.',
        recommendation:
            'Enable Flutter localization (`flutter_localizations`, `generate: true`) and move user-visible strings to l10n resources.',
        documentationUrl: 'https://github.com/vyraxsoft/vyrax',
      ),
    ];
  }
}

/// Detects user-facing string literals hardcoded in UI code.
final class HardcodedUiTextRule implements VyraxRule {
  /// Creates a [HardcodedUiTextRule].
  const HardcodedUiTextRule();

  @override
  String get id => 'VYX015';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.architecture;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);
    final presentationPath = RegExp(
      r'(^|/)(presentation|ui|view[s]?|screen[s]?|widget[s]?)(/|$)',
    );
    final hardcodedText = RegExp(
      r'''\b(Text|SelectableText|SnackBar|Tooltip|AppBar)\s*\([\s\S]{0,120}?['"][A-Za-z][^'"]{2,}['"]''',
    );
    final localizedMarkers = RegExp(r'AppLocalizations|\.tr\b|S\.of\(');

    for (final file in files) {
      if (!presentationPath.hasMatch(file.path)) {
        continue;
      }

      final source = file.readAsStringSync();
      if (localizedMarkers.hasMatch(source)) {
        continue;
      }

      for (final match in hardcodedText.allMatches(source)) {
        final line = lineFromOffset(source, match.start);
        issues.add(
          VyraxIssue(
            id: id,
            title: 'Hardcoded user-facing text',
            description:
                'Detected a user-facing string literal directly in UI code.',
            severity: VyraxSeverity.info,
            category: category,
            file: relativePath(context.projectPath, file.path),
            line: line,
            impact:
                'Hardcoded text increases localization cost and makes copy changes harder to manage.',
            recommendation:
                'Move user-facing strings to localization resources (l10n/intl) and reference them from UI.',
            documentationUrl: 'https://github.com/vyraxsoft/vyrax',
          ),
        );
      }
    }

    return issues;
  }
}

/// Detects repeated numeric literals that should be extracted as constants.
final class RepeatedMagicNumbersRule implements VyraxRule {
  /// Creates a [RepeatedMagicNumbersRule].
  const RepeatedMagicNumbersRule();

  @override
  String get id => 'VYX016';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.architecture;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);
    final numberPattern = RegExp(
      r'(?<![A-Za-z0-9_])(\d{2,}|\d+\.\d+)(?![A-Za-z0-9_])',
    );
    const excluded = <String>{'0', '1', '2', '100', '200', '404', '500'};

    for (final file in files) {
      final source = file.readAsStringSync();
      final counts = <String, int>{};

      for (final match in numberPattern.allMatches(source)) {
        final value = match.group(1);
        if (value == null || excluded.contains(value)) {
          continue;
        }

        final before = source.substring(0, match.start);
        final inConst = before.contains(
          RegExp(r'const\s+[A-Za-z0-9_<>, ?]+\s+[A-Z_]+\s*=\s*$'),
        );
        if (inConst) {
          continue;
        }

        counts[value] = (counts[value] ?? 0) + 1;
      }

      final repeated = counts.entries
          .where((entry) => entry.value >= 3)
          .toList(growable: false);
      if (repeated.isEmpty) {
        continue;
      }

      final targetValue = repeated.first.key;
      final firstMatch = numberPattern
          .allMatches(source)
          .firstWhere((match) => match.group(1) == targetValue);
      final line = lineFromOffset(source, firstMatch.start);

      issues.add(
        VyraxIssue(
          id: id,
          title: 'Repeated magic numbers',
          description:
              'Numeric literal `$targetValue` appears ${repeated.first.value} times in the same file.',
          severity: VyraxSeverity.info,
          category: category,
          file: relativePath(context.projectPath, file.path),
          line: line,
          impact:
              'Repeated literals can obscure intent and make tuning/design updates more error-prone.',
          recommendation:
              'Extract repeated numeric values into named constants to improve readability and maintainability.',
          documentationUrl: 'https://github.com/vyraxsoft/vyrax',
        ),
      );
    }

    return issues;
  }
}

/// Detects files that exceed the configured line-count threshold.
final class LargeFileRule implements VyraxRule {
  /// Creates a [LargeFileRule].
  const LargeFileRule();

  @override
  String get id => 'VYX017';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.architecture;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final maxLines = _configuredMaxLinesPerFile(context.configuration.values);
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);

    for (final file in files) {
      final source = file.readAsStringSync();
      final lineCount = '\n'.allMatches(source).length + 1;
      if (lineCount <= maxLines) {
        continue;
      }

      final isUiFile = RegExp(
        r'(^|/)(presentation|ui|view[s]?|screen[s]?|widget[s]?)(/|$)',
      ).hasMatch(file.path);
      final recommendation = isUiFile
          ? 'Split this screen into smaller widgets and extract independent widget classes where possible.'
          : 'Split this file into smaller modules, helpers, or classes to improve readability and testability.';

      issues.add(
        VyraxIssue(
          id: id,
          title: 'File too large',
          description:
              'File exceeds the configured maximum of $maxLines lines (actual: $lineCount).',
          severity: VyraxSeverity.warning,
          category: category,
          file: relativePath(context.projectPath, file.path),
          line: 1,
          impact:
              'Large files are harder to review, reason about, and test, and often hide multiple responsibilities.',
          recommendation: recommendation,
          documentationUrl: 'https://github.com/vyraxsoft/vyrax',
        ),
      );
    }

    return issues;
  }
}

String? _configuredArchitecture(Map<String, Object?> values) {
  final architecture = values['architecture'];
  if (architecture is! Map<String, Object?>) {
    return null;
  }
  final type = architecture['type'];
  if (type is! String) {
    return null;
  }
  return type.toLowerCase();
}

String _readRootPubspec(String projectPath) {
  final file = File('$projectPath/pubspec.yaml');
  try {
    return file.readAsStringSync();
  } catch (_) {
    return '';
  }
}

int _configuredMaxLinesPerFile(Map<String, Object?> values) {
  final limits = values['limits'];
  if (limits is Map<String, Object?>) {
    final configured = limits['max_lines_per_file'];
    if (configured is int && configured > 0) {
      return configured;
    }
    if (configured is String) {
      final parsed = int.tryParse(configured);
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
  }

  return 300;
}
