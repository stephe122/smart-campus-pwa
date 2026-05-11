import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mahsa_navigation/screens/auth/login_screen.dart';
import 'package:mahsa_navigation/screens/events/events_screen.dart';
import 'package:mahsa_navigation/screens/navigation/navigation_screen.dart'; 
import 'package:mahsa_navigation/screens/feedback/feedback_screen.dart';
import 'package:mahsa_navigation/screens/profile/profile_screen.dart';
import 'package:mahsa_navigation/screens/settings/settings_screen.dart';
import 'package:mahsa_navigation/widgets/footer_widget.dart';

// --- MAIN HOME SCREEN CLASS ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get User Name
    final user = FirebaseAuth.instance.currentUser;
    String displayName = "Student";
    if (user != null && user.email != null) {
      displayName = user.email!.split('@')[0];
      if (displayName.isNotEmpty) {
        displayName = displayName[0].toUpperCase() + displayName.substring(1);
      }
    }

    // 2. CHECK FOR DARK MODE
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 3. Set Dynamic Colors
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardBgColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final headerBgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8EAF6);
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E), // Keep AppBar Blue
        title: Text("Smart Campus", style: GoogleFonts.poppins(color: Colors.white)),
        actions: [
          Tooltip(
            message: "Logout",
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      // Wrapped in SingleChildScrollView so the Footer can exist at the bottom
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Welcome Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: headerBgColor, // <--- Dynamic Color
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_circle, size: 50, color: Color(0xFF1A237E)),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome $displayName", 
                              style: GoogleFonts.poppins(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: textColor // <--- Dynamic Color
                              )
                            ),
                            Text(
                              "Let's find your way!", 
                              style: GoogleFonts.poppins(color: subTextColor) // <--- Dynamic Color
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Main "Navigate Now" Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NavigationScreen()),
                        );
                      },
                      icon: const Icon(Icons.explore),
                      label: Text("NAVIGATE NOW", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // Grid Options
                  GridView.count(
                    shrinkWrap: true, // Important because it's inside a ScrollView
                    physics: const NeverScrollableScrollPhysics(), // Disable grid's own scrolling
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    children: [
                      _buildMenuCard(context, Icons.event, "Event Hub", Colors.orange, const EventsScreen(), cardBgColor, textColor),
                      _buildMenuCard(context, Icons.feedback, "Feedback", Colors.green, const FeedbackScreen(), cardBgColor, textColor),
                      _buildMenuCard(context, Icons.person, "Profile", Colors.blue, const ProfileScreen(), cardBgColor, textColor),
                      _buildMenuCard(context, Icons.settings, "Settings", Colors.grey, const SettingsScreen(), cardBgColor, textColor),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40), // Spacing before footer
            
            // --- FOOTER WIDGET ---
            const CampusFooter(),
          ],
        ),
      ),
    );
  }

  // Updated Menu Card Helper to accept Dynamic Colors
  Widget _buildMenuCard(BuildContext context, IconData icon, String title, Color iconColor, Widget? page, Color bgColor, Color txtColor) {
    // 1. Check for Dark Mode to adjust border contrast
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 2. Define a stronger border color
    // We use higher alpha (0.3 - 0.4) so it pops against the background
    final borderColor = isDark 
        ? Colors.grey.withValues(alpha: 0.3) 
        : Colors.grey.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: () {
        if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Coming Soon!")),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor, // <--- Dynamic Background
          borderRadius: BorderRadius.circular(15),
          
          // <--- UPDATED BORDER SETTINGS
          border: Border.all(
            color: borderColor, 
            width: 2.0, // Thicker width (was 1.0)
          ),
          
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), 
              blurRadius: 10, 
              offset: const Offset(0, 5)
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: iconColor),
            const SizedBox(height: 10),
            Text(
              title, 
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: txtColor // <--- Dynamic Text
              )
            ),
          ],
        ),
      ),
    );
  }
}

