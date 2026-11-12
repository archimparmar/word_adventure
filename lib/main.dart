import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'data/mini_game_data.dart';
import 'utils/theme.dart';

import 'services/level_service.dart';
import 'services/dictionary_service.dart';
import 'services/audio_service.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';

import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final userProvider = UserProvider();
  await userProvider.init();
  await LevelService.loadDataset();
  await DictionaryService.loadDictionary();
  await MiniGameData.loadDatasets();
  await AudioService().init();
  await AdService().init();
  await NotificationService().init();

  // Start background music once at launch — it persists across all screens
  AudioService().playGameplayMusic();


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Adventure',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      // Prevent Flutter's default blue from flashing before first frame
      color: const Color(0xFF10152F),
      home: const SplashScreen(),
    );
  }
}
