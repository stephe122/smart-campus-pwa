import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; 

// Importing your screens for navigation
import 'package:mahsa_navigation/screens/events/events_screen.dart';
import 'package:mahsa_navigation/screens/navigation/navigation_screen.dart';
import 'package:mahsa_navigation/screens/feedback/feedback_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
class CampusFooter extends StatelessWidget {
  const CampusFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFF1A237E); 
    const text = Colors.white;
    const subText = Colors.white70;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
      child: Column(
        children: [
          // TOP SECTION: Logo & Columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // COL 1: BRANDING
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.school, color: Colors.white, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      "MAHSA UNIVERSITY",
                      style: GoogleFonts.poppins(
                        color: text, fontWeight: FontWeight.bold, fontSize: 16
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Smart Campus Navigation System.\nFinding your way made easy.",
                      style: GoogleFonts.poppins(color: subText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              if (MediaQuery.of(context).size.width > 600) const SizedBox(width: 40),

              // COL 2: QUICK LINKS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("MENU", style: GoogleFonts.poppins(color: text, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _footerLink("Home", onTap: () {}), 
                    _footerLink("Events", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const EventsScreen()));
                    }),
                    _footerLink("Map", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NavigationScreen()));
                    }),
                    _footerLink("Feedback", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackScreen()));
                    }),
                  ],
                ),
              ),

              // COL 3: CONTACT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("CONTACT", style: GoogleFonts.poppins(color: text, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _footerLink("Student Central"),
                    _footerLink("IT Helpdesk"),
                    _footerLink("terms@mahsa.edu.my"),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
          Divider(color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 20),

          // BOTTOM SECTION: Copyright & Socials
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "© 2026 MAHSA University. All rights reserved.",
                style: GoogleFonts.poppins(color: subText, fontSize: 12),
              ),
              Row(
  children: [
    // UPDATED: Using the official FontAwesome Facebook icon
    _socialIcon(FontAwesomeIcons.facebook, 'https://www.facebook.com/MAHSAUniversity'),
    const SizedBox(width: 15),
    
    // UPDATED: Using the official FontAwesome Instagram icon
    _socialIcon(FontAwesomeIcons.instagram, 'https://www.instagram.com/mahsauniversity'), 
    const SizedBox(width: 15),
    
    // Kept the default Material link icon for the website
    _socialIcon(Icons.link, 'https://mahsa.edu.my'), 
  ],
)
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String text, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Text(
          text,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
        ),
      ),
    );
  }

  // UPDATED: Now accepts a URL and launches it securely
  // WEB-OPTIMIZED: Force launches the URL without the strict check
  Widget _socialIcon(IconData icon, String url) {
    return InkWell(
      onTap: () async {
        final Uri uri = Uri.parse(url);
        try {
          // This tells Flutter Web to force open a new blank tab
          await launchUrl(uri, webOnlyWindowName: '_blank');
        } catch (e) {
          debugPrint('Could not launch $url: $e');
        }
      },
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}