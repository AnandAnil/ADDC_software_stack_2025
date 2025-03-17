import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drone_telemetry_and_controls/spin_drone_icons.dart';
import 'package:drone_telemetry_and_controls/services/firestore.dart';
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

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin{
  LatLng? currentlocation;
  final FirestoreService firestoreService = FirestoreService();
  final MapController mapController = MapController();
  LatLng? lastFocusedPoint;
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Add this method for smooth map animations
  void animatedMapMove(LatLng destLocation, double destZoom) {
    // Skip if we're already at this location
    if (lastFocusedPoint != null &&
        lastFocusedPoint!.latitude == destLocation.latitude &&
        lastFocusedPoint!.longitude == destLocation.longitude) {
      return;
    }

    // Update our tracking variable
    lastFocusedPoint = destLocation;

    // Create controller for animation
    final latTween = Tween<double>(
        begin: mapController.camera.center.latitude,
        end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: mapController.camera.center.longitude,
        end: destLocation.longitude);
    final zoomTween =
        Tween<double>(begin: mapController.camera.zoom, end: destZoom);

    // Create animation controller
    final controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    final Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void showDeleteDialog({String? docID}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docID == null ? 'Clear Database' : 'Delete Entry'),
        content: Text(docID == null
            ? 'Are you sure you want to clear all notes?'
            : 'Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              docID == null
                  ? firestoreService.deleteAllNotes()
                  : firestoreService.deleteNote(docID);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
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
      animatedMapMove(currentlocation!, targetZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: content(),
      floatingActionButton: Column(
        spacing: 16,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              Position position = await Geolocator.getCurrentPosition();
              firestoreService.addNote(position.latitude, position.longitude);
            },
            tooltip: 'Add Location',
            child: Icon(Icons.add_rounded),
          ),
          FloatingActionButton(
            onPressed: _goToCurrentLocation,
            tooltip: 'My Location',
            child: Icon(Icons.location_pin),
          ),
          FloatingActionButton(
            onPressed: showDeleteDialog,
            tooltip: "decrement",
            child: Icon(Icons.delete),
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
        StreamBuilder<QuerySnapshot>(
          stream: firestoreService.getNoteStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            List<LatLng> points = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return LatLng(data['latitude'], data['longitude']);
            }).toList();
            // Auto-focus on the last point when new data arrives
            if (points.isNotEmpty) {
              // Use Future.delayed to avoid calling setState during build
              Future.delayed(Duration.zero, () {
                
                animatedMapMove(points.last, 18.4);
              });
            }
            return Stack(
              children: [
                if (points.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points,
                        color: Colors.blue,
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: points.asMap().entries.map(
                    (entry) {
                      int idx = entry.key;
                      LatLng point = entry.value;
                      bool isLastPoint = idx == points.length - 1;

                      return Marker(
                        point: point,
                        width: isLastPoint ? 40 : 40,
                        height: isLastPoint ? 40 : 40,
                        child: GestureDetector(
                          onTap: () {
                            final data = snapshot.data!.docs[idx].data()
                                as Map<String, dynamic>;
                            final Timestamp timestamp = data['timestamp'];
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Time: ${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}:${timestamp.toDate().second.toString().padLeft(2, '0')}, Date: ${timestamp.toDate().day.toString().padLeft(2, '0')}/${timestamp.toDate().month.toString().padLeft(2, '0')}/${timestamp.toDate().year.toString().padLeft(4, '0')}'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: isLastPoint
                              ? const Icon(
                                  SpinDrone.spinDrone,
                                  color: Colors.red,
                                  size: 40,
                                )
                              : const Icon(
                                  Icons.adjust_rounded,
                                  color: Colors.orange,
                                  size: 30,
                                ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ],
            );
          },
        ),
        if (currentlocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: currentlocation!,
                width: 80,
                height: 80,
                child: GestureDetector(
                  onTap: () {
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
                                  'Lat: ${currentlocation!.latitude.toString()}'),
                              Text(
                                  'Lon: ${currentlocation!.longitude.toString()}'),
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
