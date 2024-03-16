import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:image_classification_mobilenet/components/upload/ui/camera.dart';
import 'package:image_classification_mobilenet/components/upload/ui/gallery.dart';
import 'package:image_classification_mobilenet/pages/home_page.dart';

Future<void> main() async {
  runApp(const UploadScren());
}

class UploadScren extends StatelessWidget {
  const UploadScren({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BottomNavigationBarExample(),
    );
  }
}

class BottomNavigationBarExample extends StatefulWidget {
  const BottomNavigationBarExample({super.key});

  @override
  State<BottomNavigationBarExample> createState() =>
      _BottomNavigationBarExampleState();
}

class _BottomNavigationBarExampleState
    extends State<BottomNavigationBarExample> {
  late CameraDescription cameraDescription;
  int _selectedIndex = 0;
  List<Widget>? _widgetOptions;

  bool cameraIsAvailable = Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initPages();
    });
  }

  initPages() async {
    _widgetOptions = [const GalleryScreen()];

    if (cameraIsAvailable) {
      // get list available camera
      cameraDescription = (await availableCameras()).first;
      _widgetOptions!.add(CameraScreen(camera: cameraDescription));
    }

    setState(() {});
  }

  void _onItemTapped(int index) {
    if (!cameraIsAvailable) {
      // debugPrint("This is not supported on your current platform");
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text('ParkinSpiral'),
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePage(),
              ),
            );
          },
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
          ),
        ),
      ),
      backgroundColor: Colors.grey[200],
      body: Center(
        child: _widgetOptions?.elementAt(_selectedIndex),
      ),
    );
  }
}
