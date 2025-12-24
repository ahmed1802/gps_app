import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? _mapController;
  final Location _location = Location();

  // Default location: Algiers, Algeria
  static const LatLng _defaultLocation = LatLng(36.7392115, 2.9992443);

  Set<Marker> _markers = {};
  String _addressText = 'Tap the GPS button to get your location';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Google Map
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: const CameraPosition(
                target: _defaultLocation,
                zoom: 12,
              ),
              markers: _markers,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
            ),

            // GPS Button (top-left)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.gps_fixed, color: Colors.blue),
                  onPressed: _getMyPosition,
                ),
              ),
            ),

            // Address container (bottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      _addressText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getMyPosition() async {
    // Check if location service is enabled
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        _showError('Location service is disabled');
        return;
      }
    }

    // Check location permission
    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted) {
        _showError('Location permission denied');
        return;
      }
    }

    // Get current location
    try {
      LocationData locationData = await _location.getLocation();

      if (locationData.latitude == null || locationData.longitude == null) {
        _showError('Could not get location');
        return;
      }

      final LatLng userLocation = LatLng(
        locationData.latitude!,
        locationData.longitude!,
      );

      // Add marker at current position
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('current_location'),
            position: userLocation,
            infoWindow: const InfoWindow(
              title: 'My Location',
              snippet: 'You are here',
            ),
          ),
        };
      });

      // Animate camera to user's location
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: userLocation, zoom: 14),
        ),
      );

      // Reverse geocoding to get address
      await _reverseGeocode(locationData.latitude!, locationData.longitude!);
    } catch (e) {
      _showError('Error getting location: $e');
    }
  }

  Future<void> _reverseGeocode(double latitude, double longitude) async {
    try {
      List<geocoding.Placemark> placemarks = await geocoding
          .placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks.first;

        // Build address string with country, administrative area, and sub-administrative area
        List<String> addressParts = [];

        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          addressParts.add(place.subAdministrativeArea!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        setState(() {
          _addressText = addressParts.isNotEmpty
              ? addressParts.join(', ')
              : 'Address not available';
        });
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      setState(() {
        _addressText = 'Could not determine address';
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
