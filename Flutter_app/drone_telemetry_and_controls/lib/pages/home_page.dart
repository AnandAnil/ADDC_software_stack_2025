import 'package:drone_telemetry_and_controls/firebase_options.dart';
import 'package:drone_telemetry_and_controls/spin_drone_icons.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LatLng? currentlocation;
  final MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return;
    }
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      currentlocation = LatLng(position.latitude, position.longitude);
    });
  }

  void _goToCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      currentlocation = LatLng(position.latitude, position.longitude);
    });
    if (currentlocation != null) {
      double targetZoom =
          mapController.camera.zoom <= 5.0 ? 17.5 : mapController.camera.zoom;
      mapController.move(currentlocation!, targetZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: content(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _goToCurrentLocation,
            tooltip: 'My Location',
            child: Icon(Icons.location_pin),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {},
            tooltip: "decrement",
            child: Icon(Icons.refresh),
          )
        ],
      ),
    );
  }

  Widget content() {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: LatLng(1.2878, 103.8666),
        initialZoom: 5,
        minZoom: 2,
      ),
      children: [
        openStreetMapTileLayer,
        if (currentlocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: currentlocation!,
                width: 80,
                height: 80,
                child: GestureDetector(
                  onTap: () {
                    String convertToDMS(double coordinate, bool isLatitude) {
                      String direction = isLatitude
                          ? (coordinate >= 0 ? "N" : "S")
                          : (coordinate >= 0 ? "E" : "W");

                      coordinate = coordinate.abs();
                      int degrees = coordinate.floor();
                      double minutesDecimal = (coordinate - degrees) * 60;
                      int minutes = minutesDecimal.floor();
                      int seconds = ((minutesDecimal - minutes) * 60).round();

                      return "$degrees° $minutes' $seconds\" $direction";
                    }

                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Current Location'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Lat: ${convertToDMS(currentlocation!.latitude, true)}'),
                              Text(
                                  'Lon: ${convertToDMS(currentlocation!.longitude, false)}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Icon(
                    SpinDrone.spinDrone,
                    color: Color.fromARGB(255, 255, 0, 255),
                    size: 38,
                  ),
                ),
              )
            ],
          )
      ],
    );
  }
}

TileLayer get openStreetMapTileLayer => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
    );
