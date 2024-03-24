import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import '../helper/image_classification_helper.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  var modelAnswer = "";
  var userAnswer = "";
  var feedback = "Wrong";
  List<Widget> contentWidgets = [];
  var uploadedImageName = "";
  final CollectionReference collection =
      FirebaseFirestore.instance.collection("Report");
  String comment = "";

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

  Future<void> reportFeedback() async {

     String uploadedImageName = "";

  if (imagePath != null) {
    print("ImagePath: $imagePath");
    uploadedImageName = imagePath!.split('/').last;
    File imageFile = File(imagePath!);
    Reference storageRef = FirebaseStorage.instance.ref();
    Reference imagesRef = storageRef.child("images");
    Reference spaceRef = imagesRef.child(uploadedImageName);
    await spaceRef.putFile(imageFile);
    String imageUrl = await spaceRef.getDownloadURL();
    
    // Save data to Firestore with image
    await FirebaseFirestore.instance.collection('Report').add({
      'image': imageUrl,
      'comments': comment,
      'userPredictResults': userAnswer,
    }).then((DocumentReference docRef) {
      // Update document with its ID
      docRef.update({'id': docRef.id});
    }).catchError((error) {
      print("Failed to add report: $error");
    });
  } else {
    // Save data to Firestore without image
    await FirebaseFirestore.instance.collection('Report').add({
      'comments': comment,
      'userPredictResults': userAnswer,
    }).then((DocumentReference docRef) {
      // Update document with its ID
      docRef.update({'id': docRef.id});
    }).catchError((error) {
      print("Failed to add report: $error");
    });
  }
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
                        "Camara",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Set text color to white
                        ),
                      ),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          const Color.fromARGB(255, 234, 224, 253),
                        ),
                      )),
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
                    label: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "Gallery",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, 
                        ),
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 234, 224, 253),
                      ),
                    )),
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
                                                    (classification!
                                                            .entries
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
                                                    List<Widget>
                                                        contentWidgets = [];
                                                    userAnswer = "Healthy";
                                                    feedback = userAnswer ==
                                                            sortedResults
                                                                .first.key
                                                        ? "Correct"
                                                        : "Wrong";
                                                    modelAnswer =
                                                        sortedResults.first.key;
                                                    if (userAnswer != "") {
                                                      contentWidgets.add(
                                                        Text(
                                                          "$feedback Answer. This is a $modelAnswer's drawing",
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            color: feedback ==
                                                                    "Correct"
                                                                ? Colors.green
                                                                : Colors.red,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                    contentWidgets.addAll(
                                                      sortedResults.map((e) {
                                                        var percentage = (e
                                                                    .value *
                                                                100)
                                                            .toStringAsFixed(0);
                                                        return Text(
                                                            "${e.key}: $percentage%");
                                                      }),
                                                    );
                                                    return AlertDialog(
                                                      backgroundColor:
                                                          Colors.white,
                                                      title: const Text(
                                                        "Prediction Results",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.black),
                                                      ),
                                                      content: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children:
                                                            contentWidgets,
                                                      ),
                                                      actions: <Widget>[
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(); 
                                                                showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (BuildContext
                                                                          context) {
                                                                    return AlertDialog(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .white,
                                                                      title:
                                                                          const Text(
                                                                        "Report",
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.black),
                                                                      ),
                                                                      content:
                                                                          Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          TextFormField(
                                                                            maxLength:
                                                                                150,
                                                                            onChanged:
                                                                                (value) {
                                                                              comment = value;
                                                                            },
                                                                            decoration:
                                                                                InputDecoration(
                                                                              hintText: "Enter your report comment",
                                                                              border: OutlineInputBorder(
                                                                                // Add a border around the text field
                                                                                borderRadius: BorderRadius.circular(10.0), // Set border radius
                                                                              ),
                                                                              focusedBorder: OutlineInputBorder(
                                                                                // Border when the field is focused
                                                                                borderRadius: BorderRadius.circular(10.0),
                                                                                borderSide: const BorderSide(color: Colors.black), // Set border color
                                                                              ),
                                                                            ),
                                                                          ),                                                                          
                                                                        ],
                                                                      ),
                                                                      actions: <Widget>[
                                                                        Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center, // Center the buttons horizontally
                                                                          children: [
                                                                            TextButton(
                                                                              onPressed: () {
                                                                                Navigator.of(context).pop(); // Close the report dialog
                                                                              },
                                                                              style: ElevatedButton.styleFrom(
                                                                                backgroundColor: Colors.green,
                                                                              ),
                                                                              child: const Text(
                                                                                'Cancel',
                                                                                style: TextStyle(color: Colors.white),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(width: 10), // Add some space between the buttons
                                                                            TextButton(
                                                                              onPressed: () {
                                                                                Navigator.of(context).pop();
                                                                                reportFeedback();
                                                                              },
                                                                              style: ElevatedButton.styleFrom(
                                                                                backgroundColor: Colors.red,
                                                                              ),
                                                                              child: const Text(
                                                                                'Report',
                                                                                style: TextStyle(color: Colors.white),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                );
                                                              },
                                                              style: ElevatedButton
                                                                  .styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red),
                                                              child:
                                                                  const SizedBox(
                                                                width: 60,
                                                                child: Text(
                                                                  'Report',
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 15),
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                                isPatientButtonSelected =
                                                                    false;
                                                              },
                                                              style: ElevatedButton
                                                                  .styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .green),
                                                              child:
                                                                  const SizedBox(
                                                                width: 60,
                                                                child: Text(
                                                                  'Close',
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
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
                                                return Colors.blue;
                                              } else {
                                                return Colors.grey
                                                    .withOpacity(0.5);
                                              }
                                            }),
                                          ),
                                          child: const Text(
                                            'Healthy',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            logger.d(isLoading);
                                            if (!isHealthyButtonSelected) {
                                              isPatientButtonSelected = true;
                                              if (classification != null) {
                                                var sortedResults =
                                                    (classification!
                                                            .entries
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
                                                    List<Widget>
                                                        contentWidgets = [];
                                                    userAnswer = "Patient";
                                                    feedback = userAnswer ==
                                                            sortedResults
                                                                .first.key
                                                        ? "Correct"
                                                        : "Wrong";
                                                    modelAnswer =
                                                        sortedResults.first.key;
                                                    if (userAnswer != "") {
                                                      contentWidgets.add(
                                                        Text(
                                                          "$feedback Answer. This is a $modelAnswer's drawing",
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            color: feedback ==
                                                                    "Correct"
                                                                ? Colors.green
                                                                : Colors.red,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      );
                                                    }

                                                    contentWidgets.addAll(
                                                      sortedResults.map((e) {
                                                        var percentage = (e
                                                                    .value *
                                                                100)
                                                            .toStringAsFixed(0);
                                                        return Text(
                                                            "${e.key}: $percentage%");
                                                      }),
                                                    );

                                                    return AlertDialog(
                                                      backgroundColor:
                                                          Colors.white,
                                                      title: const Text(
                                                        "Prediction Results",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.black),
                                                      ),
                                                      content: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children:
                                                            contentWidgets,
                                                      ),
                                                      actions: <Widget>[
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                                    showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (BuildContext
                                                                          context) {
                                                                    return AlertDialog(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .white,
                                                                      title:
                                                                          const Text(
                                                                        "Report",
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.black),
                                                                      ),
                                                                      content:
                                                                          Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          TextFormField(
                                                                            maxLength:
                                                                                150,
                                                                            onChanged:
                                                                                (value) {
                                                                              comment = value;
                                                                            },
                                                                            decoration:
                                                                                InputDecoration(
                                                                              hintText: "Enter your report comment",
                                                                              border: OutlineInputBorder(
                                                                                // Add a border around the text field
                                                                                borderRadius: BorderRadius.circular(10.0), // Set border radius
                                                                              ),
                                                                              focusedBorder: OutlineInputBorder(
                                                                                // Border when the field is focused
                                                                                borderRadius: BorderRadius.circular(10.0),
                                                                                borderSide: const BorderSide(color: Colors.black), // Set border color
                                                                              ),
                                                                            ),
                                                                          ),                                                                          
                                                                        ],
                                                                      ),
                                                                      actions: <Widget>[
                                                                        Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center, // Center the buttons horizontally
                                                                          children: [
                                                                            TextButton(
                                                                              onPressed: () {
                                                                                Navigator.of(context).pop(); // Close the report dialog
                                                                              },
                                                                              style: ElevatedButton.styleFrom(
                                                                                backgroundColor: Colors.green,
                                                                              ),
                                                                              child: const Text(
                                                                                'Cancel',
                                                                                style: TextStyle(color: Colors.white),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(width: 10), // Add some space between the buttons
                                                                            TextButton(
                                                                              onPressed: () {
                                                                                Navigator.of(context).pop();
                                                                                reportFeedback();
                                                                              },
                                                                              style: ElevatedButton.styleFrom(
                                                                                backgroundColor: Colors.red,
                                                                              ),
                                                                              child: const Text(
                                                                                'Report',
                                                                                style: TextStyle(color: Colors.white),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                );
                                                                isPatientButtonSelected =
                                                                    false;
                                                              },
                                                              style: ElevatedButton
                                                                  .styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red),
                                                              child:
                                                                  const SizedBox(
                                                                width: 60,
                                                                child: Text(
                                                                  'Report',
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 15),
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                                isPatientButtonSelected =
                                                                    false;
                                                              },
                                                              style: ElevatedButton
                                                                  .styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .green),
                                                              child:
                                                                  const SizedBox(
                                                                width: 60,
                                                                child: Text(
                                                                  'Close',
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
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
                                                return Colors.blue;
                                              } else {
                                                return Colors.grey
                                                    .withOpacity(0.5);
                                              }
                                            }),
                                          ),
                                          child: const Text(
                                            'Patient',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
