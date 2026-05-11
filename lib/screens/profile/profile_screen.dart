import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:mahsa_navigation/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  
  // Controllers for editing
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _facultyController = TextEditingController();

  // Stream to listen to real-time user data
  Stream<DocumentSnapshot>? _userDataStream;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      // Point to the specific document for this user in the 'users' collection
      _userDataStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .snapshots();
    }
  }

  // Function to show the "Edit Profile" Dialog
  void _showEditDialog(Map<String, dynamic>? currentData) {
    // Pre-fill the current values
    _nameController.text = currentData?['name'] ?? '';
    _studentIdController.text = currentData?['studentId'] ?? '';
    _facultyController.text = currentData?['faculty'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Profile", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 10),
              TextField(
  controller: _studentIdController,
  maxLength: 20, // <--- This limits input to 20 chars
  decoration: const InputDecoration(
    labelText: "Student ID", 
    prefixIcon: Icon(Icons.badge),
    counterText: "", // Hides the little "0/20" counter if you want it cleaner
  ),
),
              const SizedBox(height: 10),
              TextField(
                controller: _facultyController,
                decoration: const InputDecoration(labelText: "Faculty", prefixIcon: Icon(Icons.school)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              // ---Capture the Navigator BEFORE the async gap ---
              final nav = Navigator.of(context);

              // SAVE TO FIREBASE
              if (user != null) {
                await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
                  'name': _nameController.text.trim(),
                  'studentId': _studentIdController.text.trim(),
                  'faculty': _facultyController.text.trim(),
                  'email': user!.email, // Keep email for reference
                  'last_updated': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true)); // Merge prevents overwriting existing data fields accidentally
              }
              
              // Safely use the captured navigator to close the dialog
              nav.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check Dark Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    // Format the Joined Date (Creation Time)
    String joinedDate = "Unknown";
    if (user?.metadata.creationTime != null) {
      joinedDate = DateFormat.yMMMM().format(user!.metadata.creationTime!); // e.g. "September 2024"
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("MY PROFILE", style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Edit Button in AppBar
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () {
               // We need to fetch current data first to pass it to the dialog
               // But since we are inside a StreamBuilder below, we can't access it easily here.
               // So we'll pass 'null' for now, or the stream will handle updates.
               // A better UX is clicking the edit pencil on the avatar.
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userDataStream,
        builder: (context, snapshot) {
          // Default Values if data is loading or empty
          String name = "Student";
          String studentId = "Not Set";
          String faculty = "Not Set";
          
          Map<String, dynamic>? data;

          if (snapshot.hasData && snapshot.data!.exists) {
            data = snapshot.data!.data() as Map<String, dynamic>;
            name = data['name'] ?? "Student";
            studentId = data['studentId'] ?? "Not Set";
            faculty = data['faculty'] ?? "Not Set";
            
            // If name is empty in DB, try to use email
            if (name.isEmpty && user?.email != null) {
              name = user!.email!.split('@')[0].toUpperCase();
            }
          } else if (user?.email != null) {
             // Fallback if no DB record yet
             name = user!.email!.split('@')[0].toUpperCase();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // PROFILE AVATAR
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFF1A237E),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "S",
                          style: GoogleFonts.poppins(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Edit Button
                      InkWell(
                        onTap: () => _showEditDialog(data),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Icon(Icons.edit, color: Colors.blue, size: 20),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // NAME & EMAIL
                Text(
                  name,
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                ),
                Text(
                  user?.email ?? "",
                  style: GoogleFonts.poppins(color: subTextColor),
                ),
                const SizedBox(height: 30),

                // DETAILS CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5)
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildProfileItem(Icons.badge, "Student ID", studentId, textColor, subTextColor),
                      Divider(color: isDark ? Colors.grey[800] : Colors.grey[200]),
                      _buildProfileItem(Icons.school, "Faculty", faculty, textColor, subTextColor),
                      Divider(color: isDark ? Colors.grey[800] : Colors.grey[200]),
                      // Use the REAL joined date here
                      _buildProfileItem(Icons.calendar_today, "Joined", joinedDate, textColor, subTextColor),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // LOGOUT BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: Text("Sign Out", style: GoogleFonts.poppins(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value, Color txtColor, Color subTxtColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A237E), size: 24),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 12, color: subTxtColor)),
              Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: txtColor)),
            ],
          )
        ],
      ),
    );
  }
}