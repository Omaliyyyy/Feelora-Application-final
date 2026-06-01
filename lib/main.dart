import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/task_screen.dart';
import 'screens/progress_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Enable offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const FeeloraApp());
}

class FeeloraApp extends StatelessWidget {
  const FeeloraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feelora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: kAccent,
          surface: kBackground,
        ),
        scaffoldBackgroundColor: kBackground,
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/':           (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/login':      (_) => const LoginScreen(),
        '/home':       (_) => const HomeScreen(),
        '/progress':   (_) => const ProgressScreen(),
      },
      // Task screen uses arguments so needs onGenerateRoute
      onGenerateRoute: (settings) {
        if (settings.name == '/tasks') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => TaskScreen(
              moodData:   args['mood']  as MoodData,
              currentDay: args['day']   as int,
            ),
          );
        }
        return null;
      },
    );
  }
}
