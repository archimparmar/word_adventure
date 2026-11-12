import 'package:flutter/material.dart';

enum UnlockType { level, coins, achievement }

class MiniGame {
  final String id;
  final String name;
  final String description;
  final String category;
  final IconData icon;
  final int difficulty; // 1-5
  final UnlockType unlockType;
  final int unlockValue; // e.g. Level 15, or 500 Coins
  final int maxLevel;
  
  const MiniGame({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.difficulty,
    required this.unlockType,
    required this.unlockValue,
    required this.maxLevel,
  });
}
