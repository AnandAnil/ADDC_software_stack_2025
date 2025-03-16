import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        title: Text(docID == null ? 'Add New Location' : 'Edit Location Name'),
        content: TextField(
          autofocus: true,
          controller: textController,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (docID == null) {
                Position position = await Geolocator.getCurrentPosition();
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
      floatingActionButton: Row(
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
              padding: EdgeInsets.only(bottom: 80),
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
                    'lat: ${data['latitude']}\nlng: ${data['longitude']}',
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(
                              text: '${data['latitude']}, ${data['longitude']}',
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: Icon(Icons.copy_outlined),
                      ),
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
