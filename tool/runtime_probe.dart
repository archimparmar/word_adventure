// Runtime probe: boots the real app services exactly like main.dart, opens the
// real game screens at sampled levels and checks that what is rendered comes
// from the corrected datasets bundled into the build.
//
// Usage (from the project root):
//   flutter run -d windows -t tool/runtime_probe.dart
//
// Prints one "PROBE|..." line per check and exits with code 0 (all passed)
// or 1 (something did not match).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:word_puzzle/data/mini_game_data.dart';
import 'package:word_puzzle/providers/game_provider.dart';
import 'package:word_puzzle/providers/user_provider.dart';
import 'package:word_puzzle/screens/game_screen.dart';
import 'package:word_puzzle/screens/mini_crossword_screen.dart';
import 'package:word_puzzle/screens/riddle_screen.dart';
import 'package:word_puzzle/screens/word_search_screen.dart';
import 'package:word_puzzle/services/audio_service.dart';
import 'package:word_puzzle/services/dictionary_service.dart';
import 'package:word_puzzle/services/level_service.dart';
import 'package:word_puzzle/utils/theme.dart';

int _failures = 0;

void _log(String status, String what, [String detail = '']) {
  if (status == 'FAIL') _failures++;
  // ignore: avoid_print
  print('PROBE|$status|$what|$detail');
}

List<String> _visibleTexts() {
  final out = <String>[];
  void visit(Element e) {
    final w = e.widget;
    if (w is Text) {
      final s = w.data ?? w.textSpan?.toPlainText();
      if (s != null && s.trim().isNotEmpty) out.add(s.trim());
    } else if (w is RichText) {
      final s = w.text.toPlainText();
      if (s.trim().isNotEmpty) out.add(s.trim());
    }
    e.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return out;
}

bool _hasLetters(List<String> texts, String word) {
  final singles = texts.where((t) => t.length == 1).map((t) => t.toUpperCase()).toList();
  for (final ch in word.toUpperCase().split('')) {
    if (!singles.remove(ch)) return false;
  }
  return true;
}

Future<List<String>> _show(UserProvider user, Widget screen) async {
  runApp(
    MultiProvider(
      // a fresh key forces a full rebuild so no state leaks between probes
      key: UniqueKey(),
      providers: [ChangeNotifierProvider.value(value: user)],
      child: MaterialApp(theme: AppTheme.theme, debugShowCheckedModeBanner: false, home: screen),
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 1200));
  return _visibleTexts();
}

Future<List<dynamic>> _bundled(String name) async =>
    (jsonDecode(await rootBundle.loadString('assets/$name')) as Map<String, dynamic>)['levels'] as List<dynamic>;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    // layout/asset noise must not abort the probe; report and continue
    // ignore: avoid_print
    print('PROBE|NOTE|flutter error|${details.exceptionAsString().split('\n').first}');
  };

  final user = UserProvider();
  await user.init();
  await LevelService.loadDataset();
  await DictionaryService.loadDictionary();
  await MiniGameData.loadDatasets();
  try {
    await AudioService().init();
  } catch (e) {
    _log('NOTE', 'audio init skipped', '$e');
  }

  final mainData = await _bundled('word_wheel_300_levels.json');
  final cwData = await _bundled('crossword_50_levels.json');
  final riddleData = await _bundled('word_riddle_50_levels.json');
  final wsData = await _bundled('word_search_50_levels.json');

  // ── global uniqueness of what the running app actually serves ──
  final Map<String, String> seen = {};
  int dupes = 0;
  void use(String w, String where) {
    final k = w.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    if (seen.containsKey(k)) {
      dupes++;
      _log('FAIL', 'duplicate at runtime', '$w in $where and ${seen[k]}');
    }
    seen[k] = where;
  }

  for (int id = 1; id <= 300; id++) {
    for (final w in LevelService.getLevel(id).requiredWords) {
      use(w, 'Main $id');
    }
  }
  for (final p in MiniGameData.crosswords) {
    for (final w in p.words) {
      use(w.answer, 'Crossword ${p.id}');
    }
  }
  for (final p in MiniGameData.riddles) {
    use(p.answer, 'Riddle ${p.id}');
  }
  for (final p in MiniGameData.wordSearches) {
    for (final w in p.words) {
      use(w.word, 'Word Search ${p.id}');
    }
  }
  _log(dupes == 0 ? 'PASS' : 'FAIL', 'runtime global uniqueness',
      'levels main=300 crossword=${MiniGameData.crosswords.length} riddle=${MiniGameData.riddles.length} '
          'wordsearch=${MiniGameData.wordSearches.length} words=${seen.length} duplicates=$dupes');

  // ── Main game screens ──
  for (final id in [1, 5, 6, 10, 57, 150, 222, 299, 300]) {
    final expected = (mainData[id - 1]['words_to_make'] as List<dynamic>).cast<String>();
    final provider = GameProvider(id);
    final texts = await _show(user, ChangeNotifierProvider.value(value: provider, child: const GameScreen()));
    final okWheel = _hasLetters(texts, expected.first) && provider.wheelLetters.length == expected.first.length;
    final okWords = provider.currentLevel.requiredWords.join(',') == expected.join(',');
    // submit two real words through GameProvider, the same object the wheel
    // drives. The screen's reward handler is deliberately not called and the
    // level is not finished, so no coins/XP/progress are written to the save.
    final played = <String>[];
    for (final word in expected.skip(1).take(2)) {
      final picked = <int>[];
      for (final ch in word.split('')) {
        final idx = List.generate(provider.wheelLetters.length, (i) => i)
            .firstWhere((i) => provider.wheelLetters[i] == ch && !picked.contains(i), orElse: () => -1);
        if (idx < 0) break;
        picked.add(idx);
        provider.selectIndex(idx);
      }
      provider.submitWord((w, result) {
        if (result == SubmissionResult.validRequired) played.add(w);
      });
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    final okPlay = played.length == expected.skip(1).take(2).length && provider.foundWords.length == played.length;
    _log(okWheel && okWords && okPlay ? 'PASS' : 'FAIL', 'Main Level $id',
        'wheel=${provider.wheelLetters.join()} words=${expected.join(' ')} accepted=${played.join(' ')}');
  }

  // ── Crossword screens ──
  for (final id in [1, 6, 20, 35, 50]) {
    final words = (cwData[id - 1]['words'] as List<dynamic>);
    final texts = await _show(user, MiniCrosswordScreen(levelId: id));
    final joined = texts.join(' || ');
    final shownClues = words.where((w) => joined.contains(w['clue'] as String)).length;
    final runtime = MiniGameData.crosswords[id - 1].words.map((w) => w.answer).join(' ');
    final ok = shownClues >= 1 && runtime == words.map((w) => w['answer']).join(' ');
    _log(ok ? 'PASS' : 'FAIL', 'Crossword Level $id', 'answers=$runtime cluesOnScreen=$shownClues/${words.length}');
  }

  // ── Riddle screens ──
  for (final id in [1, 6, 25, 34, 49, 50]) {
    final r = riddleData[id - 1] as Map<String, dynamic>;
    final texts = await _show(user, RiddleScreen(levelId: id));
    final clueShown = texts.any((t) => t.contains(r['clue'] as String));
    final bankOk = _hasLetters(texts, (r['answer'] as String).replaceAll(' ', ''));
    _log(clueShown && bankOk ? 'PASS' : 'FAIL', 'Riddle Level $id', 'answer=${r['answer']} clueOnScreen=$clueShown letterBankHasAnswer=$bankOk');
  }

  // ── Word search screens ──
  for (final id in [1, 6, 20, 35, 50]) {
    final l = wsData[id - 1] as Map<String, dynamic>;
    final targets = (l['words'] as List<dynamic>).map((w) => w['word'] as String).toList();
    final texts = await _show(user, WordSearchScreen(levelId: id));
    final upper = texts.map((t) => t.toUpperCase()).toList();
    final listed = targets.where((t) => upper.any((u) => u.contains(t))).length;
    final boardOk = _hasLetters(texts, (l['board'] as List<dynamic>).join());
    _log(listed == targets.length && boardOk ? 'PASS' : 'FAIL', 'Word Search Level $id',
        'targets=${targets.join(' ')} listedOnScreen=$listed/${targets.length} boardOnScreen=$boardOk');
  }

  _log(_failures == 0 ? 'PASS' : 'FAIL', 'SUMMARY', 'failures=$_failures');
  await Future<void>.delayed(const Duration(milliseconds: 300));
  exit(_failures == 0 ? 0 : 1);
}
