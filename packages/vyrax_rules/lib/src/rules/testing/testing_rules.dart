import 'package:vyrax_core/vyrax_core.dart';
import 'package:vyrax_rules/src/rule_helpers.dart';

/// Detects direct use of infrastructure packages in presentation code.
final class DirectExternalPackageInPresentationRule implements VyraxRule {
  /// Creates a [DirectExternalPackageInPresentationRule].
  const DirectExternalPackageInPresentationRule();

  @override
  String get id => 'VYX010';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.testing;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);
    final presentationPath = RegExp(
      r'(^|/)(presentation|ui|view[s]?|screen[s]?)(/|$)',
    );
    final riskyImports = RegExp(
      r'''import\s+['"]package:(dio|http|firebase_[a-z_]+|shared_preferences|sqflite|geolocator|camera|permission_handler|connectivity_plus|device_info_plus|url_launcher|package_info_plus)/[^'"]*['"];''',
    );

    for (final file in files) {
      if (!presentationPath.hasMatch(file.path)) {
        continue;
      }

      final source = file.readAsStringSync();
      final match = riskyImports.firstMatch(source);
      if (match == null) {
        continue;
      }

      final pkg = match.group(1) ?? 'external package';
      final line = lineFromOffset(source, match.start);
      issues.add(
        VyraxIssue(
          id: id,
          title: 'External package used directly in presentation',
          description:
              'Presentation layer imports `$pkg` directly instead of using a handler/adapter.',
          severity: VyraxSeverity.warning,
          category: category,
          file: relativePath(context.projectPath, file.path),
          line: line,
          impact:
              'Direct framework/package coupling makes widgets harder to unit test and replace over time.',
          recommendation:
              'Introduce a handler/service abstraction in domain or data layer and inject it into presentation.',
          documentationUrl: 'https://github.com/vyraxsoft/vyrax',
        ),
      );
    }

    return issues;
  }
}

/// Detects singleton patterns that can hurt test isolation.
final class SingletonOveruseRule implements VyraxRule {
  /// Creates a [SingletonOveruseRule].
  const SingletonOveruseRule();

  @override
  String get id => 'VYX011';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.testing;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);
    final singletonPattern = RegExp(
      r'static\s+final\s+[A-Z][A-Za-z0-9_]*\s+_[a-zA-Z0-9_]*\s*=\s*[A-Z][A-Za-z0-9_]*\._\s*\(|factory\s+[A-Z][A-Za-z0-9_]*\s*\([^)]*\)\s*=>\s*_[a-zA-Z0-9_]*\s*;',
      multiLine: true,
    );

    for (final file in files) {
      final source = file.readAsStringSync();
      final match = singletonPattern.firstMatch(source);
      if (match == null) {
        continue;
      }

      final line = lineFromOffset(source, match.start);
      issues.add(
        VyraxIssue(
          id: id,
          title: 'Singleton overuse risk',
          description:
              'Detected a singleton-style implementation that can leak shared state across tests.',
          severity: VyraxSeverity.warning,
          category: category,
          file: relativePath(context.projectPath, file.path),
          line: line,
          impact:
              'Global mutable state often reduces test isolation and increases hidden coupling.',
          recommendation:
              'Prefer dependency injection with scoped lifetimes; keep singleton usage minimal and explicit.',
          documentationUrl: 'https://github.com/vyraxsoft/vyrax',
        ),
      );
    }

    return issues;
  }
}

/// Detects error-like models that miss a factory or mapper constructor.
final class ErrorModelWithoutFactoryRule implements VyraxRule {
  /// Creates an [ErrorModelWithoutFactoryRule].
  const ErrorModelWithoutFactoryRule();

  @override
  String get id => 'VYX014';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.testing;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);
    final classPattern = RegExp(
      r'class\s+([A-Z][A-Za-z0-9_]*(Error|Failure|Exception))\b[^\{]*\{',
    );

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final match in classPattern.allMatches(source)) {
        final className = match.group(1);
        if (className == null) {
          continue;
        }

        final openBrace = source.indexOf('{', match.start);
        final closeBrace = _matchBraceInSource(source, openBrace);
        if (openBrace == -1 || closeBrace == -1) {
          continue;
        }

        final body = source.substring(openBrace + 1, closeBrace);
        final fieldCount = RegExp(
          r'\bfinal\s+[A-Za-z0-9_<>, ?]+\s+[a-zA-Z_][A-Za-z0-9_]*\s*;',
        ).allMatches(body).length;
        if (fieldCount < 2) {
          continue;
        }

        final hasFactory = RegExp(
          'factory\\s+$className\\s*(\\.|\\()',
        ).hasMatch(body);
        final hasMapper = RegExp(
          'static\\s+$className\\s+from[A-Z][A-Za-z0-9_]*\\s*\\(',
        ).hasMatch(body);
        if (hasFactory || hasMapper) {
          continue;
        }

        final line = lineFromOffset(source, match.start);
        issues.add(
          VyraxIssue(
            id: id,
            title: 'Error model without factory mapper',
            description:
                'Detected `$className` with multiple fields but no factory/static mapper constructor.',
            severity: VyraxSeverity.warning,
            category: category,
            file: relativePath(context.projectPath, file.path),
            line: line,
            impact:
                'Without a centralized mapper/factory, translating exceptions to domain errors becomes inconsistent and harder to test.',
            recommendation:
                'Add a factory or static mapper (for example `fromException`, `fromCode`) to standardize error construction.',
            documentationUrl: 'https://github.com/vyraxsoft/vyrax',
          ),
        );
      }
    }

    return issues;
  }
}

int _matchBraceInSource(String source, int openIndex) {
  if (openIndex < 0 || openIndex >= source.length) {
    return -1;
  }

  var depth = 0;
  for (var i = openIndex; i < source.length; i++) {
    final char = source.codeUnitAt(i);
    if (char == 123) {
      depth++;
    } else if (char == 125) {
      depth--;
      if (depth == 0) {
        return i;
      }
    }
  }
  return -1;
}
