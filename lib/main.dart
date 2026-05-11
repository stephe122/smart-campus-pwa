import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // <--- NEW IMPORT
import 'package:google_fonts/google_fonts.dart';
import 'package:mahsa_navigation/firebase_options.dart';
import 'package:mahsa_navigation/screens/auth/login_screen.dart';
import 'package:mahsa_navigation/providers/theme_provider.dart'; // <--- NEW IMPORT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Connect to Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MahsaApp());
}

class MahsaApp extends StatelessWidget {
  const MahsaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // WRAP EVERYTHING IN PROVIDER
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      builder: (context, _) {
        final themeProvider = Provider.of<ThemeProvider>(context);

        return MaterialApp(
          title: 'MAHSA Navigation',
          debugShowCheckedModeBanner: false,
          
          // 1. LIGHT THEME (Your Original Style)
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF1A237E), // MAHSA Blue
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A237E),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.white,
            textTheme: GoogleFonts.poppinsTextTheme(),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // 2. DARK THEME (The New Style)
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF1A237E),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A237E),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212), // Dark Grey Background
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1F1F1F), // Darker Grey for AppBar
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            cardColor: const Color(0xFF1F1F1F),
            bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Color(0xFF1F1F1F)),
          ),

          // 3. LISTEN TO THE SWITCH
          themeMode: themeProvider.themeMode, 
          
          home: const SplashScreen(),
        );
      },
    );
  }
}

// --- YOUR EXISTING SPLASH SCREEN (UNCHANGED) ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Show splash for 3 seconds, then navigate to Login
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Keep Splash white for professionalism
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 100, color: Color(0xFF1A237E)), 
            const SizedBox(height: 20),
            Text(
              "MAHSA UNIVERSITY",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              color: Color(0xFF1A237E),
            ),
          ],
        ),
      ),
    );
  }
}