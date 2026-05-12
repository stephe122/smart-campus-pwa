# 🗺️ MAHSA Smart Campus Navigation And Service Web App 

A cross-platform, full-stack navigation progressive web app (PWA) built to solve complex outdoor routing for university campuses. Engineered with Flutter, Firebase, and the Google Maps Platform.

**🔗 [View Live Application](https://mahsa-smart-campus-navig-81bae.web.app/)**

## 🚀 Overview
Navigating a sprawling university campus can be overwhelming for new students and visitors. This application provides real-time, highly accurate routing to specific campus landmarks (e.g., Empathy Building, and Mahsa Student Residence Hostel) bypassing the limitations of standard GPS routing which often fails to map internal campus walkways.

## ✨ Key Features
* **Interactive Campus Mapping:** Custom Google Maps integration specifically bounded and optimized for the university footprint.
* **Dynamic Route Generation:** Implements the Google Maps Directions API via a secure CORS proxy to generate accurate pedestrian polylines.
* **Progressive Web App (PWA):** Fully deployable as a web application with mobile-native responsiveness.
* **Enterprise-Grade Security:** * API keys secured via strict Google Cloud Platform (GCP) HTTP Referrer restrictions.
  * API scoping limited strictly to Maps JavaScript and Directions APIs.
  * Sensitive configuration files abstracted and `.gitignore` protected.

## 🛠️ Tech Stack & Architecture
* **Frontend:** Flutter (Dart)
* **Backend / Hosting:** Firebase Hosting
* **Mapping Engine:** Google Maps Platform (Maps JavaScript API, Directions API)
* **Networking:** Handled complex Cross-Origin Resource Sharing (CORS) policies using proxy routing for secure API communication on web targets.

## 🧠 Technical Challenges Overcome
1. **Web-Specific CORS Restrictions:** Bypassed strict browser CORS policies when querying the Directions API by engineering a proxy routing solution, allowing seamless polyline generation on the live web.
2. **Cloud Security Protocols:** Successfully navigated GCP's stringent security requirements, implementing HTTP Referrer wildcards to secure the Maps API on a public Firebase Hosting domain while preventing quota theft.

## 💻 Local Execution
To run this project locally, ensure you have the Flutter SDK installed.

1. Clone the repository.
2. Run `flutter pub get` to fetch dependencies.
3. *Note: You will need to provide your own Google Maps API keys in a `lib/config/secrets.dart` file to enable mapping features locally.*
4. Run `flutter run -d chrome` to launch the web instance.

---
*Designed and developed to prioritize clean, responsive user interfaces and robust backend integration.*