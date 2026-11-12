import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Global Color System
  static const Color deepIndigo = Color(0xFF10152F);
  static const Color royalBlue = Color(0xFF263C96);
  static const Color sky = Color(0xFF35BFE8);
  static const Color gold = Color(0xFFFFD21C);
  static const Color warmGold = Color(0xFFF4A62A);
  static const Color success = Color(0xFF25D978);
  static const Color aqua = Color(0xFF00E5C3);
  static const Color coral = Color(0xFFFF6B6B);
  
  static const Color textLight = Colors.white;
  static const Color textDark = deepIndigo;
  static const Color overlaySubtle = Color(0x66000000); // Only for text readability
  static const Color overlayDark = Color(0xB3000000); // 70% opacity

  // Spacing System
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s28 = 28.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;

  // Corner System
  static const double radiusSmall = 12.0; // Game tiles 8-12
  static const double radiusMedium = 16.0; // Small controls 10-14
  static const double radiusCard = 20.0; // Cards 16-20
  static const double radiusLarge = 24.0; // Hero buttons 18-24

  static TextStyle get worldTitle => GoogleFonts.nunito(
    fontWeight: FontWeight.w900,
    fontSize: 24,
    color: textLight,
    shadows: const [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
  );

  static TextStyle get levelLarge => GoogleFonts.nunito(
    fontWeight: FontWeight.w900,
    fontSize: 22,
    color: textLight,
    shadows: const [Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 2))],
  );

  static TextStyle get sectionHeading => GoogleFonts.nunito(
    fontWeight: FontWeight.w800,
    fontSize: 18,
    color: textLight,
    shadows: const [Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1))],
  );

  static TextStyle get body => GoogleFonts.nunito(
    fontWeight: FontWeight.w700,
    fontSize: 14,
    color: textLight,
  );

  static TextStyle get smallSecondary => GoogleFonts.nunito(
    fontWeight: FontWeight.w700,
    fontSize: 12,
    color: Colors.white70,
  );

  static TextStyle get reward => GoogleFonts.nunito(
    fontWeight: FontWeight.w900,
    fontSize: 24,
    color: gold,
    shadows: const [Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 3))],
  );

  static ThemeData get theme {
    return ThemeData(
      primaryColor: royalBlue,
      scaffoldBackgroundColor: deepIndigo,
      colorScheme: const ColorScheme.light(
        primary: royalBlue,
        secondary: sky,
        surface: Colors.transparent,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(),
      // surface is transparent, and SnackBar text defaults to a colour derived
      // from it, so the text must be given an explicit visible colour.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1B362A),
        contentTextStyle: GoogleFonts.nunito(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

// World Theme System
class WorldTheme {
  final String id;
  final String name;
  final String backgroundPath;
  final String boardPath;
  final String landmarkPath;
  final Color primaryColor;
  final Color accentColor;

  const WorldTheme({
    required this.id,
    required this.name,
    required this.backgroundPath,
    required this.boardPath,
    required this.landmarkPath,
    required this.primaryColor,
    required this.accentColor,
  });

  static const List<WorldTheme> worlds = [
    WorldTheme(
      id: 'world_1',
      name: 'MEADOW TRAILS',
      backgroundPath: 'assets/images/worlds/world_1.webp',
      boardPath: 'assets/images/boards/board_wood.webp',
      landmarkPath: 'assets/images/landmarks/meadow_world_1.webp',
      primaryColor: Color(0xFF4CAF50),
      accentColor: AppTheme.warmGold,
    ),
    WorldTheme(
      id: 'world_2',
      name: 'MYSTIC FOREST',
      backgroundPath: 'assets/images/worlds/world_2.webp',
      boardPath: 'assets/images/boards/board_wood.webp',
      landmarkPath: 'assets/images/landmarks/forest_world_2.webp',
      primaryColor: Color(0xFF2E7D32),
      accentColor: AppTheme.gold,
    ),
    WorldTheme(
      id: 'world_3',
      name: 'TROPICAL ISLAND',
      backgroundPath: 'assets/images/worlds/world_3.webp',
      boardPath: 'assets/images/boards/board_wood.webp',
      landmarkPath: 'assets/images/landmarks/island_world_3.webp',
      primaryColor: AppTheme.sky,
      accentColor: AppTheme.warmGold,
    ),
    WorldTheme(
      id: 'world_4',
      name: 'SUNSET DESERT',
      backgroundPath: 'assets/images/worlds/world_4.webp',
      boardPath: 'assets/images/boards/board_stone.webp',
      landmarkPath: 'assets/images/landmarks/desert_world_4.webp',
      primaryColor: AppTheme.coral,
      accentColor: AppTheme.gold,
    ),
    WorldTheme(
      id: 'world_5',
      name: 'FROZEN PEAKS',
      backgroundPath: 'assets/images/worlds/world_5.webp',
      boardPath: 'assets/images/boards/board_crystal.webp',
      landmarkPath: 'assets/images/landmarks/snow_world_5.webp',
      primaryColor: AppTheme.royalBlue,
      accentColor: AppTheme.sky,
    ),
    WorldTheme(
      id: 'world_6',
      name: 'ANCIENT RUINS',
      backgroundPath: 'assets/images/worlds/world_6.webp',
      boardPath: 'assets/images/boards/board_stone.webp',
      landmarkPath: 'assets/images/landmarks/ruins_world_6.webp',
      primaryColor: Color(0xFF795548),
      accentColor: AppTheme.gold,
    ),
    WorldTheme(
      id: 'world_7',
      name: 'CELESTIAL CLOUDS',
      backgroundPath: 'assets/images/worlds/world_7.webp',
      boardPath: 'assets/images/boards/board_gold.webp',
      landmarkPath: 'assets/images/landmarks/clouds_world_7.webp',
      primaryColor: AppTheme.sky,
      accentColor: AppTheme.gold,
    ),
  ];

  static WorldTheme getTheme(int level) {
    if (level <= 40) return worlds[0];
    if (level <= 80) return worlds[1];
    if (level <= 120) return worlds[2];
    if (level <= 160) return worlds[3];
    if (level <= 200) return worlds[4];
    if (level <= 250) return worlds[5];
    return worlds[6];
  }
}
