class RiddlePuzzle {
  final int id;
  final String clue;
  final String answer;
  final String category;
  final String difficulty;
  final String hint;
  final String explanation;
  final int reward;

  RiddlePuzzle({
    required this.id,
    required this.clue,
    required this.answer,
    required this.category,
    required this.difficulty,
    required this.hint,
    required this.explanation,
    this.reward = 25,
  });

  factory RiddlePuzzle.fromJson(Map<String, dynamic> json) {
    return RiddlePuzzle(
      id: json['level'] as int? ?? 1,
      clue: json['clue'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      difficulty: json['difficulty'] as String? ?? 'Easy',
      hint: json['hint'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      reward: 25,
    );
  }
}

class CrosswordPuzzle {
  final int id;
  final int rows;
  final int cols;
  final List<String> grid;
  final List<String> solution;
  final List<CrosswordWord> words;
  final int reward;

  CrosswordPuzzle({
    required this.id,
    required this.rows,
    required this.cols,
    required this.grid,
    required this.solution,
    required this.words,
    this.reward = 30,
  });

  factory CrosswordPuzzle.fromJson(Map<String, dynamic> json) {
    List<CrosswordWord> wordList = [];
    if (json['words'] != null) {
      for (var w in json['words']) {
        wordList.add(CrosswordWord.fromJson(w as Map<String, dynamic>));
      }
    }
    List<String> gridList = (json['grid'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    List<String> solList = (json['solution'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? gridList;

    return CrosswordPuzzle(
      id: json['level'] as int? ?? 1,
      rows: json['rows'] as int? ?? 5,
      cols: json['cols'] as int? ?? 5,
      grid: gridList,
      solution: solList,
      words: wordList,
      reward: 30,
    );
  }
}

class WordWheelPuzzle {
  final int id;
  final String centerLetter;
  final String outerLetters;
  final List<String> validWords;
  final int reward;

  WordWheelPuzzle({
    required this.id,
    required this.centerLetter,
    required this.outerLetters,
    required this.validWords,
    required this.reward,
  });
}

class CrosswordWord {
  final int number;
  final String answer;
  final String clue;
  final int row;
  final int col;
  final String direction; // 'across' or 'down'

  CrosswordWord({
    required this.number,
    required this.answer,
    required this.clue,
    required this.row,
    required this.col,
    required this.direction,
  });

  factory CrosswordWord.fromJson(Map<String, dynamic> json) {
    return CrosswordWord(
      number: json['number'] as int? ?? 1,
      answer: (json['answer'] as String? ?? '').toUpperCase(),
      clue: json['clue'] as String? ?? '',
      row: json['row'] as int? ?? 0,
      col: json['col'] as int? ?? 0,
      direction: (json['direction'] as String? ?? 'across').toLowerCase(),
    );
  }
}

class WordSearchPuzzle {
  final int id;
  final int size;
  final String difficulty;
  final List<String> board;
  final List<WordSearchWord> words;
  final int reward;

  WordSearchPuzzle({
    required this.id,
    required this.size,
    required this.difficulty,
    required this.board,
    required this.words,
    this.reward = 35,
  });

  factory WordSearchPuzzle.fromJson(Map<String, dynamic> json) {
    List<WordSearchWord> wordList = [];
    if (json['words'] != null) {
      for (var w in json['words']) {
        wordList.add(WordSearchWord.fromJson(w as Map<String, dynamic>));
      }
    }
    return WordSearchPuzzle(
      id: json['level'] as int? ?? 1,
      size: json['size'] as int? ?? 6,
      difficulty: json['difficulty'] as String? ?? 'easy',
      board: (json['board'] as List<dynamic>?)?.map((e) => e.toString().toUpperCase()).toList() ?? [],
      words: wordList,
      reward: 35,
    );
  }
}

class WordSearchWord {
  final String word;
  final int startRow;
  final int startCol;
  final int endRow;
  final int endCol;
  final String direction;

  WordSearchWord({
    required this.word,
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
    required this.direction,
  });

  factory WordSearchWord.fromJson(Map<String, dynamic> json) {
    List<dynamic> start = json['start'] ?? [0, 0];
    List<dynamic> end = json['end'] ?? [0, 0];
    return WordSearchWord(
      word: (json['word'] as String? ?? '').toUpperCase(),
      startRow: start[0] as int? ?? 0,
      startCol: start[1] as int? ?? 0,
      endRow: end[0] as int? ?? 0,
      endCol: end[1] as int? ?? 0,
      direction: json['direction'] as String? ?? 'right',
    );
  }
}

class DailyPuzzle {
  final String date; // YYYY-MM-DD
  final String letters;
  final List<String> requiredWords;
  final int reward;

  DailyPuzzle({
    required this.date,
    required this.letters,
    required this.requiredWords,
    required this.reward,
  });
}
