import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mahsa_navigation/models/event_model.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Check Dark Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 2. Define Dynamic Colors
    final textColor = isDark ? Colors.white : Colors.black;
    final iconColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgColor, // <--- Dynamic AppBar BG
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor), // <--- Dynamic Icon Color
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "EVENTS",
          style: GoogleFonts.poppins(
            color: textColor, // <--- Dynamic Text Color
            fontWeight: FontWeight.bold
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').orderBy('date').snapshots(),
        builder: (context, snapshot) {
          // 1. Error State (Crucial for catching missing Firebase indexes or permission issues)
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Something went wrong: ${snapshot.error}",
                style: GoogleFonts.poppins(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          // 2. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3. Empty State
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No upcoming events.", 
                style: GoogleFonts.poppins(color: isDark ? Colors.grey[400] : Colors.grey[600])
              ),
            );
          }

          // 4. Display List (Wrapped in a try-catch to prevent a single bad Firebase doc from breaking the screen)
          final events = <CampusEvent>[];
          for (var doc in snapshot.data!.docs) {
            try {
              events.add(CampusEvent.fromFirestore(doc));
            } catch (e) {
              // If you made a typo in the Firebase console, this catches it!
              debugPrint("Error parsing event document ${doc.id}: $e");
            }
          }

          // 5. Fallback if all documents had formatting errors
          if (events.isEmpty) {
            return Center(
              child: Text(
                "Events are currently unavailable due to a formatting error.", 
                style: GoogleFonts.poppins(color: isDark ? Colors.grey[400] : Colors.grey[600])
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventCard(context, event, isDark); // Pass isDark to helper
            },
          );
        },
      ),
    );
  }

  // Helper Widget to draw the Card (With Image, Description, and Details)
  Widget _buildEventCard(BuildContext context, CampusEvent event, bool isDark) {
    // Dynamic Card Colors
    final cardBgColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1A237E);
    final descColor = isDark ? Colors.grey[400] : Colors.grey[700];
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey.shade300;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      // No padding here so the image can touch the edges
      decoration: BoxDecoration(
        color: cardBgColor, // <--- Dynamic Background
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // Fixed deprecation
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 1. EVENT IMAGE (Banner)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              event.imageUrl,
              height: 150, // Fixed height for the banner
              width: double.infinity,
              fit: BoxFit.cover, // Ensures image fills the area without stretching
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image fails to load
                return Container(
                  height: 150,
                  width: double.infinity,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                  ),
                );
              },
            ),
          ),

          // 2. TEXT CONTENT (Padding applied only to text area)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Title
                Text(
                  event.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor, // <--- Dynamic Title Color
                  ),
                ),
                const SizedBox(height: 10),

                // Description 
                Text(
                  event.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: descColor, // <--- Dynamic Description Color
                  ),
                ),
                const SizedBox(height: 15),

                // Time and Date Row
                Row(
                  children: [
                    _buildTag(event.date, Icons.calendar_today, isDark),
                    const SizedBox(width: 10),
                    _buildTag(event.time, Icons.access_time, isDark),
                  ],
                ),
                const SizedBox(height: 15),

                // Venue Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A237E).withValues(alpha: 0.2) : const Color(0xFFE8EAF6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1A237E)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Color(0xFF1A237E)), // Keep Blue
                      const SizedBox(width: 5),
                      Text(
                        event.venue,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1A237E), // White text on dark mode
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Tags (With Icons)
  Widget _buildTag(String text, IconData icon, bool isDark) {
    final tagBgColor = isDark ? Colors.transparent : Colors.white;
    final tagBorderColor = isDark ? Colors.grey[700]! : Colors.grey.shade400;
    final tagTextColor = isDark ? Colors.grey[300] : Colors.grey[800];
    final tagIconColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tagBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tagBorderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: tagIconColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tagTextColor,
            ),
          ),
        ],
      ),
    );
  }
}