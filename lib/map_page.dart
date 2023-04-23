import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:geocoding/geocoding.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _controller;
  Set<Marker> _markers = {};
  LatLng? _selectedLatLng;
  String? _selectedAddress;

  TextEditingController _searchController = TextEditingController();

  // Add your Google Maps API Key here
  final places = GoogleMapsPlaces(apiKey: 'AIzaSyB43pS0d30i-AkO4jZs7qUsMi0fupfzOAw');

  Future<String?> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      Placemark placemark = placemarks.first;
      return '${placemark.street}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}';
    } catch (e) {
      print(e);
      return null;
    }
  }

  void _onMapTap(LatLng latLng) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Location'),
          content: Text('Do you want to select this location?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      String? address = await _getAddressFromLatLng(latLng);
      if (address != null) {
        setState(() {
          _markers.clear(); // Clear previous marker
          _markers.add(
            Marker(
              markerId: MarkerId('selected_location'),
              position: latLng,
            ),
          );
          _selectedAddress = address;
        });
        print('Selected Address: $address');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get address. Please try again.')));
      }
    }
  }

  Future<void> _searchLocation() async {
    PlacesSearchResponse response = await places.searchByText(_searchController.text);

    if (response.status == 'OK' && response.results.isNotEmpty) {
      PlacesSearchResult result = response.results.first;
      LatLng target = LatLng(
          result.geometry?.location?.lat ?? 37.42796133580664,
          result.geometry?.location?.lng ?? -122.085749655962
      );

      _controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 14.0)));

      _onMapTap(target);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location not found!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text('Select Location'),
        ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(37.42796133580664, -122.085749655962),
              zoom: 14.4746,
            ),
            onTap: _onMapTap,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
            },
          ),
          // Add search box
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for a location...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _searchLocation,
                    icon: Icon(Icons.search),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedAddress != null) {
            Navigator.pop(context, _selectedAddress);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a location')));
          }
        },
        child: Icon(Icons.check),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
