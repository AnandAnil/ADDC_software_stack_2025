import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference notes =
      FirebaseFirestore.instance.collection('Notes');

  Future<void> addNote(String note) {
    return notes.add(
      {
        'note': note,
        'timestamp': Timestamp.now(),
      },
    );
  }

  Stream<QuerySnapshot> getNoteStream() {
    final notesStream =
        notes.orderBy('timestamp', descending: true).snapshots();
    return notesStream;
  }

  Future<void> updateNote(String docID, String newNote) {
    return notes.doc(docID).update(
      {
        'note': newNote,
        'timestamp': Timestamp.now(),
      },
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
