import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final String? destinationCity;
  final String? selectedHotel;
  final String? meetingVenue;
  
  const MapScreen({
    super.key,
    this.destinationCity,
    this.selectedHotel,
    this.meetingVenue,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  List<Marker> _markers = [];
  List<Map<String, dynamic>> _nearbyPlaces = [];
  bool _isLoading = false;
  String _selectedTab = 'hotels';
  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  String? _distanceText;
  
  final Map<String, LatLng> _cityCoordinates = {
    'Paris': LatLng(48.8566, 2.3522),
    'London': LatLng(51.5074, -0.1278),
    'New York': LatLng(40.7128, -74.0060),
    'Tokyo': LatLng(35.6762, 139.6503),
    'Dubai': LatLng(25.2048, 55.2708),
    'Lagos': LatLng(6.5244, 3.3792),
    'Rome': LatLng(41.9028, 12.4964),
    'Barcelona': LatLng(41.3851, 2.1734),
    'Berlin': LatLng(52.5200, 13.4050),
    'Amsterdam': LatLng(52.3676, 4.9041),
  };

  final Map<String, LatLng> _hotelCoordinates = {
    'City Budget Inn': LatLng(48.8600, 2.3600),
    'Comfort Stay Hotel': LatLng(48.8650, 2.3450),
    'Grand Central Hotel': LatLng(48.8700, 2.3550),
    'Marina Boutique Hotel': LatLng(48.8750, 2.3650),
    'The Royal Palace Hotel': LatLng(48.8800, 2.3500),
    'Presidential Suites': LatLng(48.8850, 2.3700),
  };

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
    _setupInitialMarkers();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      
      _addMarker(
        _currentLocation!,
        'Your Location',
        Icons.my_location,
        Colors.blue,
      );
      
      _mapController.move(_currentLocation!, 13);
      
    } catch (e) {
      debugPrint('Error getting location: $e');
      _centerOnDestination();
    }
  }

  void _setupInitialMarkers() {
    if (widget.destinationCity != null && 
        _cityCoordinates.containsKey(widget.destinationCity)) {
      _destinationLocation = _cityCoordinates[widget.destinationCity!];
      _addMarker(
        _destinationLocation!,
        widget.destinationCity!,
        Icons.location_city,
        Colors.red,
      );
    }

    if (widget.selectedHotel != null && 
        _hotelCoordinates.containsKey(widget.selectedHotel)) {
      final hotelLocation = _hotelCoordinates[widget.selectedHotel];
      if (hotelLocation != null) {
        _addMarker(
          hotelLocation,
          widget.selectedHotel!,
          Icons.hotel,
          Colors.green,
        );
      }
    }

    if (widget.meetingVenue != null && _destinationLocation != null) {
      final venueLocation = LatLng(
        _destinationLocation!.latitude + 0.01,
        _destinationLocation!.longitude + 0.01,
      );
      _addMarker(
        venueLocation,
        widget.meetingVenue!,
        Icons.meeting_room,
        Colors.orange,
      );
    }
  }

  void _addMarker(LatLng point, String title, IconData icon, Color color) {
    setState(() {
      _markers.add(
        Marker(
          point: point,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showMarkerDetails(title, point),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      );
    });
  }

  void _showMarkerDetails(String title, LatLng location) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Coordinates: ${location.latitude.toStringAsFixed(4)}, '
                 '${location.longitude.toStringAsFixed(4)}'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _mapController.move(location, 15);
              },
              icon: const Icon(Icons.navigation),
              label: const Text('Center on Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _centerOnDestination() {
    if (widget.destinationCity != null && 
        _cityCoordinates.containsKey(widget.destinationCity)) {
      _destinationLocation = _cityCoordinates[widget.destinationCity!];
      _mapController.move(_destinationLocation!, 12);
    } else {
      _destinationLocation = const LatLng(48.8566, 2.3522);
      _mapController.move(_destinationLocation!, 12);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destinationCity != null 
          ? 'Map - ${widget.destinationCity}' 
          : 'Travel Map'),
        backgroundColor: const Color(0xFF0EADBB),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              onTap: (index) {
                setState(() {
                  _selectedTab = index == 0 ? 'hotels' : index == 1 ? 'restaurants' : 'attractions';
                });
              },
              tabs: const [
                Tab(text: '🏨 Hotels', icon: Icon(Icons.hotel)),
                Tab(text: '🍽️ Restaurants', icon: Icon(Icons.restaurant)),
                Tab(text: '🏛️ Attractions', icon: Icon(Icons.tour)),
              ],
              labelColor: const Color(0xFF0EADBB),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF0EADBB),
            ),
          ),
          
          Expanded(
            flex: 3,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(48.8566, 2.3522),
                initialZoom: 12,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: _markers,
                ),
              ],
            ),
          ),
          
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _selectedTab == 'hotels' 
                      ? '📍 Hotels Nearby' 
                      : _selectedTab == 'restaurants'
                        ? '🍽️ Restaurants Nearby'
                        : '🏛️ Attractions Nearby',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildHotelsList(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_destinationLocation != null) {
            _mapController.move(_destinationLocation!, 14);
          } else {
            _centerOnDestination();
          }
        },
        backgroundColor: const Color(0xFF0EADBB),
        child: const Icon(Icons.center_focus_strong, color: Colors.white),
      ),
    );
  }

  Widget _buildHotelsList() {
    final hotels = [
      'City Budget Inn',
      'Comfort Stay Hotel', 
      'Grand Central Hotel',
      'Marina Boutique Hotel',
      'The Royal Palace Hotel',
      'Presidential Suites',
    ];
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: hotels.length,
      itemBuilder: (context, index) {
        final hotel = hotels[index];
        final isSelected = widget.selectedHotel == hotel;
        final location = _hotelCoordinates[hotel];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected 
                ? BorderSide(color: const Color(0xFF0EADBB), width: 2)
                : BorderSide.none,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected 
                  ? const Color(0xFF0EADBB) 
                  : Colors.grey.shade200,
              child: Icon(
                Icons.hotel,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
            title: Text(
              hotel,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.navigation),
              onPressed: () {
                if (location != null) {
                  _mapController.move(location, 15);
                  _showMarkerDetails(hotel, location);
                }
              },
              color: const Color(0xFF0EADBB),
            ),
          ),
        );
      },
    );
  }
}