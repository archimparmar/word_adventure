import 'package:flutter/material.dart';
import '../models/mini_game.dart';

class MiniGameRegistry {
  static const List<MiniGame> games = [
    MiniGame(
      id: 'word_wheel',
      name: 'Word Wheel',
      description: 'Find words using the center letter.',
      category: 'FAST & FUN',
      icon: Icons.data_usage,
      difficulty: 2,
      unlockType: UnlockType.level,
      unlockValue: 1, // Available immediately
      maxLevel: 50,
    ),
    MiniGame(
      id: 'mini_crossword',
      name: 'Mini Crossword',
      description: 'Solve the clues to fill the grid.',
      category: 'PUZZLE & LOGIC',
      icon: Icons.grid_on,
      difficulty: 3,
      unlockType: UnlockType.level,
      unlockValue: 15, // Unlock at Main Level 15
      maxLevel: 50,
    ),
    MiniGame(
      id: 'word_riddle',
      name: 'Word Riddles',
      description: 'Solve the riddle to find the word.',
      category: 'PUZZLE & LOGIC',
      icon: Icons.psychology,
      difficulty: 2,
      unlockType: UnlockType.coins,
      unlockValue: 200, // Unlock for 200 coins
      maxLevel: 100,
    ),
    MiniGame(
      id: 'word_search',
      name: 'Word Search',
      description: 'Find hidden words in the grid.',
      category: 'FAST & FUN',
      icon: Icons.search,
      difficulty: 1,
      unlockType: UnlockType.level,
      unlockValue: 30, // Unlock at Main Level 30
      maxLevel: 50,
    ),
  ];

  static MiniGame? getGame(String id) {
    try {
      return games.firstWhere((game) => game.id == id);
    } catch (e) {
      return null;
    }
  }
}
