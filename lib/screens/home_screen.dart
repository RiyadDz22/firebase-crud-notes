import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_notes/models/note_modle.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

var uuid = const Uuid();
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _noteController = TextEditingController();
  late List<Note> _notes;

  @override
  void initState() {
    super.initState();
    _notes = [];
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('notes')
          .where('userId', isEqualTo: user.uid) // Filter based on the user ID
          .get();

      final List<Note> loadedNotes = snapshot.docs.map((doc) {
        final noteData = doc.data() as Map<String, dynamic>;

        final createdAt = noteData.containsKey('createdAt')
            ? (noteData['createdAt'] as Timestamp).toDate()
            : DateTime.now();

        return Note(
          id: doc.id,
          note: noteData['note'],
          createdAt: createdAt,
        );
      }).toList();

      setState(() {
        _notes = loadedNotes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your notes'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddNoteDialog(context);
        },
        child: const Icon(Icons.add),
      ),
      body: _notes.isEmpty
          ? const Center(child: Text('There are no notes to show'))
          : ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Dismissible(
                  key: Key(note.id.toString()),
                  onDismissed: (direction) async {
                    await _firestore
                        .collection('notes')
                        .where('note', isEqualTo: note.note)
                        .get()
                        .then((QuerySnapshot querySnapshot) {
                      querySnapshot.docs.forEach((doc) {
                        doc.reference.delete();
                      });
                    });

                    setState(() {
                      _notes.removeAt(index);
                    });
                  },
                  child: Card(
                    child: ListTile(
                      onTap: () {
                        _showUpdateNoteDialog(context, note);
                      },
                      title: Text(note.note),
                      subtitle: Text(note.createdAt.toString()),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showUpdateNoteDialog(BuildContext context, Note note) {
    TextEditingController noteController =
        TextEditingController(text: note.note);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Note'),
          content: TextField(
            controller: noteController,
            maxLength: null,
            maxLines: null,
            autocorrect: true,
            expands: true,
            decoration:
                const InputDecoration(hintText: 'Enter your updated note'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final CollectionReference notesRef =
                    _firestore.collection('notes');

                await notesRef.doc(note.id).update({
                  'note': noteController.text,
                }); // Update the 'note' field in Firestore
                if (!mounted) {
                  return;
                }
                Navigator.of(context).pop(); // Close dialog
                _loadNotes(); // Reload notes after updating the note
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Note'),
          content: TextField(
            controller: _noteController,
            maxLength: null,
            maxLines: null,
            autocorrect: true,
            expands: true,
            decoration: const InputDecoration(hintText: 'Enter your note'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser!;
                final CollectionReference notesRef =
                    _firestore.collection('notes');
                final String noteId =
                    uuid.v4(); // Generate a UUID for the note ID
                final Map<String, dynamic> userFields = {
                  'note': _noteController.text,
                  'noteId':
                      noteId, // Store the generated note ID within the document
                  'userId': user.uid,
                  'createdAt': DateTime.now(),
                };

                await notesRef
                    .doc(noteId)
                    .set(userFields); // Set the document with the generated ID

                _noteController.clear();
                if (!mounted) {
                  return;
                }
                Navigator.of(context).pop(); // Close dialog
                _loadNotes(); // Reload notes after adding a new one
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
