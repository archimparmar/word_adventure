import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class DictionaryService {
  /// Offline list of common English words (no proper names, abbreviations or
  /// profanity). It only decides whether an extra word counts as a BONUS word;
  /// required words always come from the curated level datasets.
  static const String dictionaryAsset = 'assets/english_dictionary.txt';

  static final Set<String> _words = {};
  static bool _isLoaded = false;

  static bool get isLoaded => _isLoaded;

  static Future<void> loadDictionary() async {
    if (_isLoaded) return;
    try {
      final text = await rootBundle.loadString(dictionaryAsset);
      _parseWords(text);
    } catch (_) {
      _tryLoadFromFile();
    }
  }

  static void _tryLoadFromFile() {
    try {
      final file = File(dictionaryAsset);
      if (file.existsSync()) {
        final text = file.readAsStringSync();
        _parseWords(text);
      }
    } catch (_) {}
  }

  static void _parseWords(String content) {
    final lines = const LineSplitter().convert(content);
    for (String line in lines) {
      String trimmed = line.trim();
      if (trimmed.isEmpty ||
          trimmed.startsWith('Title:') ||
          trimmed.startsWith('Description:') ||
          trimmed.startsWith('Source:') ||
          trimmed.startsWith('---')) {
        continue;
      }
      if (trimmed.length >= 3) {
        _words.add(trimmed.toUpperCase());
      }
    }
    _isLoaded = _words.isNotEmpty;
  }

  /// Checks if [word] exists in the offline English dictionary.
  static bool isValidWord(String word) {
    if (!_isLoaded || _words.isEmpty) {
      _tryLoadFromFile();
    }
    String upper = word.trim().toUpperCase();
    if (upper.length < 3) return false;
    return _words.contains(upper);
  }

  /// Checks if [word] can be formed using only the available [letters] multiset.
  static bool canFormWordFromLetters(String word, String letters) {
    String upperWord = word.trim().toUpperCase();
    String upperLetters = letters.trim().toUpperCase();

    Map<String, int> letterCounts = {};
    for (int i = 0; i < upperLetters.length; i++) {
      String char = upperLetters[i];
      letterCounts[char] = (letterCounts[char] ?? 0) + 1;
    }

    Map<String, int> wordCounts = {};
    for (int i = 0; i < upperWord.length; i++) {
      String char = upperWord[i];
      wordCounts[char] = (wordCounts[char] ?? 0) + 1;
      if ((wordCounts[char] ?? 0) > (letterCounts[char] ?? 0)) {
        return false;
      }
    }

    return true;
  }
}
