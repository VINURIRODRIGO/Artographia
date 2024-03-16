import 'package:flutter/material.dart';
import 'package:image_classification_mobilenet/components/notes/screens/home.dart';

void main() {
  runApp(const NotesScreen());
}

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}