import 'dart:io';

/// Collects all Dart files inside a project, skipping generated/build folders.
List<File> collectDartFiles(String projectPath) {
  final root = Directory(projectPath);
  if (!root.existsSync()) {
    return const [];
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
      .toList(growable: false);
}

/// Collects method bodies that look like Flutter `build` blocks.
Iterable<BuildBlock> collectBuildBlocks(String source) sync* {
  final pattern = RegExp(r'build\s*\([^)]*\)\s*\{');
  for (final match in pattern.allMatches(source)) {
    final openBrace = source.indexOf('{', match.start);
    if (openBrace == -1) {
      continue;
    }

    final closeBrace = _matchingBrace(source, openBrace);
    if (closeBrace == -1) {
      continue;
    }

    final block = source.substring(openBrace + 1, closeBrace);
    yield BuildBlock(content: block, startOffset: openBrace + 1);
  }
}

/// Returns the 1-based line number for a character offset.
int lineFromOffset(String source, int offset) {
  var line = 1;
  for (var i = 0; i < source.length && i < offset; i++) {
    if (source.codeUnitAt(i) == 10) {
      line++;
    }
  }
  return line;
}

/// Returns a path relative to [projectPath] when possible.
String relativePath(String projectPath, String absolutePath) {
  final normalizedRoot = projectPath.endsWith('/')
      ? projectPath
      : '$projectPath/';
  if (absolutePath.startsWith(normalizedRoot)) {
    return absolutePath.substring(normalizedRoot.length);
  }
  return absolutePath;
}

int _matchingBrace(String source, int openIndex) {
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

/// Represents a parsed `build` block and its source offset.
final class BuildBlock {
  /// Creates a [BuildBlock].
  const BuildBlock({required this.content, required this.startOffset});

  /// Source content of the build block.
  final String content;

  /// Start offset of [content] within the full source.
  final int startOffset;
}
