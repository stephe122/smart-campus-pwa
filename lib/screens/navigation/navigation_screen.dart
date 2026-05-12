import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mahsa_navigation/models/campus_location.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mahsa_navigation/config/secrets.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  
  static const LatLng _mahsaCenter = LatLng(2.9595, 101.5766);

  static final LatLngBounds _mahsaBounds = LatLngBounds(
    southwest: const LatLng(2.9520, 101.5710),
    northeast: const LatLng(2.9640, 101.5820),
  );

  static const String googleMapsApiKey = "Secrets.directionRoutingKey"; // Direction Routing Key

  List<CampusLocation> _locations = [];
  Set<Marker> _markers = {};
  
  Set<Polyline> _polylines = {}; 
  
  bool _isRouting = false;

  bool _hasRoute = false;
  bool _isNavigating = false;
  List<LatLng> _currentRoutePoints = [];
  Timer? _simulationTimer;
  StreamSubscription<Position>? _livePositionStream;
  String _currentDestinationName = "";

  BitmapDescriptor _personIcon = BitmapDescriptor.defaultMarker;

  String _etaString = "-- mins";
  String _distanceString = "-- m";

  FlutterTts flutterTts = FlutterTts();
  List<Map<String, dynamic>> _navigationSteps = [];
  String _currentInstruction = "Head towards destination";

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadCustomMarker();
    _fetchLocations();
    _checkLocationPermission();
  }

  void _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _loadCustomMarker() async {
    _personIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      'assets/images/walking_person.png'
    );
    setState(() {});
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _livePositionStream?.cancel();
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _fetchLocations() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('campus_locations').get();
      if (mounted) {
        setState(() {
          _locations = snapshot.docs.map((doc) => CampusLocation.fromFirestore(doc)).toList();
        });
        _createMarkers();
      }
    } catch (e) {
      debugPrint("Error fetching locations: $e");
    }
  }

  void _createMarkers() {
    Set<Marker> newMarkers = {};
    for (var loc in _locations) {
      newMarkers.add(
        Marker(
          markerId: MarkerId(loc.id),
          position: LatLng(loc.lat, loc.lng),
          onTap: () {
            if (!_isNavigating) {
              _showLocationDetails(loc);
            }
          },
        ),
      );
    }
    
    setState(() {
      _markers = newMarkers;
    });
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackBar("Location services are disabled. Please enable them in your browser.");
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnackBar("Location permissions denied.");
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _showErrorSnackBar("Location blocked by your phone. Please allow location access in your Safari/Browser settings to use navigation.");
      return false;
    }
    return true;
  }

  Future<void> _drawRoute(LatLng destination, String destName) async {
    setState(() {
      _isRouting = true;
      _hasRoute = false;
      _currentDestinationName = destName;
      _etaString = "Calculating...";
      _distanceString = "...";
      _navigationSteps.clear();
    });

    try {
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        setState(() => _isRouting = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng realStartPoint = LatLng(position.latitude, position.longitude);

      // --- Prevent routing if already standing at the destination ---
      double distanceToDestCheck = Geolocator.distanceBetween(
        realStartPoint.latitude, realStartPoint.longitude,
        destination.latitude, destination.longitude
      );

      if (distanceToDestCheck < 20.0) {
        _showErrorSnackBar("You are already at $destName!");
        setState(() => _isRouting = false);
        return; 
      }

      String destLower = destName.toLowerCase();
      LatLng apiStartPoint = realStartPoint;
      LatLng apiDestination = destination;

      // --- FORCE EXACT DESTINATION COORDINATES ---
      // This ignores slightly-off Firebase markers and targets the exact pedestrian doors
      if (destLower.contains("residence") || destLower.contains("hostel")) {
        apiDestination = const LatLng(2.958339712740769, 101.57700159161652);
      } else if (destLower.contains("empathy")) {
        apiDestination = const LatLng(2.9604590357023777, 101.57741427074535);
      }

      // --- DETERMINE START POINT (THE SNAP LOGIC) ---
      if (!_mahsaBounds.contains(realStartPoint)) {
        // OFF CAMPUS - SIMULATION MODE
        if (destLower.contains("empathy")) {
          apiStartPoint = const LatLng(2.958339712740769, 101.57700159161652); // Start at Hostel
        } else if (destLower.contains("residence") || destLower.contains("hostel")) {
          apiStartPoint = const LatLng(2.9604590357023777, 101.57741427074535); // Start at Empathy
        } else {
          apiStartPoint = const LatLng(2.958339712740769, 101.57700159161652); // Default
        }
      } else {
        // ON CAMPUS - REAL NAVIGATION MODE
        double distToEmpathy = Geolocator.distanceBetween(
          realStartPoint.latitude, realStartPoint.longitude, 
          2.9604590357023777, 101.57741427074535
        );
        double distToHostel = Geolocator.distanceBetween(
          realStartPoint.latitude, realStartPoint.longitude, 
          2.958339712740769, 101.57700159161652
        );

        // If within 50m of a building, SNAP to the exact door to prevent car-road loops!
        if (distToEmpathy < 50.0) { 
          apiStartPoint = const LatLng(2.9604590357023777, 101.57741427074535);
        } else if (distToHostel < 50.0) { 
          apiStartPoint = const LatLng(2.958339712740769, 101.57700159161652);
        } else {
          apiStartPoint = realStartPoint; 
        }
      }

      final String apiUrl = "https://maps.googleapis.com/maps/api/directions/json?origin=${apiStartPoint.latitude},${apiStartPoint.longitude}&destination=${apiDestination.latitude},${apiDestination.longitude}&mode=walking&key=$googleMapsApiKey";
      final String proxyUrl = "https://api.allorigins.win/raw?url=${Uri.encodeComponent(apiUrl)}";

      final response = await http.get(Uri.parse(proxyUrl));

      if (response.statusCode == 200) {
        final proxyData = json.decode(response.body);
        final data = json.decode(proxyData['contents']);

        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          
          var leg = data['routes'][0]['legs'][0];
          String distanceText = leg['distance']['text'];
          String durationText = leg['duration']['text'];

          List<Map<String, dynamic>> parsedSteps = [];
          for (var step in leg['steps']) {
            String rawInstruction = step['html_instructions'];
            String cleanInstruction = rawInstruction.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
            
            parsedSteps.add({
              "instruction": cleanInstruction,
              "location": LatLng(step['start_location']['lat'], step['start_location']['lng'])
            });
          }

          String polylineStr = data['routes'][0]['overview_polyline']['points'];
          PolylinePoints polylinePoints = PolylinePoints();
          List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(polylineStr);
          
          List<LatLng> polylineCoordinates = [];
          for (var point in decodedPoints) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }

          setState(() {
            _currentRoutePoints = polylineCoordinates;
            _etaString = durationText;      
            _distanceString = distanceText;

            _navigationSteps = parsedSteps;
            if (_navigationSteps.isNotEmpty) {
              _currentInstruction = _navigationSteps.first['instruction'];
            } else {
              _currentInstruction = "Head towards $_currentDestinationName";
            }

            _polylines = {
              Polyline(
                polylineId: PolylineId("route_${DateTime.now().millisecondsSinceEpoch}"),
                color: const Color(0xFF1A237E),
                points: polylineCoordinates,
                width: 6,
              )
            };
            
            _hasRoute = true;
          });

          _frameRouteOnMap(apiStartPoint, apiDestination);
          
        } else {
          String errorMsg = data['error_message'] ?? "No walking route found between these points.";
          _showErrorSnackBar("Routing issue: $errorMsg");
        }
      } else {
         _showErrorSnackBar("Failed to connect to the proxy server. Code: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorSnackBar("Routing error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isRouting = false;
        });
      }
    }
  }

  void _checkAndSpeakInstruction(LatLng currentLoc) {
    if (_navigationSteps.isEmpty) return;

    LatLng nextStepLoc = _navigationSteps.first['location'];
    
    double dist = Geolocator.distanceBetween(
      currentLoc.latitude, currentLoc.longitude,
      nextStepLoc.latitude, nextStepLoc.longitude
    );

    if (dist < 15.0) {
      String textToSpeak = _navigationSteps.first['instruction'];
      
      setState(() {
        _currentInstruction = textToSpeak;
      });
      
      flutterTts.speak(textToSpeak);
      
      _navigationSteps.removeAt(0);
    }
  }

  void _startRealNavigation(LatLng destination) {
    setState(() {
      _isNavigating = true;
      _hasRoute = false;
    });

    flutterTts.speak("Starting route. $_currentInstruction");

    _livePositionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      )
    ).listen((Position position) async {
      
      LatLng currentRealPoint = LatLng(position.latitude, position.longitude);

      _checkAndSpeakInstruction(currentRealPoint);

      double distanceToDest = Geolocator.distanceBetween(
        currentRealPoint.latitude, currentRealPoint.longitude,
        destination.latitude, destination.longitude
      );

      if (distanceToDest < 15.0) {
        _endNavigation();
        flutterTts.speak("You have arrived at $_currentDestinationName.");
        _showErrorSnackBar("You have arrived at $_currentDestinationName!");
        return;
      }

      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: currentRealPoint,
          zoom: 19.0,   
          tilt: 60.0,   
          bearing: position.heading,
        )
      ));

      if (mounted) {
        setState(() {
          _markers.removeWhere((m) => m.markerId.value == "sim_user");
          _markers.add(Marker(
            markerId: const MarkerId("sim_user"),
            position: currentRealPoint,
            rotation: position.heading,
            anchor: const Offset(0.5, 0.5),
            icon: _personIcon,
          ));
        });
      }
    });
  }

  void _startSimulation() {
    setState(() {
      _isNavigating = true;
      _hasRoute = false;
    });

    flutterTts.speak("Starting simulation. $_currentInstruction");

    int currentIndex = 0;
    
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      
      if (currentIndex >= _currentRoutePoints.length - 1) {
        timer.cancel();
        _endNavigation();
        flutterTts.speak("You have arrived at $_currentDestinationName.");
        _showErrorSnackBar("You have arrived at $_currentDestinationName!");
        return;
      }

      LatLng currentPoint = _currentRoutePoints[currentIndex];
      LatLng nextPoint = _currentRoutePoints[currentIndex + 1];
      
      _checkAndSpeakInstruction(currentPoint);

      double bearing = _calculateBearing(currentPoint, nextPoint);

      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: currentPoint,
          zoom: 19.0,   
          tilt: 60.0,   
          bearing: bearing,
        )
      ));

      List<LatLng> remainingRoute = _currentRoutePoints.sublist(currentIndex);
      
      if (mounted) {
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId("route"),
              color: const Color(0xFF1A237E),
              points: remainingRoute,
              width: 6,
            )
          };

          _markers.removeWhere((m) => m.markerId.value == "sim_user");
          _markers.add(Marker(
            markerId: const MarkerId("sim_user"),
            position: currentPoint,
            rotation: bearing,
            anchor: const Offset(0.5, 0.5),
            icon: _personIcon,
          ));
        });
      }

      currentIndex++;
    });
  }

  void _endNavigation() async {
    _simulationTimer?.cancel();
    _livePositionStream?.cancel();
    
    setState(() {
      _isNavigating = false;
      _polylines = {};
      _markers.removeWhere((m) => m.markerId.value == "sim_user");
      _currentRoutePoints.clear();
    });
    
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      const CameraPosition(target: _mahsaCenter, zoom: 18.0, tilt: 0, bearing: 0)
    ));
    _createMarkers();
  }

  double _calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * math.pi / 180.0;
    double lon1 = start.longitude * math.pi / 180.0;
    double lat2 = end.latitude * math.pi / 180.0;
    double lon2 = end.longitude * math.pi / 180.0;

    double dLon = lon2 - lon1;
    double y = math.sin(dLon) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    double bearing = math.atan2(y, x);
    return (bearing * 180.0 / math.pi + 360.0) % 360.0;
  }

  Future<void> _frameRouteOnMap(LatLng start, LatLng end) async {
    LatLngBounds bounds;
    if (start.latitude > end.latitude && start.longitude > end.longitude) {
      bounds = LatLngBounds(southwest: end, northeast: start);
    } else if (start.longitude > end.longitude) {
      bounds = LatLngBounds(
          southwest: LatLng(start.latitude, end.longitude),
          northeast: LatLng(end.latitude, start.longitude));
    } else if (start.latitude > end.latitude) {
      bounds = LatLngBounds(
          southwest: LatLng(end.latitude, start.longitude),
          northeast: LatLng(start.latitude, end.longitude));
    } else {
      bounds = LatLngBounds(southwest: start, northeast: end);
    }

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  void _showLocationDetails(CampusLocation loc) {
    setState(() {});
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]
              ),
              padding: const EdgeInsets.only(bottom: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      loc.imagePath,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        width: double.infinity,
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                        child: Icon(Icons.domain, size: 60, color: Colors.grey[500]),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.name,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          )
                        ),
                        const SizedBox(height: 5),
                        Text(
                          loc.category,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF1A237E),
                            fontWeight: FontWeight.w600
                          )
                        ),
                        const SizedBox(height: 10),
                        Text(
                          loc.description,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                        
                        const SizedBox(height: 25),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isRouting ? null : () async {
                              final nav = Navigator.of(context);
                              
                              setModalState(() => _isRouting = true);
                              
                              await _drawRoute(LatLng(loc.lat, loc.lng), loc.name);
                              
                              nav.pop();
                            },
                            icon: _isRouting
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.navigation, color: Colors.white),
                            label: Text(
                              _isRouting ? "CALCULATING..." : "GET ROUTE",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A237E),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          }
        );
      },
    ).whenComplete(() {
      setState(() => _isRouting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _mahsaCenter,
              zoom: 18.0,
            ),
            cameraTargetBounds: CameraTargetBounds(_mahsaBounds),
            minMaxZoomPreference: const MinMaxZoomPreference(16.0, 19.5),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: !_isNavigating,
            compassEnabled: !_isNavigating,
            padding: EdgeInsets.only(top: _isNavigating ? 130 : 100, bottom: _isNavigating ? 130 : 80),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),

          if (!_isNavigating) ...[
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                child: ListTile(
                  leading: const Icon(Icons.search, color: Colors.grey),
                  title: Text("Where to?", style: GoogleFonts.poppins(color: Colors.grey)),
                  onTap: () {
                    showSearch(context: context, delegate: LocationSearchDelegate(_locations, _showLocationDetails));
                  },
                ),
              ),
            ),
            
            Positioned(
              bottom: 30,
              left: 20,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                child: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],

          if (_hasRoute && !_isNavigating)
            Positioned(
              bottom: 30,
              left: 80,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () => _startRealNavigation(_currentRoutePoints.last),
                        icon: const Icon(Icons.directions_walk, color: Colors.white),
                        label: Text("START", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          elevation: 8,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _startSimulation,
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        label: Text("SIMULATE", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          elevation: 8,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_isNavigating) ...[
            Positioned(
              top: 40,
              left: 15,
              right: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.turn_right, color: Colors.white, size: 40),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("towards $_currentDestinationName", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                          Text(_currentInstruction, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 20,
              left: 15,
              right: 15,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ETA: $_etaString", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700])),
                        Text("Distance: $_distanceString", style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _endNavigation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text("Exit", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

// SEARCH DELEGATE
class LocationSearchDelegate extends SearchDelegate {
  final List<CampusLocation> locations;
  final Function(CampusLocation) onSelected;

  LocationSearchDelegate(this.locations, this.onSelected);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = isDark ? Colors.grey[800] : Colors.grey[100];
    final borderColor = isDark ? Colors.grey[600]! : Colors.grey[300]!;

    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgColor,
        hintStyle: const TextStyle(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          onPressed: () => query = '',
          icon: const Icon(Icons.clear)
        )
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        onPressed: () => close(context, null),
        icon: const Icon(Icons.arrow_back)
      );

  @override
  Widget buildResults(BuildContext context) => Container();

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = locations
        .where((loc) => loc.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final loc = suggestions[index];
        return ListTile(
          title: Text(loc.name),
          subtitle: Text(loc.category),
          leading: const Icon(Icons.location_on, color: Color(0xFF1A237E)),
          onTap: () {
            close(context, null);
            onSelected(loc);
          },
        );
      },
    );
  }
}