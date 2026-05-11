import 'package:cloud_firestore/cloud_firestore.dart';

class CampusEvent {
  final String id;
  final String title;
  final String date;
  final String time;
  final String venue;
  final String description;
  final String imageUrl; // <--- REQUIRED FIELD

  CampusEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.venue,
    required this.description,
    required this.imageUrl,
  });

  factory CampusEvent.fromFirestore(DocumentSnapshot doc) {
    // 1. Safely cast the data and handle the rare case where doc.data() is totally null
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    return CampusEvent(
      id: doc.id,
      
      // 2. Add ?.toString() to completely prevent TypeErrors if a field 
      // was accidentally saved as a Number in the Firebase console.
      title: data['title']?.toString() ?? 'Untitled Event',
      date: data['date']?.toString() ?? 'TBA',
      time: data['time']?.toString() ?? 'TBA',
      venue: data['venue']?.toString() ?? 'TBA',
      description: data['description']?.toString() ?? 'No description available.',
      
      // 3. Ensure the image URL isn't just an empty string '' that would break Image.network
      imageUrl: (data['imageUrl'] != null && data['imageUrl'].toString().trim().isNotEmpty)
          ? data['imageUrl'].toString()
          : 'https://mahsa.edu.my/images/mahsa-logo.png', // Fallback MAHSA placeholder
    );
  }
}