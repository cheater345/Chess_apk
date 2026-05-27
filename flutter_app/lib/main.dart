import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/puzzle_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'providers/socket_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/game/game_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const OpenChessArena());
}

class OpenChessArena extends StatelessWidget {
  const OpenChessArena({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SocketProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => PuzzleProvider()),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'OpenChess Arena',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
        routes: {
          '/auth': (context) => const AuthScreen(),
          '/home': (context) => const HomeScreen(),
          '/game': (context) => const GameScreen(),
        },
      ),
    );
  }
}
