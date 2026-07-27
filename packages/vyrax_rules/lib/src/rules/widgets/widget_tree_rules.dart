import 'package:vyrax_core/vyrax_core.dart';
import 'package:vyrax_rules/src/rule_helpers.dart';

/// Detects deep or wrapper-heavy widget subtrees in `build` methods.
final class WidgetTreeComplexityRule implements VyraxRule {
  /// Creates a [WidgetTreeComplexityRule].
  const WidgetTreeComplexityRule();

  @override
  String get id => 'VYX023';

  @override
  VyraxIssueCategory get category => VyraxIssueCategory.widgets;

  @override
  Future<List<VyraxIssue>> evaluate(VyraxRuleContext context) async {
    final issues = <VyraxIssue>[];
    final files = collectDartFiles(context.projectPath);
    final wrapperPattern = RegExp(
      r'\b(Padding|Center|Align|Container|SizedBox|Expanded|Flexible|ConstrainedBox|DecoratedBox|ClipRRect|AspectRatio|SafeArea|Theme|Material|Builder|Stack|Row|Column|Wrap|Card|Consumer|BlocBuilder|ValueListenableBuilder)\s*\(',
    );
    final widgetPattern = RegExp(r'\b[A-Z][A-Za-z0-9_]*\s*\(');

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final block in collectBuildBlocks(source)) {
        final widgetCount = widgetPattern.allMatches(block.content).length;
        final wrapperCount = wrapperPattern.allMatches(block.content).length;
        final depth = _maxParenDepth(block.content);

        if (widgetCount < 18 && wrapperCount < 6 && depth < 14) {
          continue;
        }

        final line = lineFromOffset(source, block.startOffset);
        issues.add(
          VyraxIssue(
            id: id,
            title: 'Widget tree complexity',
            description:
                'Build subtree is too deep (widgets: $widgetCount, wrappers: $wrapperCount, max depth: $depth).',
            severity: VyraxSeverity.warning,
            category: category,
            file: relativePath(context.projectPath, file.path),
            line: line,
            impact:
                'Deep widget trees are harder to read, and wrapper-heavy layouts often make rebuild reasoning harder.',
            recommendation:
                'Extract leaf widgets, collapse wrapper chains, and split repeated subtrees into dedicated widgets so the tree is flatter and easier to reason about.',
            documentationUrl: 'https://github.com/vyraxsoft/vyrax',
          ),
        );
      }
    }

    return issues;
  }
}

int _maxParenDepth(String source) {
  var depth = 0;
  var maxDepth = 0;
  var inSingleQuote = false;
  var inDoubleQuote = false;
  var escaped = false;

  for (var index = 0; index < source.length; index++) {
    final char = source.codeUnitAt(index);

    if (escaped) {
      escaped = false;
      continue;
    }

    if (char == 92) {
      escaped = true;
      continue;
    }

    if (inSingleQuote) {
      if (char == 39) {
        inSingleQuote = false;
      }
      continue;
    }

    if (inDoubleQuote) {
      if (char == 34) {
        inDoubleQuote = false;
      }
      continue;
    }

    if (char == 39) {
      inSingleQuote = true;
      continue;
    }

    if (char == 34) {
      inDoubleQuote = true;
      continue;
    }

    if (char == 40) {
      depth++;
      if (depth > maxDepth) {
        maxDepth = depth;
      }
    } else if (char == 41 && depth > 0) {
      depth--;
    }
  }

  return maxDepth;
}
