import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../models/note.dart';

class EditScreen extends StatefulWidget {
  final Note? note;
  const EditScreen({super.key, this.note});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _contentController = TextEditingController();
  final Logger logger = Logger();

  @override
  void initState() {
    if (widget.note != null) {
      _titleController = TextEditingController(text: widget.note!.title);
      _contentController = TextEditingController(text: widget.note!.content);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text('Notes'), // Change the title
        leading: IconButton(
          // Add leading property with IconButton
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
          ),
        ),
      ),
      backgroundColor: Colors.grey[400],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 25, 25, 0), // Set padding here
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.black, fontSize: 30),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Title',
                        hintStyle: TextStyle(color: Colors.black, fontSize: 30),
                      ),
                    ),
                    TextField(
                      controller: _contentController,
                      style: const TextStyle(color: Colors.black),
                      maxLines: null,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Type something here',
                        hintStyle: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          saveNoteToFirestore();
        },
        elevation: 10,
        backgroundColor: const Color.fromARGB(208, 199, 171, 252),
        child: const Icon(
          Icons.save,
          color: Color.fromARGB(255, 255, 255, 255),
        ),
      ),
    );
  }

  void saveNoteToFirestore() {
    // Access Firestore instance
    CollectionReference collectionReference =
        FirebaseFirestore.instance.collection("Notes");

    // Get the title and content from text controllers
    String title = _titleController.text;
    String content = _contentController.text;

    // Get current user's email
    String userEmail = FirebaseAuth.instance.currentUser!.email!;

    // Create a new note object
    Map<String, dynamic> noteData = {
      'title': title,
      'content': content,
      'email': userEmail,
      'modifiedTime': DateTime.now(),
    };

    // If editing an existing note, update it in Firestore
    if (widget.note != null) {
      collectionReference
          .doc(widget.note!.id.toString())
          .update(noteData)
          .then((value) => {
                logger.d("DocumentSnapshot successfully updated!"),
                // Navigate back to home page
                Navigator.pop(context)
              })
          .catchError((e) =>{ logger.d("Error updating document $e")});
    } else {
      // Otherwise, add a new note to Firestore
      collectionReference.add(noteData).then((DocumentReference docRef) {
        logger.d("Document added with ID: ${docRef.id}");

        // Use the generated document ID to update the note
        docRef.update({'id': docRef.id}).then(
          (value) {
            logger.d("Note updated with auto-generated ID: ${docRef.id}");
            // Navigate back to home page
            Navigator.pop(context);
          },
          onError: (e) => logger.d("Error updating document $e"),
        );
      }).catchError((error) {
        logger.d("Failed to add note: $error");
        // Handle error
      });
    }
  }
}
