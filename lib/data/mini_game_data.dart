import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/puzzle_models.dart';

class MiniGameData {
  static List<RiddlePuzzle> _riddles = [];
  static List<CrosswordPuzzle> _crosswords = [];
  static List<WordSearchPuzzle> _wordSearches = [];
  static bool _loaded = false;

  static bool get isLoaded => _loaded;
  static List<RiddlePuzzle> get riddles => _riddles;
  static List<CrosswordPuzzle> get crosswords => _crosswords;
  static List<WordSearchPuzzle> get wordSearches => _wordSearches;
  static List<WordWheelPuzzle> get wordWheels => [];

  static Future<void> loadDatasets() async {
    if (_loaded) return;

    try {
      final riddleStr = await rootBundle.loadString('assets/word_riddle_50_levels.json');
      final Map<String, dynamic> riddleMap = jsonDecode(riddleStr);
      final List<dynamic> riddleList = riddleMap['levels'];
      _riddles = riddleList.map((e) => RiddlePuzzle.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading riddle dataset: $e');
      }
    }

    try {
      final crosswordStr = await rootBundle.loadString('assets/crossword_50_levels.json');
      final Map<String, dynamic> crosswordMap = jsonDecode(crosswordStr);
      final List<dynamic> crosswordList = crosswordMap['levels'];
      _crosswords = crosswordList.map((e) => CrosswordPuzzle.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading crossword dataset: $e');
      }
    }

    try {
      final searchStr = await rootBundle.loadString('assets/word_search_50_levels.json');
      final Map<String, dynamic> searchMap = jsonDecode(searchStr);
      final List<dynamic> searchList = searchMap['levels'];
      _wordSearches = searchList.map((e) => WordSearchPuzzle.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading word search dataset: $e');
      }
    }

    _loaded = true;
  }
}
