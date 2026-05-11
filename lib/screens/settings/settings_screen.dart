import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:mahsa_navigation/providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  // 1. Password Reset Function
  Future<void> _resetPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password reset email sent! Check your inbox.")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  // 2. About App Dialog (The Script)
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("About MAHSA Smart Campus Navigation App", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "Version 1.0.0 (Beta)\n\n"
          "This application was developed to assist MAHSA University students in navigating the campus efficiently. \n\n"
          "Key Features:\n"
          "• Real-time Navigation\n"
          "• Campus Event Updates\n"
          "• Profile Setup\n"
          "• Student Feedback System\n\n"
          "Developed by: Engr Stephen Software Developer\n"
          "For: Final Year Project 2026",
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
        ],
      ),
    );
  }

  // 3. Privacy Policy Dialog (The Documentation)
  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Privacy Policy", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            "Last Updated: February 2026\n\n"
            "1. Data Collection\n"
            "We collect your email address for authentication purposes only. We do not share your personal data with third parties.\n\n"
            "2. Location Services\n"
            "This app requires access to your real-time location to provide navigation services within the campus. Location data is processed locally on your device.\n\n"
            "3. Feedback\n"
            "Any feedback submitted is sent directly to the administration for review. Please avoid including sensitive personal information in feedback forms.\n\n"
            "4. Disclaimer\n"
            "This is a student project application. MAHSA University is not liable for any navigation errors.",
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("I Understand"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access the Theme Provider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      // Background handles dark mode automatically now
      appBar: AppBar(
        title: Text("SETTINGS", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader("Account"),
          _buildSettingsTile(
            icon: Icons.lock_reset,
            title: "Change Password",
            subtitle: "Send a reset link to your email",
            onTap: _resetPassword,
          ),
          
          const SizedBox(height: 20),
          _buildSectionHeader("App Preferences"),
          
          // Switch Tile 1: Notifications (Mock)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
            child: SwitchListTile(
              secondary: Icon(Icons.notifications, color: Theme.of(context).primaryColor),
              title: Text("Notifications", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() => _notificationsEnabled = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value ? "Notifications Enabled" : "Notifications Disabled"),
                    duration: const Duration(milliseconds: 800),
                  ),
                );
              },
            ),
          ),

          // Switch Tile 2: Dark Mode (Real)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
            child: SwitchListTile(
              secondary: Icon(Icons.dark_mode, color: Theme.of(context).primaryColor),
              title: Text("Dark Mode", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              value: themeProvider.isDarkMode, // Reads from Provider
              onChanged: (value) {
                // Toggles the Provider
                final provider = Provider.of<ThemeProvider>(context, listen: false);
                provider.toggleTheme(value);
              },
            ),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader("About"),
          _buildSettingsTile(
            icon: Icons.info, 
            title: "About App", 
            subtitle: "Version 1.0.0 (Beta)",
            onTap: _showAboutDialog, // Opens the Dialog
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip, 
            title: "Privacy Policy", 
            subtitle: "Read our terms of service",
            onTap: _showPrivacyDialog, // Opens the Dialog
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Adapts to Dark Mode
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}