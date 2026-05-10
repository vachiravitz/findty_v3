import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/game_selection_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SquadFinderApp());
}

class SquadFinderApp extends StatelessWidget {
  const SquadFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: const Color(0xFFFCE4EC),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFFF80AB),
        secondary: Color(0xFFFCE4EC),
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Squad Finder',
      theme: base.copyWith(
        textTheme: GoogleFonts.notoSansThaiTextTheme(base.textTheme),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('th', 'TH'),
      ],
      locale: const Locale('th', 'TH'),
      // ฟัง auth state เพื่อ:
      // - logged in -> GameSelectionScreen ทันที (ข้าม login)
      // - logged out -> LoginScreen
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.data != null) return const GameSelectionScreen();
          return const LoginScreen();
        },
      ),
    );
  }
}
