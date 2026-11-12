// Fails loudly (exit code 1) when any gameplay word repeats anywhere across
// the four games, or when a level dataset is structurally invalid.
//
// Usage (from the project root):
//   dart run tool/validate_vocabulary.dart
import 'dart:io';

import 'vocabulary_audit.dart';

void main(List<String> args) {
  final root = args.isNotEmpty ? args.first : '.';
  final result = runVocabularyAudit(root: root);
  stdout.write(result.report());
  if (!result.passed) {
    stderr.writeln('Vocabulary audit FAILED.');
    exitCode = 1;
  }
}
