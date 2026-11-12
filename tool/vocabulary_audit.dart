// Global vocabulary audit for all four games (Main Word Adventure, Mini
// Crossword, Word Riddles, Word Search).
//
// Pure Dart (no Flutter imports) so it can run both as a CLI:
//   dart run tool/validate_vocabulary.dart
// and inside `flutter test` (see test/global_vocabulary_test.dart).
import 'dart:convert';
import 'dart:io';

class VocabEntry {
  final String raw;
  final String word; // normalized
  final String mode;
  final int level;
  final String type;

  VocabEntry(this.raw, this.mode, this.level, this.type) : word = normalizeWord(raw);

  @override
  String toString() => '$mode Level $level ($type)';
}

class VocabularyAuditResult {
  final List<VocabEntry> entries = [];
  final Map<String, int> counts = {};
  final Map<String, int> levelCounts = {};

  /// normalized word -> every place it is used (only words used more than once)
  final Map<String, List<VocabEntry>> duplicates = {};

  /// "PLAN / PLANS" style overlaps between two different gameplay words
  final List<String> relatedForms = [];

  final List<String> mainErrors = [];
  final List<String> crosswordErrors = [];
  final List<String> riddleErrors = [];
  final List<String> wordSearchErrors = [];
  final List<String> fallbackErrors = [];
  final List<String> dailyNotes = [];

  int get uniqueWords => entries.map((e) => e.word).toSet().length;

  bool get passed =>
      duplicates.isEmpty &&
      relatedForms.isEmpty &&
      mainErrors.isEmpty &&
      crosswordErrors.isEmpty &&
      riddleErrors.isEmpty &&
      wordSearchErrors.isEmpty &&
      fallbackErrors.isEmpty;

  String report() {
    final b = StringBuffer();
    void section(String title, List<String> errors) {
      if (errors.isEmpty) return;
      b.writeln('');
      b.writeln('$title (${errors.length})');
      for (final e in errors) {
        b.writeln('  - $e');
      }
    }

    b.writeln('GLOBAL VOCABULARY AUDIT');
    b.writeln('-----------------------');
    b.writeln('Main Game levels:    ${levelCounts['main'] ?? 0}');
    b.writeln('Crossword levels:    ${levelCounts['crossword'] ?? 0}');
    b.writeln('Riddle levels:       ${levelCounts['riddle'] ?? 0}');
    b.writeln('Word Search levels:  ${levelCounts['wordsearch'] ?? 0}');
    b.writeln('');
    b.writeln('Main Game words:     ${counts['main'] ?? 0}');
    b.writeln('Crossword answers:   ${counts['crossword'] ?? 0}');
    b.writeln('Riddle answers:      ${counts['riddle'] ?? 0}');
    b.writeln('Word Search targets: ${counts['wordsearch'] ?? 0}');
    b.writeln('Runtime fallbacks:   ${counts['fallback'] ?? 0}');
    b.writeln('');
    b.writeln('Total gameplay words:     ${entries.length}');
    b.writeln('Unique gameplay words:    $uniqueWords');
    b.writeln('Duplicate gameplay words: ${duplicates.length}');
    b.writeln('Related-form overlaps:    ${relatedForms.length}');

    for (final e in duplicates.entries) {
      b.writeln('');
      b.writeln('DUPLICATE WORD:');
      b.writeln(e.key);
      b.writeln('Found in:');
      for (final where in e.value) {
        b.writeln('- $where');
      }
    }
    section('RELATED FORMS OF THE SAME WORD', relatedForms);
    section('INVALID MAIN GAME VOCABULARY', mainErrors);
    section('INVALID CROSSWORD DATA', crosswordErrors);
    section('INVALID RIDDLE DATA', riddleErrors);
    section('INVALID WORD SEARCH DATA', wordSearchErrors);
    section('RUNTIME FALLBACK PROBLEMS', fallbackErrors);

    b.writeln('');
    b.writeln('Main Game:   ${mainErrors.isEmpty ? 'PASS' : 'FAIL'}');
    b.writeln('Crossword:   ${crosswordErrors.isEmpty ? 'PASS' : 'FAIL'}');
    b.writeln('Riddles:     ${riddleErrors.isEmpty ? 'PASS' : 'FAIL'}');
    b.writeln('Word Search: ${wordSearchErrors.isEmpty ? 'PASS' : 'FAIL'}');
    b.writeln('Fallbacks:   ${fallbackErrors.isEmpty ? 'PASS' : 'FAIL'}');
    if (dailyNotes.isNotEmpty) {
      b.writeln('');
      b.writeln('Daily Challenge (separate recurring pool, informational only):');
      for (final n in dailyNotes) {
        b.writeln('  $n');
      }
    }
    b.writeln('');
    b.writeln('DUPLICATES FOUND: ${duplicates.length + relatedForms.length}');
    b.writeln('RESULT: ${passed ? 'PASS' : 'FAIL'}');
    return b.toString();
  }
}

/// Canonical form used for every comparison: upper-case, letters only.
/// "Apple", "APPLE", " apple " and "ice-cream" / "ICE CREAM" all collapse.
String normalizeWord(String raw) => raw.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');

/// One-step base forms of [w] (plural / past / -ing). Used to catch a second
/// level that reuses the same vocabulary item in a different inflection.
Set<String> candidateStems(String w) {
  final out = <String>{};
  final n = w.length;
  void add(String s) {
    if (s.length >= 3) out.add(s);
  }

  if (w.endsWith('S') && !w.endsWith('SS')) add(w.substring(0, n - 1));
  if (w.endsWith('ES')) add(w.substring(0, n - 2));
  if (w.endsWith('IES')) add('${w.substring(0, n - 3)}Y');
  if (w.endsWith('ED')) {
    add(w.substring(0, n - 2));
    add(w.substring(0, n - 1));
    if (n >= 5 && w[n - 3] == w[n - 4]) add(w.substring(0, n - 3));
  }
  if (w.endsWith('IED')) add('${w.substring(0, n - 3)}Y');
  if (w.endsWith('ING')) {
    add(w.substring(0, n - 3));
    add('${w.substring(0, n - 3)}E');
    if (n >= 6 && w[n - 4] == w[n - 5]) add(w.substring(0, n - 4));
  }
  return out;
}

const Map<String, List<int>> wordSearchDirections = {
  'up_left': [-1, -1],
  'up': [-1, 0],
  'up_right': [-1, 1],
  'left': [0, -1],
  'right': [0, 1],
  'down_left': [1, -1],
  'down': [1, 0],
  'down_right': [1, 1],
};

List<dynamic> _levels(String root, String name) {
  final file = File('$root/assets/$name');
  if (!file.existsSync()) {
    throw StateError('Missing dataset: ${file.path}');
  }
  return (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)['levels'] as List<dynamic>;
}

bool _canForm(String word, String letters) {
  final counts = <String, int>{};
  for (final c in letters.split('')) {
    counts[c] = (counts[c] ?? 0) + 1;
  }
  for (final c in word.split('')) {
    final left = (counts[c] ?? 0) - 1;
    if (left < 0) return false;
    counts[c] = left;
  }
  return true;
}

final RegExp _lettersOnly = RegExp(r'^[A-Z]+$');

VocabularyAuditResult runVocabularyAudit({String root = '.'}) {
  final r = VocabularyAuditResult();

  void add(String raw, String mode, int level, String type) {
    r.entries.add(VocabEntry(raw, mode, level, type));
    r.counts[mode] = (r.counts[mode] ?? 0) + 1;
  }

  // ───────────────────────── MAIN GAME ─────────────────────────
  final main = _levels(root, 'word_wheel_300_levels.json');
  r.levelCounts['main'] = main.length;
  final Map<int, List<String>> mainByLevel = {};
  for (int i = 0; i < main.length; i++) {
    final l = main[i] as Map<String, dynamic>;
    final int level = l['level'] as int;
    final String tag = 'Level $level';
    if (level != i + 1) r.mainErrors.add('$tag: expected level number ${i + 1}');
    final String mainWord = (l['main_word'] as String).toUpperCase();
    final String letters = (l['letters'] as List<dynamic>).join('').toUpperCase();
    final List<String> words =
        (l['words_to_make'] as List<dynamic>).map((e) => e.toString().toUpperCase()).toList();
    mainByLevel[level] = words;
    if (letters != mainWord) r.mainErrors.add('$tag: letters "$letters" do not spell main word "$mainWord"');
    if (words.isEmpty || words.first != mainWord) r.mainErrors.add('$tag: main word must be the first word to make');
    if (l['word_count'] != words.length) r.mainErrors.add('$tag: word_count ${l['word_count']} != ${words.length}');
    final lengths = (l['word_lengths'] as List<dynamic>).map((e) => e as int).toList();
    if (lengths.length != words.length) {
      r.mainErrors.add('$tag: word_lengths has ${lengths.length} entries for ${words.length} words');
    }
    if (words.toSet().length != words.length) r.mainErrors.add('$tag: a word is listed twice in the same level');
    for (int k = 0; k < words.length; k++) {
      final w = words[k];
      if (!_lettersOnly.hasMatch(w)) r.mainErrors.add('$tag: "$w" contains non-letter characters');
      if (w.length < 3) r.mainErrors.add('$tag: "$w" is shorter than 3 letters');
      if (!_canForm(w, letters)) r.mainErrors.add('$tag: "$w" cannot be formed from "$letters"');
      if (k < lengths.length && lengths[k] != w.length) r.mainErrors.add('$tag: word_lengths mismatch for "$w"');
      add(w, 'main', level, w == mainWord ? 'main word' : 'required');
    }
    for (final b in (l['bonus_words'] as List<dynamic>? ?? const [])) {
      final w = b.toString().toUpperCase();
      if (!_canForm(w, letters)) r.mainErrors.add('$tag: bonus "$w" cannot be formed from "$letters"');
      add(w, 'main', level, 'bonus');
    }
    if (l['hard_word'] != null) {
      final w = l['hard_word'].toString().toUpperCase();
      if (!_canForm(w, letters)) r.mainErrors.add('$tag: hard word "$w" cannot be formed from "$letters"');
      if (!words.contains(w)) add(w, 'main', level, 'hard');
    }
  }

  // ───────────────────────── CROSSWORD ─────────────────────────
  final crosswords = _levels(root, 'crossword_50_levels.json');
  r.levelCounts['crossword'] = crosswords.length;
  for (int i = 0; i < crosswords.length; i++) {
    final l = crosswords[i] as Map<String, dynamic>;
    final int level = l['level'] as int;
    final String tag = 'Level $level';
    if (level != i + 1) r.crosswordErrors.add('$tag: expected level number ${i + 1}');
    final int rows = l['rows'] as int;
    final int cols = l['cols'] as int;
    final List<String> grid = (l['grid'] as List<dynamic>).map((e) => e.toString()).toList();
    final List<String> sol = (l['solution'] as List<dynamic>).map((e) => e.toString()).toList();
    if (grid.length != rows || sol.length != rows || grid.any((x) => x.length != cols) || sol.any((x) => x.length != cols)) {
      r.crosswordErrors.add('$tag: grid/solution size does not match ${rows}x$cols');
      continue;
    }
    final Set<String> covered = {};
    final Set<String> declared = {};
    final Set<String> numberDirs = {};
    for (final wRaw in l['words'] as List<dynamic>) {
      final w = wRaw as Map<String, dynamic>;
      final String answer = (w['answer'] as String).toUpperCase();
      final String dir = (w['direction'] as String).toLowerCase();
      final int row = w['row'] as int;
      final int col = w['col'] as int;
      final String clue = (w['clue'] as String? ?? '').trim();
      add(answer, 'crossword', level, 'crossword answer');
      if (!_lettersOnly.hasMatch(answer)) r.crosswordErrors.add('$tag: answer "$answer" has non-letter characters');
      if (dir != 'across' && dir != 'down') {
        r.crosswordErrors.add('$tag: "$answer" has invalid direction "$dir"');
        continue;
      }
      if (w['length'] != answer.length) r.crosswordErrors.add('$tag: "$answer" length field is ${w['length']}');
      if (clue.isEmpty) r.crosswordErrors.add('$tag: "$answer" has no clue');
      if (normalizeWord(clue).contains(answer)) r.crosswordErrors.add('$tag: clue for "$answer" gives the answer away');
      if (!numberDirs.add('${w['number']}-$dir')) r.crosswordErrors.add('$tag: duplicate clue number ${w['number']} $dir');
      final int dr = dir == 'down' ? 1 : 0;
      final int dc = dir == 'across' ? 1 : 0;
      final int endR = row + dr * (answer.length - 1);
      final int endC = col + dc * (answer.length - 1);
      if (row < 0 || col < 0 || endR >= rows || endC >= cols) {
        r.crosswordErrors.add('$tag: "$answer" does not fit in the grid at [$row,$col] $dir');
        continue;
      }
      for (int k = 0; k < answer.length; k++) {
        final int rr = row + dr * k;
        final int cc = col + dc * k;
        if (sol[rr][cc] != answer[k]) {
          r.crosswordErrors.add('$tag: "$answer" letter ${k + 1} conflicts with solution cell [$rr,$cc] "${sol[rr][cc]}"');
        }
        covered.add('$rr,$cc');
      }
      // a declared word must be a complete run (blocked or edge on both sides)
      final int br = row - dr, bc = col - dc, ar = endR + dr, ac = endC + dc;
      if (br >= 0 && bc >= 0 && sol[br][bc] != '#') r.crosswordErrors.add('$tag: "$answer" is preceded by an open cell');
      if (ar < rows && ac < cols && sol[ar][ac] != '#') r.crosswordErrors.add('$tag: "$answer" is followed by an open cell');
      declared.add('$row,$col,$dir,${answer.length}');
    }
    for (int rr = 0; rr < rows; rr++) {
      for (int cc = 0; cc < cols; cc++) {
        final String s = sol[rr][cc];
        final String g = grid[rr][cc];
        if (s == '#') {
          if (g != '#') r.crosswordErrors.add('$tag: grid cell [$rr,$cc] should be blocked');
          continue;
        }
        if (!_lettersOnly.hasMatch(s)) r.crosswordErrors.add('$tag: solution cell [$rr,$cc] is "$s"');
        if (!covered.contains('$rr,$cc')) r.crosswordErrors.add('$tag: solution cell [$rr,$cc] belongs to no answer');
        if (g != '_' && g != s) r.crosswordErrors.add('$tag: prefilled letter "$g" at [$rr,$cc] should be "$s"');
        // every run of 2+ letters must be a declared answer (no accidental words)
        final bool startAcross = (cc == 0 || sol[rr][cc - 1] == '#') && cc + 1 < cols && sol[rr][cc + 1] != '#';
        if (startAcross) {
          int len = 0;
          while (cc + len < cols && sol[rr][cc + len] != '#') {
            len++;
          }
          if (!declared.contains('$rr,$cc,across,$len')) {
            r.crosswordErrors.add('$tag: undeclared across run "${sol[rr].substring(cc, cc + len)}" at [$rr,$cc]');
          }
        }
        final bool startDown = (rr == 0 || sol[rr - 1][cc] == '#') && rr + 1 < rows && sol[rr + 1][cc] != '#';
        if (startDown) {
          int len = 0;
          final sb = StringBuffer();
          while (rr + len < rows && sol[rr + len][cc] != '#') {
            sb.write(sol[rr + len][cc]);
            len++;
          }
          if (!declared.contains('$rr,$cc,down,$len')) {
            r.crosswordErrors.add('$tag: undeclared down run "$sb" at [$rr,$cc]');
          }
        }
      }
    }
  }

  // ───────────────────────── RIDDLES ─────────────────────────
  final riddles = _levels(root, 'word_riddle_50_levels.json');
  r.levelCounts['riddle'] = riddles.length;
  for (int i = 0; i < riddles.length; i++) {
    final l = riddles[i] as Map<String, dynamic>;
    final int level = l['level'] as int;
    final String tag = 'Level $level';
    if (level != i + 1) r.riddleErrors.add('$tag: expected level number ${i + 1}');
    final String answer = (l['answer'] as String? ?? '');
    add(answer, 'riddle', level, 'riddle answer');
    if (normalizeWord(answer).isEmpty) r.riddleErrors.add('$tag: empty answer');
    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(answer)) r.riddleErrors.add('$tag: answer "$answer" has unexpected characters');
    for (final field in ['clue', 'category', 'difficulty', 'hint', 'explanation']) {
      if ((l[field] as String? ?? '').trim().isEmpty) r.riddleErrors.add('$tag: missing $field');
    }
    final String clueNorm = ' ${(l['clue'] as String? ?? '').toUpperCase().replaceAll(RegExp(r'[^A-Z]+'), ' ')} ';
    final String hintNorm = ' ${(l['hint'] as String? ?? '').toUpperCase().replaceAll(RegExp(r'[^A-Z]+'), ' ')} ';
    final String needle = ' ${answer.toUpperCase().trim()} ';
    if (clueNorm.contains(needle)) r.riddleErrors.add('$tag: clue contains the answer "$answer"');
    if (hintNorm.contains(needle)) r.riddleErrors.add('$tag: hint contains the answer "$answer"');
  }

  // ───────────────────────── WORD SEARCH ─────────────────────────
  final searches = _levels(root, 'word_search_50_levels.json');
  r.levelCounts['wordsearch'] = searches.length;
  for (int i = 0; i < searches.length; i++) {
    final l = searches[i] as Map<String, dynamic>;
    final int level = l['level'] as int;
    final String tag = 'Level $level';
    if (level != i + 1) r.wordSearchErrors.add('$tag: expected level number ${i + 1}');
    final int size = l['size'] as int;
    final List<String> board = (l['board'] as List<dynamic>).map((e) => e.toString().toUpperCase()).toList();
    if (board.length != size || board.any((row) => row.length != size || !_lettersOnly.hasMatch(row))) {
      r.wordSearchErrors.add('$tag: board is not a ${size}x$size grid of letters');
      continue;
    }
    int occurrences(String word) {
      int found = 0;
      for (int rr = 0; rr < size; rr++) {
        for (int cc = 0; cc < size; cc++) {
          for (final d in wordSearchDirections.values) {
            final int er = rr + d[0] * (word.length - 1);
            final int ec = cc + d[1] * (word.length - 1);
            if (er < 0 || ec < 0 || er >= size || ec >= size) continue;
            bool ok = true;
            for (int k = 0; k < word.length && ok; k++) {
              ok = board[rr + d[0] * k][cc + d[1] * k] == word[k];
            }
            if (ok) found++;
          }
        }
      }
      return found;
    }

    final List<String> targets = [];
    for (final wRaw in l['words'] as List<dynamic>) {
      final w = wRaw as Map<String, dynamic>;
      final String word = (w['word'] as String).toUpperCase();
      targets.add(word);
      add(word, 'wordsearch', level, 'word-search target');
      if (!_lettersOnly.hasMatch(word)) r.wordSearchErrors.add('$tag: target "$word" has non-letter characters');
      final d = wordSearchDirections[w['direction']];
      if (d == null) {
        r.wordSearchErrors.add('$tag: "$word" has invalid direction "${w['direction']}"');
        continue;
      }
      final start = (w['start'] as List<dynamic>).map((e) => e as int).toList();
      final end = (w['end'] as List<dynamic>).map((e) => e as int).toList();
      final int er = start[0] + d[0] * (word.length - 1);
      final int ec = start[1] + d[1] * (word.length - 1);
      if (start[0] < 0 || start[1] < 0 || start[0] >= size || start[1] >= size || er < 0 || ec < 0 || er >= size || ec >= size) {
        r.wordSearchErrors.add('$tag: "$word" runs outside the board');
        continue;
      }
      if (end[0] != er || end[1] != ec) r.wordSearchErrors.add('$tag: "$word" end $end does not match start/direction [$er, $ec]');
      for (int k = 0; k < word.length; k++) {
        final String cell = board[start[0] + d[0] * k][start[1] + d[1] * k];
        if (cell != word[k]) {
          r.wordSearchErrors.add('$tag: "$word" letter ${k + 1} is "$cell" on the board');
          break;
        }
      }
      final int n = occurrences(word);
      if (n != 1) r.wordSearchErrors.add('$tag: "$word" appears $n times on the board (expected exactly 1)');
    }
    if (targets.toSet().length != targets.length) r.wordSearchErrors.add('$tag: a target is listed twice');
    for (final a in targets) {
      for (final b in targets) {
        if (a != b && b.contains(a)) r.wordSearchErrors.add('$tag: target "$a" is hidden inside target "$b"');
      }
    }
  }

  // ───────────────────────── RUNTIME FALLBACKS (Dart source) ─────────────────────────
  _auditFallbacks(root, r, mainByLevel, add);

  // ───────────────────────── GLOBAL UNIQUENESS ─────────────────────────
  final Map<String, List<VocabEntry>> byWord = {};
  for (final e in r.entries) {
    byWord.putIfAbsent(e.word, () => []).add(e);
  }
  final sortedWords = byWord.keys.toList()..sort();
  for (final w in sortedWords) {
    if (byWord[w]!.length > 1) r.duplicates[w] = byWord[w]!;
  }
  for (final w in sortedWords) {
    for (final stem in candidateStems(w)) {
      if (stem != w && byWord.containsKey(stem)) {
        r.relatedForms.add('$stem (${byWord[stem]!.first}) / $w (${byWord[w]!.first})');
      }
    }
  }

  // ───────────────────────── DAILY CHALLENGE (informational) ─────────────────────────
  try {
    final daily = _levels(root, 'daily_challenge_100_levels.json');
    final List<String> dailyWords = [];
    for (final l in daily) {
      for (final w in (l as Map<String, dynamic>)['words_to_make'] as List<dynamic>) {
        dailyWords.add(normalizeWord(w.toString()));
      }
    }
    final distinct = dailyWords.toSet();
    r.dailyNotes.add('Daily levels: ${daily.length}, word slots: ${dailyWords.length}, distinct words: ${distinct.length}');
    r.dailyNotes.add('Words shared with the four games: ${distinct.where(byWord.containsKey).length}');
    r.dailyNotes.add('The daily set cycles every ${daily.length} days by design, so it is not part of the unique pool.');
  } catch (e) {
    r.dailyNotes.add('Daily dataset could not be read: $e');
  }

  return r;
}

/// The app ships hardcoded data that is used when an asset fails to load.
/// It must never bring old/duplicated vocabulary back at runtime.
void _auditFallbacks(
  String root,
  VocabularyAuditResult r,
  Map<int, List<String>> mainByLevel,
  void Function(String raw, String mode, int level, String type) add,
) {
  String read(String path) {
    final f = File('$root/$path');
    if (!f.existsSync()) {
      r.fallbackErrors.add('Missing source file $path');
      return '';
    }
    return f.readAsStringSync();
  }

  // 1. LevelService.levels must mirror the main dataset exactly.
  final service = read('lib/services/level_service.dart');
  final levelRe = RegExp(
    r'Level\(\s*id: (\d+),\s*theme: "[^"]*",\s*letters: "([A-Z]+)",\s*requiredWords: \[([^\]]*)\],\s*bonusWords: \[([^\]]*)\],\s*hardWord: (null|"[A-Z]+")',
  );
  List<String> list(String body) => RegExp(r'"([A-Z]+)"').allMatches(body).map((m) => m.group(1)!).toList();
  final Set<int> seen = {};
  final Set<String> hardcodedVocabulary = {};
  for (final m in levelRe.allMatches(service)) {
    final int id = int.parse(m.group(1)!);
    seen.add(id);
    final expected = mainByLevel[id];
    final words = {...list(m.group(3)!), ...list(m.group(4)!), if (m.group(5) != 'null') m.group(5)!.replaceAll('"', '')};
    hardcodedVocabulary.addAll(words);
    if (expected == null) {
      r.fallbackErrors.add('LevelService.levels has level $id which is not in the dataset');
      continue;
    }
    if (m.group(2) != expected.first) {
      r.fallbackErrors.add('LevelService.levels level $id letters "${m.group(2)}" != dataset "${expected.first}"');
    }
    if (words.length != expected.toSet().length || !words.containsAll(expected)) {
      r.fallbackErrors.add('LevelService.levels level $id words differ from the dataset');
    }
  }
  for (final id in mainByLevel.keys) {
    if (!seen.contains(id)) r.fallbackErrors.add('LevelService.levels is missing level $id');
  }
  final vocabBlock = RegExp(r'allVocabulary = \[(.*?)\];', dotAll: true).firstMatch(service);
  if (vocabBlock == null) {
    r.fallbackErrors.add('LevelService.allVocabulary not found');
  } else {
    final vocab = list(vocabBlock.group(1)!).toSet();
    final expected = mainByLevel.values.expand((e) => e).toSet();
    if (vocab.length != expected.length || !vocab.containsAll(expected)) {
      r.fallbackErrors.add('LevelService.allVocabulary (${vocab.length}) differs from the main dataset vocabulary (${expected.length})');
    }
  }

  // 2. Single-puzzle fallbacks inside the mini-game screens must be globally unique too.
  void screen(String path, RegExp re, String type) {
    final src = read(path);
    final matches = re.allMatches(src).toList();
    if (src.isNotEmpty && matches.isEmpty) r.fallbackErrors.add('No fallback puzzle found in $path');
    for (final m in matches) {
      add(m.group(1)!, 'fallback', 0, type);
    }
  }

  screen('lib/screens/mini_crossword_screen.dart', RegExp(r'answer:\s*"([A-Za-z ]+)"'), 'crossword screen fallback');
  screen('lib/screens/riddle_screen.dart', RegExp(r'answer:\s*"([A-Za-z ]+)"'), 'riddle screen fallback');
  screen('lib/screens/word_search_screen.dart', RegExp(r'WordSearchWord\(word:\s*"([A-Za-z]+)"'), 'word search screen fallback');
}
