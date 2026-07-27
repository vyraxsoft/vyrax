import 'package:vyrax_core/vyrax_core.dart';
import 'package:vyrax_rules/src/rule_helpers.dart';

final class WidgetLifecycleRule implements VyraxRule {
  const WidgetLifecycleRule();

  @override
  String get id => 'VYX022';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.state;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);
    final stateClassPattern = RegExp(
      r'class\s+([A-Z][A-Za-z0-9_]*)\s+extends\s+State<[^>]+>\s*\{',
      multiLine: true,
    );

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final match in stateClassPattern.allMatches(source)) {
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
        final reasons = <String>[];

        final initStateBody = _methodBody(body, 'initState');
        if (initStateBody != null) {
          final asyncLifecyclePattern = RegExp(
            r'\bawait\b|\bFuture\.delayed\b|\.then\s*\(',
          );
          if (asyncLifecyclePattern.hasMatch(initStateBody)) {
            reasons.add('initState is doing async work');
          }
        }

        final resourcePattern = RegExp(
          r'\b(?:TextEditingController|AnimationController|ScrollController|PageController|TabController|FocusNode|StreamSubscription(?:<[^>]+>)?|Timer|ValueNotifier(?:<[^>]+>)?)\b',
        );
        final hasResources = resourcePattern.hasMatch(body);
        if (hasResources) {
          final disposeBody = _methodBody(body, 'dispose');
          final hasCleanup =
              disposeBody != null &&
              RegExp(
                r'\.(?:dispose|cancel|removeListener)\s*\(',
              ).hasMatch(disposeBody);
          if (!hasCleanup) {
            reasons.add('state owns disposable resources without cleanup');
          }
        }

        if (reasons.isEmpty) {
          continue;
        }

        final line = lineFromOffset(source, match.start);
        issues.add(
          VyraxIssue(
            id: id,
            title: 'Widget lifecycle misuse',
            description:
                'State class `$className` appears to violate lifecycle expectations: ${reasons.join(' and ')}.',
            severity: VyraxSeverity.warning,
            category: category,
            file: relativePath(context.projectPath, file.path),
            line: line,
            impact:
                'Lifecycle mistakes can leak resources, make rebuild timing unpredictable, and create flaky behavior.',
            recommendation:
                'Keep initState synchronous, move async work to a separate method or post-frame callback, and dispose controllers/subscriptions when the State is removed.',
            documentationUrl: 'https://github.com/vyraxsoft/vyrax',
          ),
        );
      }
    }

    return issues;
  }
}

String? _methodBody(String source, String methodName) {
  final pattern = RegExp(
    '(?m)^\\s*(?:@override\\s+)?(?:[A-Za-z0-9_<>, ?]+\\s+)?$methodName\\s*\\([^\\)]*\\)\\s*(?:async\\s*)?\\{',
  );
  final match = pattern.firstMatch(source);
  if (match == null) {
    return null;
  }

  final openBrace = source.indexOf('{', match.start);
  final closeBrace = _matchBraceInSource(source, openBrace);
  if (openBrace == -1 || closeBrace == -1) {
    return null;
  }

  return source.substring(openBrace + 1, closeBrace);
}

int _matchBraceInSource(String source, int openIndex) {
  if (openIndex < 0 || openIndex >= source.length) {
    return -1;
  }

  var depth = 0;
  for (var index = openIndex; index < source.length; index++) {
    final char = source.codeUnitAt(index);
    if (char == 123) {
      depth++;
    } else if (char == 125) {
      depth--;
      if (depth == 0) {
        return index;
      }
    }
  }

  return -1;
}
