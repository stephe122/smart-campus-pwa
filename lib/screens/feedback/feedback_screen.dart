import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http; // <--- Import for Email

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _messageController = TextEditingController();
  String _selectedCategory = 'Bug Report';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Bug Report',
    'Suggestion',
    'Navigation Error',
    'Other'
  ];

  // --- EMAIL SENDING FUNCTION ---
  Future<void> _sendEmailNotification(String category, String message, String userEmail) async {
    const serviceId = "service_68icxrv";   // Your Service ID
    const templateId = "template_garfwfe"; // Your Template ID
    const publicKey = "kJWjiolA9lIvcJvKz";   // Your Public Key

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    
    try {
      await http.post(
        url,
        headers: {
          'origin': 'http://localhost', // Required for Web apps
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'category': category,
            'message': message,
            'user_email': userEmail,
          }
        }),
      );
      debugPrint("Email Sent Successfully!");
    } catch (e) {
      debugPrint("Failed to send email: $e");
    }
  }

  Future<void> _submitFeedback() async {
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please type a message first.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userEmail = user?.email ?? 'Anonymous';

      // 1. Send to Firestore (Database)
      await FirebaseFirestore.instance.collection('feedback').add({
        'category': _selectedCategory,
        'message': message,
        'user_email': userEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // 2. Send Email to You (The Admin)
      await _sendEmailNotification(_selectedCategory, message, userEmail);

      // 3. Show Success
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Thank You!"),
            content: const Text("Your feedback has been sent directly to the admin."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Check Dark Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 2. Define Dynamic Colors
    final textColor = isDark ? Colors.white : Colors.black;
    final iconColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final cardColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey.shade400;

    return Scaffold(
      // Let main.dart handle the scaffold background color
      appBar: AppBar(
        backgroundColor: bgColor, // <--- Dynamic AppBar BG
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor), // <--- Dynamic Icon Color
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "FEEDBACK",
          style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.bold), // <--- Dynamic Text Color
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A237E).withValues(alpha: 0.2) : const Color(0xFFE8EAF6), // <--- Dynamic Banner BG
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF1A237E)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.feedback, color: Color(0xFF1A237E), size: 30),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "Your feedback helps us improve MAHSA Smart Campus Navigation App.",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1A237E), // <--- Dynamic Banner Text
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Category Dropdown
            Text("Category", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor)), // <--- Dynamic Text
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: inputFillColor, // <--- Dynamic Input BG
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor), // <--- Dynamic Border
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  dropdownColor: cardColor, // <--- Dynamic Dropdown Menu BG
                  isExpanded: true,
                  style: GoogleFonts.poppins(color: textColor, fontSize: 14), // <--- Dynamic Selected Text
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Message Field
            Text("Feedback", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor)), // <--- Dynamic Text
            const SizedBox(height: 10),
            TextField(
              controller: _messageController,
              maxLines: 5,
              maxLength: 500,
              style: GoogleFonts.poppins(color: textColor), // <--- Dynamic Typing Text Color
              decoration: InputDecoration(
                hintText: "Tell us what happened...",
                hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]), // <--- Dynamic Hint Color
                fillColor: inputFillColor, // <--- Dynamic Input BG
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder( // <--- Added to ensure border color is correct when not focused
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "SUBMIT FEEDBACK",
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}