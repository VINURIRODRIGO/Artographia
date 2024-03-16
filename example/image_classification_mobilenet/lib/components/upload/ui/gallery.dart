import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import '../helper/image_classification_helper.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  ImageClassificationHelper? imageClassificationHelper;
  final imagePicker = ImagePicker();
  String? imagePath;
  img.Image? image;
  Map<String, double>? classification;
  bool cameraIsAvailable = Platform.isAndroid || Platform.isIOS;
  bool showButtons = false;
  Logger logger = Logger();
  bool isLoading = false;
  bool isHealthyButtonSelected = false;
  bool isPatientButtonSelected = false;

  @override
  void initState() {
    imageClassificationHelper = ImageClassificationHelper();
    imageClassificationHelper!.initHelper();
    super.initState();
  }

  // Clean old results when press some take picture button
  void cleanResult() {
    imagePath = null;
    image = null;
    classification = null;
    setState(() {});
  }

  // Inside GalleryScreen class
  Future<void> processImage() async {
    setState(() {
      isLoading = true;
      isHealthyButtonSelected = false;
      isPatientButtonSelected = false;
    });
    if (imagePath != null) {
      final imageData = File(imagePath!).readAsBytesSync();
      image = img.decodeImage(imageData);
      setState(() {});
      classification = await imageClassificationHelper?.inferenceImage(image!);
      setState(() {});
      showButtons = true; // Set showButtons to true when image is processed
    }
    // Set isLoading to false to indicate that image processing is complete
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    imageClassificationHelper?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (cameraIsAvailable)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      cleanResult();
                      final result = await imagePicker.pickImage(
                        source: ImageSource.camera,
                      );
                      imagePath = result?.path;
                      setState(() {});
                      processImage();
                    },
                    icon: const Icon(
                      Icons.camera,
                      size: 32,
                    ),
                    label: const Text(
                      "Take Photo",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    cleanResult();
                    final result = await imagePicker.pickImage(
                      source: ImageSource.gallery,
                    );
                    imagePath = result?.path;
                    setState(() {});
                    processImage();
                  },
                  icon: const Icon(
                    Icons.photo,
                    size: 32,
                  ),
                  label: const Text(
                    "Gallery Screen",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isLoading) const CircularProgressIndicator(),
                    if (!isLoading && imagePath != null)
                      Image.file(File(imagePath!)),
                    if (image == null && !isLoading)
                      const Text(
                        "UPLOAD A SPIRAL IMAGE",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (!isLoading)
                       Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(),
                            SingleChildScrollView(
                              child: Column(
                                children: [
                                  if (showButtons)
                                    Container(
                                      padding: const EdgeInsets.only(top: 30.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () async {
                                              logger.d(isLoading);
                                              if (!isPatientButtonSelected) {
                                                isHealthyButtonSelected = true;

                                                if (classification != null) {
                                                  var sortedResults =
                                                      (classification!.entries
                                                              .toList()
                                                            ..sort((a, b) => a
                                                                .value
                                                                .compareTo(
                                                                    b.value)))
                                                          .reversed
                                                          .take(3)
                                                          .toList();
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return AlertDialog(
                                                        title: const Text(
                                                            "Prediction Results"),
                                                        content: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children:
                                                              sortedResults
                                                                  .map((e) {
                                                            var percentage = (e
                                                                        .value *
                                                                    100)
                                                                .toStringAsFixed(
                                                                    0);
                                                            return Text(
                                                                "${e.key}: $percentage%");
                                                          }).toList(),
                                                        ),
                                                        actions: <Widget>[
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                              isPatientButtonSelected =
                                                                  false;
                                                            },
                                                            child: const Text(
                                                                'Close'),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                }
                                              }
                                            },
                                            style: ButtonStyle(
                                              backgroundColor:
                                                  MaterialStateProperty
                                                      .resolveWith<Color>(
                                                          (states) {
                                                if (isHealthyButtonSelected ==
                                                        true &&
                                                    isPatientButtonSelected ==
                                                        false) {                                                 
                                                  return Colors
                                                      .blue;
                                                } else {                                                
                                                  return Colors.grey.withOpacity(
                                                      0.5);
                                                }
                                              }),
                                            ),
                                            child: const Text(
                                              'Healthy',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              logger.d(isLoading);
                                              if (!isHealthyButtonSelected) {
                                                isPatientButtonSelected = true;
                                                if (classification != null) {
                                                  var sortedResults =
                                                      (classification!.entries
                                                              .toList()
                                                            ..sort((a, b) => a
                                                                .value
                                                                .compareTo(
                                                                    b.value)))
                                                          .reversed
                                                          .take(3)
                                                          .toList();
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return AlertDialog(
                                                        title: const Text(
                                                            "Prediction Results"),
                                                        content: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children:
                                                              sortedResults
                                                                  .map((e) {
                                                            var percentage = (e
                                                                        .value *
                                                                    100)
                                                                .toStringAsFixed(
                                                                    0);
                                                            return Text(
                                                                "${e.key}: $percentage%");
                                                          }).toList(),
                                                        ),
                                                        actions: <Widget>[
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                              isHealthyButtonSelected =
                                                                  false;
                                                            },
                                                            child: const Text(
                                                                'Close'),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                }
                                              }
                                            },
                                            style: ButtonStyle(
                                              backgroundColor:
                                                  MaterialStateProperty
                                                      .resolveWith<Color>(
                                                          (states) {
                                                if (isPatientButtonSelected ==
                                                        true &&
                                                    isHealthyButtonSelected ==
                                                        false) {
                                                  return Colors
                                                      .blue;
                                                } else {
                                                  return Colors.grey.withOpacity(
                                                      0.5);
                                                }
                                              }),
                                            ),
                                            child: const Text(
                                              'Patient',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
