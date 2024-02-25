import 'dart:io';
import 'package:flutter/material.dart';

class ImageDisplayScreen extends StatelessWidget {
  final File? pickedImage;
  const ImageDisplayScreen({Key? key, required this.pickedImage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Back'),
      ),
      body: Container(
        color: Colors.grey[300], // Set content background color
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 300,
                width: 300,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey), // Add border
                  ),
                  child: pickedImage != null
                      ? Image.file(pickedImage!, fit: BoxFit.cover)
                      : Center(child: Text('No image selected')),
                ),
              ),
              SizedBox(height: 16), // Add spacing between image and buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Handle logic for Parkinson button
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0, // Remove elevation
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), // Adjust padding
                    ),
                    child: Text('Parkinson'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Handle logic for Healthy button
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0, // Remove elevation
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), // Adjust padding
                    ),
                    child: Text('Healthy'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
