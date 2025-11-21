import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

// Assuming this path for your LocationService
import 'package:smartsan_app/features/community_reporting/domain/services/location_service.dart';

/// The model returned by the picker screen containing the selected coordinates.
class PickedLocation {
  final double latitude;
  final double longitude;
  final String address; // Optional: for display purposes

  PickedLocation({required this.latitude, required this.longitude, this.address = 'Picked Location'});
}

class LocationPickerScreen extends StatefulWidget {
  // Optional initial location, defaults to a neutral spot (e.g., a specific city center)
  final double initialLat;
  final double initialLng;

  const LocationPickerScreen({
    super.key,
    this.initialLat = 0.0, // Default to 0, 0 if not provided
    this.initialLng = 0.0,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final LocationService _locationService = LocationService();
  
  // Controller to manage the map
  GoogleMapController? _mapController; 

  // The coordinates at the center of the visible map area
  LatLng? _pickedLocation; 

  // The initial camera position to display when the map loads
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(0.0, 0.0), // Default to 0,0 (Atlantic) before fetching location
    zoom: 1.0,
  );

  bool _isLoading = true;
  String _loadingMessage = 'Initializing map...';

  @override
  void initState() {
    super.initState();
    _determineInitialPosition();
  }

  /// Tries to get the current location of the device to set the initial camera position.
  Future<void> _determineInitialPosition() async {
    try {
      setState(() {
        _loadingMessage = 'Checking permissions and fetching location...';
      });
      
      Position position = await _locationService.getCurrentLocation();
      
      final initialPosition = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _initialCameraPosition = CameraPosition(
          target: initialPosition,
          zoom: 17.0, // Zoomed in for precision
        );
        _pickedLocation = initialPosition;
        _isLoading = false;
      });

    } on Exception catch (e) {
      // If location fails (e.g., denied permissions), use the default initial values
      final defaultPosition = LatLng(widget.initialLat, widget.initialLng);

      setState(() {
        _initialCameraPosition = CameraPosition(
          target: defaultPosition,
          zoom: 10.0,
        );
        _pickedLocation = defaultPosition;
        _isLoading = false;
        // Show error message if not using the default
        if (widget.initialLat == 0.0) {
           _loadingMessage = 'Map loaded, but failed to fetch current GPS: ${e.toString()}';
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(_loadingMessage)),
           );
        }
      });
    }
  }

  /// Called when the map camera stops moving (user lifts finger after panning/zooming).
  void _onCameraIdle() async {
    if (_mapController != null) {
      final center = await _mapController!.getVisibleRegion();
      final newCenter = LatLng(
        (center.northeast.latitude + center.southwest.latitude) / 2,
        (center.northeast.longitude + center.southwest.longitude) / 2,
      );
      
      // Update the state only if the location has actually changed
      if (_pickedLocation == null || newCenter.latitude != _pickedLocation!.latitude || newCenter.longitude != _pickedLocation!.longitude) {
         setState(() {
          _pickedLocation = newCenter;
        });
      }
    }
  }

  /// Handles returning the selected location to the calling screen.
  void _selectLocation() {
    if (_pickedLocation != null) {
      Navigator.pop(
        context,
        PickedLocation(
          latitude: _pickedLocation!.latitude,
          longitude: _pickedLocation!.longitude,
        ),
      );
    } else {
      // Should not happen if map is initialized correctly
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for the map to load.')),
      );
    }
  }
  
  // Custom marker icon to indicate the center of the map view
  Set<Marker> _buildMarkers() {
    if (_pickedLocation == null) return {};
    return {
      Marker(
        markerId: const MarkerId('pickedLocation'),
        position: _pickedLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Report Location'),
      ),
    };
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Issue Location'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _selectLocation,
            tooltip: 'Confirm Location',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.green),
                  const SizedBox(height: 16),
                  Text(_loadingMessage),
                ],
              ),
            )
          : Stack(
              children: [
                // 1. The Google Map Widget
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _initialCameraPosition,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onCameraIdle: _onCameraIdle, // Update picked location when panning stops
                  myLocationEnabled: true, // Shows the user's current position dot
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  markers: _buildMarkers(),
                ),
                
                // 2. Crosshair/Pin in the center (better UX than relying on markers)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 40), // Offset slightly to align with marker base
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 48,
                    ),
                  ),
                ),

                // 3. Confirm Button (also placed in AppBar, but sometimes good to have here)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: ElevatedButton.icon(
                    onPressed: _selectLocation,
                    icon: const Icon(Icons.send),
                    label: const Text('Confirm Location', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}