import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_planner/services/firestore.dart';
import 'package:latlong2/latlong.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  LatLng? currentlocation;
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController textController = TextEditingController();

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

  void openNoteBox({String? docID}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: textController,
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Position position = await Geolocator.getCurrentPosition();
              if (docID == null) {
                firestoreService.addNote(
                  textController.text,
                  position.latitude,
                  position.longitude,
                );
              } else {
                firestoreService.updateNote(docID, textController.text);
              }
              textController.clear();
              Navigator.pop(context);
            },
            child: Text('Add Location'),
          ),
        ],
      ),
    );
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

  String convertToDMS(double coordinate, bool isLatitude) {
    String direction = isLatitude
        ? (coordinate >= 0 ? "N" : "S")
        : (coordinate >= 0 ? "E" : "W");

    coordinate = coordinate.abs();
    int degrees = coordinate.floor();
    double minutesDecimal = (coordinate - degrees) * 60;
    int minutes = minutesDecimal.floor();
    int seconds = ((minutesDecimal - minutes) * 60).round();

    if (seconds == 60) {
      minutes += 1;
      seconds = 0;
      if (minutes == 60) {
        degrees += 1;
        minutes = 0;
      }
    }
    String degreesStr = degrees.toString().padLeft(2, '0');
    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = seconds.toString().padLeft(2, '0');

    return "$degreesStr° $minutesStr' $secondsStr\" $direction";
  }

  void clearDatabase() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Database'),
        content: Text('Are you sure you want to clear all notes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              firestoreService.deleteAllNotes();
            },
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location chart'),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 16,
        children: [
          FloatingActionButton(
            onPressed: openNoteBox,
            child: Icon(Icons.add),
          ),
          FloatingActionButton(
            onPressed: showDeleteDialog,
            child: Icon(Icons.delete),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getNoteStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List notesList = snapshot.data!.docs;
            return ListView.builder(
              itemCount: notesList.length,
              itemBuilder: (context, index) {
                DocumentSnapshot document = notesList[index];
                String docID = document.id;
                Map<String, dynamic> data =
                    document.data() as Map<String, dynamic>;
                String noteText = data['note'];
                return ListTile(
                  title: Text(noteText),
                  subtitle: Text(
                    'lat: ${convertToDMS(data['latitude'], true)}\nlng: ${convertToDMS(data['longitude'], false)}',
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => openNoteBox(docID: docID),
                        icon: Icon(Icons.settings_outlined),
                      ),
                      IconButton(
                        onPressed: () => showDeleteDialog(docID: docID),
                        icon: Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            return const Text("nothing yet to show here");
          }
        },
      ),
    );
  }
}
