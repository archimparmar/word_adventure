import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../models/level.dart';
import '../services/level_service.dart';
import '../services/dictionary_service.dart';

enum SubmissionResult {
  validRequired,
  validBonus,
  validHard,
  alreadyFound,
  invalid,
}

class GameProvider with ChangeNotifier {
  Level _currentLevel;
  final List<String> _foundWords = [];
  final List<String> _foundBonusWords = [];
  
  List<String> _wheelLetters = [];
  final List<int> _selectedIndices = [];
  
  bool _isLevelComplete = false;
  int _hintsUsed = 0;
  
  final List<String> _hintedCells = [];
  List<String> get hintedCells => _hintedCells;

  GameProvider(int levelId) : _currentLevel = LevelService.getLevel(levelId) {
    _initializeLevel();
  }

  Level get currentLevel => _currentLevel;
  List<String> get foundWords => _foundWords;
  List<String> get foundBonusWords => _foundBonusWords;
  List<String> get wheelLetters => _wheelLetters;
  List<int> get selectedIndices => _selectedIndices;
  bool get isLevelComplete => _isLevelComplete;
  
  // Staggered Layout properties
  final Map<String, math.Point<int>> _wordPositions = {};
  Map<String, math.Point<int>> get wordPositions => _wordPositions;
  int _gridWidth = 1;
  int _gridHeight = 1;
  int get gridWidth => _gridWidth;
  int get gridHeight => _gridHeight;
  
  String get currentWord => _selectedIndices.map((i) => _wheelLetters[i]).join('');

  void _initializeLevel() {
    _foundWords.clear();
    _foundBonusWords.clear();
    _selectedIndices.clear();
    _isLevelComplete = false;
    _hintsUsed = 0;
    _hintedCells.clear();
    
    _shuffleWheelLetters();
    _generateLayout();
    notifyListeners();
  }

  void _generateLayout() {
    _wordPositions.clear();
    int currentY = 0;
    int maxX = 0;
    
    List<String> words = List.from(_currentLevel.requiredWords);
    
    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      int x = 0;
      
      switch (_currentLevel.layoutPattern) {
        case 1:
          x = i % 3; 
          break;
        case 2:
          x = math.max(0, (8 - word.length) ~/ 2);
          break;
        case 3:
          x = math.max(0, (word.length) ~/ 2);
          break;
        case 4:
          x = (i % 2 == 0) ? 0 : 2;
          break;
        case 5:
          x = (i % 2 == 0) ? 0 : 3;
          break;
        default:
          x = i % 2;
      }
      
      _wordPositions[word] = math.Point(x, currentY);
      currentY += 1;
      maxX = math.max(maxX, x + word.length);
    }
    
    _gridWidth = math.max(4, maxX);
    _gridHeight = currentY;
  }

  void selectIndex(int index) {
    if (index >= 0 && index < _wheelLetters.length && !_selectedIndices.contains(index)) {
      _selectedIndices.add(index);
      notifyListeners();
    }
  }

  void deselectLastIndex() {
    if (_selectedIndices.isNotEmpty) {
      _selectedIndices.removeLast();
      notifyListeners();
    }
  }

  void submitWord(Function(String word, SubmissionResult result) onResult) {
    if (_selectedIndices.isEmpty) return;

    final word = currentWord;
    _selectedIndices.clear();

    if (_currentLevel.requiredWords.contains(word)) {
      if (_foundWords.contains(word)) {
        onResult(word, SubmissionResult.alreadyFound);
      } else {
        _foundWords.add(word);
        _checkCompletion();
        onResult(word, SubmissionResult.validRequired);
      }
    } else if (word == _currentLevel.hardWord) {
      if (_foundBonusWords.contains(word)) {
        onResult(word, SubmissionResult.alreadyFound);
      } else {
        _foundBonusWords.add(word);
        onResult(word, SubmissionResult.validHard);
      }
    } else if (_currentLevel.bonusWords.contains(word)) {
      if (_foundBonusWords.contains(word)) {
        onResult(word, SubmissionResult.alreadyFound);
      } else {
        _foundBonusWords.add(word);
        onResult(word, SubmissionResult.validBonus);
      }
    } else if (DictionaryService.isValidWord(word) &&
               DictionaryService.canFormWordFromLetters(word, _currentLevel.letters)) {
      if (_foundBonusWords.contains(word)) {
        onResult(word, SubmissionResult.alreadyFound);
      } else {
        _foundBonusWords.add(word);
        onResult(word, SubmissionResult.validBonus);
      }
    } else {
      onResult(word, SubmissionResult.invalid);
    }
    
    notifyListeners();
  }
  
  void clearSelection() {
    _selectedIndices.clear();
    notifyListeners();
  }

  void _checkCompletion() {
    if (_foundWords.length == _currentLevel.requiredWords.length) {
      _isLevelComplete = true;
    }
  }
  
  bool isPerfect() => _hintsUsed == 0;

  void shuffle() {
    _shuffleWheelLetters();
    _selectedIndices.clear();
    notifyListeners();
  }

  void _shuffleWheelLetters() {
    List<String> canonical = _currentLevel.letters.toUpperCase().split('');
    if (canonical.length <= 3) {
      List<String> list = List.from(canonical);
      list.shuffle();
      _wheelLetters = list;
      return;
    }

    List<String> shuffled = List.from(canonical);
    for (int attempt = 0; attempt < 50; attempt++) {
      shuffled.shuffle();
      if (!_isCanonicalPath(shuffled, canonical)) {
        _wheelLetters = shuffled;
        return;
      }
    }
    _wheelLetters = shuffled;
  }

  bool _isCanonicalPath(List<String> arr, List<String> canonical) {
    int n = arr.length;
    if (n != canonical.length) return false;
    String mainStr = canonical.join('');
    String revStr = canonical.reversed.join('');

    for (int i = 0; i < n; i++) {
      String cw = List.generate(n, (k) => arr[(i + k) % n]).join('');
      String ccw = List.generate(n, (k) => arr[(i - k + n) % n]).join('');
      if (cw == mainStr || ccw == mainStr || cw == revStr || ccw == revStr) {
        return true;
      }
    }
    return false;
  }

  bool useHint() {
    List<String> availableHints = [];
    
    for (String word in _currentLevel.requiredWords) {
      if (!_foundWords.contains(word)) {
        for (int i = 0; i < word.length; i++) {
          String cellKey = '${word}_$i';
          if (!_hintedCells.contains(cellKey)) {
            availableHints.add(cellKey);
          }
        }
      }
    }
    
    if (availableHints.isNotEmpty) {
      availableHints.shuffle();
      _hintedCells.add(availableHints.first);
      _hintsUsed++;

      // Auto-detect if any required word has all letters hinted
      for (String word in _currentLevel.requiredWords) {
        if (!_foundWords.contains(word)) {
          bool allHinted = true;
          for (int i = 0; i < word.length; i++) {
            if (!_hintedCells.contains('${word}_$i')) {
              allHinted = false;
              break;
            }
          }
          if (allHinted) {
            _foundWords.add(word);
          }
        }
      }
      _checkCompletion();

      notifyListeners();
      return true;
    }
    
    return false;
  }

  void loadLevel(int levelId) {
    _currentLevel = LevelService.getLevel(levelId);
    _initializeLevel();
  }
}
