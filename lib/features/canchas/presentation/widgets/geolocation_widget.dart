import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeolocationWidget extends StatefulWidget {
  final double latitude;
  final double longitude;

  const GeolocationWidget({super.key, required this.latitude, required this.longitude});

  @override
  State<GeolocationWidget> createState() => _GeolocationWidgetState();
}

class _GeolocationWidgetState extends State<GeolocationWidget> {
  late GoogleMapController _mapController;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.latitude, widget.longitude),
        zoom: 15,
      ),
      markers: {
        Marker(
          markerId: const MarkerId("cancha"),
          position: LatLng(widget.latitude, widget.longitude),
        ),
      },
    );
  }
}
