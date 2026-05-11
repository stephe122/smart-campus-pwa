import 'package:cloud_firestore/cloud_firestore.dart';

class CampusLocation {
  final String id;
  final String name;
  final String category;
  final double lat;
  final double lng;
  final String description;
  final String imagePath;

  CampusLocation({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    required this.description,
    this.imagePath = 'assets/images/mahsa_default.jpg',
  });

  // Factory to convert Firestore Database data into App data
  factory CampusLocation.fromFirestore(DocumentSnapshot doc) {
    // 1. Safely handle potential null data from the document
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    // 2. Helper function to safely parse coordinates
    // This prevents crashes if a coordinate was accidentally saved as a String in Firebase
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble(); // Handles whole numbers
      if (value is String) return double.tryParse(value) ?? 0.0; // Converts strings to numbers
      return 0.0;
    }

    return CampusLocation(
      id: doc.id,
      
      // 3. Use ?.toString() to prevent TypeErrors if text fields are accidentally saved as numbers
      name: data['name']?.toString() ?? 'Unknown Location',
      category: data['category']?.toString() ?? 'Uncategorized',
      
      // 4. Run the coordinates through the safe parsing helper
      lat: parseDouble(data['lat']),
      lng: parseDouble(data['lng']),
      
      description: data['description']?.toString() ?? 'No description available.',
      
      // --- Added this line to safely grab the imagePath from Firebase ---
      imagePath: data['imagePath']?.toString() ?? 'assets/images/mahsa_default.jpg',
    );
  }
}