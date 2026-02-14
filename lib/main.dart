import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AromaApp());
}

class AromaApp extends StatelessWidget {
  const AromaApp({super.key});

  Future<FirebaseApp> _initializeFirebase() async {
    return Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _initializeFirebase(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Sentidos | Aromatización Profesional',
            themeMode: ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,

              // 🎨 Paleta dorado tenue elegante
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFD4AF37), // Dorado corporativo
                brightness: Brightness.light,
              ),

              scaffoldBackgroundColor: const Color(0xFFF8F6F1),

              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),

              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    width: 2,
                  ),
                ),
              ),

              cardTheme: CardThemeData(
              elevation: 12,
              shadowColor: Colors.black.withValues(alpha:0.15),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
               ),
              ),

            ),
            home: const LoginScreen(),
          );
        }

        // Loader mientras Firebase se inicializa
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}
