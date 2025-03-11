import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_planner/services/firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController textController = TextEditingController();

  void openNoteBox({String? docID}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: textController,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (docID == null) {
                firestoreService.addNote(textController.text);
              } else {
                firestoreService.updateNote(docID, textController.text);
              }
              textController.clear();
              Navigator.pop(context);
            },
            child: Text('Add Note'),
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
        title: Text('GPS Mapper'),
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
            onPressed: clearDatabase,
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => openNoteBox(docID: docID),
                        icon: Icon(Icons.settings_outlined),
                      ),
                      IconButton(
                        onPressed: () => firestoreService.deleteNote(docID),
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
