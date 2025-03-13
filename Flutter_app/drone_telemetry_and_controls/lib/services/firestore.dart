import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class FirestoreService {
  final CollectionReference notes =
      FirebaseFirestore.instance.collection('Telemetry Locations');

  Future<void> addNote(double latitude, double longitude) {
    return notes.add(
      {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': Timestamp.now(),
      },
    );
  }

  Stream<QuerySnapshot> getNoteStream() {
    final notesStream =
        notes.orderBy('timestamp', descending: false).snapshots();
    return notesStream;
  }

  Future<void> updateNote(String docID, String newNote) {
    return notes.doc(docID).update(
      {'note': newNote},
    );
  }

  Future<void> deleteNote(String docID) {
    return notes.doc(docID).delete();
  }

  Future<void> deleteAllNotes() {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    return notes.get().then(
      (querySnapshot) {
        for (var doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }
        return batch.commit();
      },
    );
  }
}
