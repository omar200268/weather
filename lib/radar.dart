import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RadarPage extends StatefulWidget {
  const RadarPage({super.key});

  @override
  _RadarPageState createState() => _RadarPageState();
}

class _RadarPageState extends State<RadarPage> {
  late GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar'),
      ),
      body: GoogleMap(
        onMapCreated: (controller) {
          mapController = controller;
        },
        initialCameraPosition: const CameraPosition(
          target: LatLng(0, 0), // Dünya haritasının merkezi
          zoom: 1,
        ),
        mapType: MapType.normal, // Normal harita görünümü
      ),
    );
  }
}
