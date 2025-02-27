import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: lightDynamic,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic,
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
          home: const MyHomePage(title: 'Flutter Demo Home Page'),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LatLng? currentlocation;
  final MapController mapController = MapController();
  int _counter = 0;

  void _incrementCounter() {
    print("increment button pressed");
    setState(() {
      _counter++;
    });
  }

  void _refresh() {
    print("reset button pressed");
    setState(() {
      _counter = 0;
    });
  }

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

  void _goToCurrentLocation() {
    if (currentlocation != null) {
      mapController.move(currentlocation!, 17.5);
    }
  }

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
            onPressed: _refresh,
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
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
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
