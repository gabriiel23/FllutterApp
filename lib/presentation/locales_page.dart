import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocalesPage extends StatefulWidget {
  const LocalesPage({super.key});

  @override
  State<LocalesPage> createState() => _LocalesPageState();
}

class _LocalesPageState extends State<LocalesPage> {
  final Map<MarkerId, Marker> _markers = {};
  final LatLng _initialPosition = const LatLng(-2.8974, -79.0045); // Coordenadas iniciales (pueden ser las de tu ciudad)

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  void _loadMarkers() {
    final marker1 = Marker(
      markerId: const MarkerId("local1"),
      position: const LatLng(-2.8974, -79.0045),
      infoWindow: const InfoWindow(
        title: "Complejo Deportivo Loja",
        snippet: "Cancha, Piscina, Sauna, Turco",
      ),
      onTap: () {
        _showDetails(
          name: "Complejo Deportivo Loja",
          services: "Piscina, Sauna, Turco, Alquiler de equipos",
          horarios: "Lunes a Domingo: 7 AM - 10 PM",
        );
      },
    );

    final marker2 = Marker(
      markerId: const MarkerId("local2"),
      position: const LatLng(-2.8956, -79.0067),
      infoWindow: const InfoWindow(
        title: "Cancha FutbolManía",
        snippet: "Cancha de césped sintético",
      ),
      onTap: () {
        _showDetails(
          name: "Cancha FutbolManía",
          services: "Solo cancha disponible",
          horarios: "Lunes a Viernes: 8 AM - 8 PM",
        );
      },
    );

    setState(() {
      _markers[marker1.markerId] = marker1;
      _markers[marker2.markerId] = marker2;
    });
  }

  void _showDetails({
    required String name,
    required String services,
    required String horarios,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Servicios: $services",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                "Horarios: $horarios",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  print("Reserva iniciada para $name");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text("Reservar Ahora"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Locales"),
        backgroundColor: Colors.green,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 14.0,
        ),
        markers: Set<Marker>.of(_markers.values),
      ),
    );
  }
}
