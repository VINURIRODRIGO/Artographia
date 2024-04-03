import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../helper/image_classification_helper.dart';


class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  State<StatefulWidget> createState() => CameraScreenState();
}

enum SelectedButton { none, healthy, patient }

class CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  late CameraController cameraController;
  late ImageClassificationHelper imageClassificationHelper;
  Map<String, double>? classification;
  bool _isProcessing = false;
  bool showButtons = false;
  Logger logger = Logger();
  SelectedButton selectedButton = SelectedButton.none;
  var modelAnswer = "";
  var userAnswer = "";
  var feedback = "Wrong";
  List<Widget> contentWidgets = [];
  bool isLoading = false;
  bool isHealthyButtonSelected = false;
  bool isPatientButtonSelected = false;
  String? uploadedImageFileName;
    var uploadedImageName = "";
  final CollectionReference collection =
      FirebaseFirestore.instance.collection("Report");
  String comment = "";
  
  initCamera() {
    cameraController = CameraController(widget.camera, ResolutionPreset.medium,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420);
    cameraController.initialize().then((value) {
      cameraController.startImageStream(imageAnalysis);
      if (mounted) {
        setState(() {});
      }
    });
  }


  // Inside CameraScreen class
  Future<void> imageAnalysis(CameraImage cameraImage) async {
    if (_isProcessing) {
      return;
    }
    _isProcessing = true;
    classification =
        await imageClassificationHelper.inferenceCameraFrame(cameraImage);
    _isProcessing = false;
    if (mounted) {
      setState(() {});
      showButtons = true; // Set showButtons to true when image is analyzed
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    initCamera();
    imageClassificationHelper = ImageClassificationHelper();
    imageClassificationHelper.initHelper();
    super.initState();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        cameraController.stopImageStream();
        break;
      case AppLifecycleState.resumed:
        if (!cameraController.value.isStreamingImages) {
          await cameraController.startImageStream(imageAnalysis);
        }
        break;
      default:
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.dispose();
    imageClassificationHelper.close();
    super.dispose();
  }

  Widget cameraWidget(context) {
    var camera = cameraController.value;
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * camera.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Transform.scale(
      scale: scale,
      child: Center(
        child: CameraPreview(cameraController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> list = [];

    list.add(
      SizedBox(
        child: (!cameraController.value.isInitialized)
            ? Container()
            : cameraWidget(context),
      ),
    );
    list.add(Align(
      alignment: Alignment.bottomCenter,
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (showButtons)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      logger.d(isLoading);
                      if (!isPatientButtonSelected) {
                        isHealthyButtonSelected = true;
                        if (classification != null) {
                          var sortedResults = (classification!.entries.toList()
                                ..sort((a, b) => a.value.compareTo(b.value)))
                              .reversed
                              .take(3)
                              .toList();
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              List<Widget> contentWidgets = [];
                              userAnswer = "Healthy";
                              feedback = userAnswer == sortedResults.first.key
                                  ? "Correct"
                                  : "Wrong";
                              modelAnswer = sortedResults.first.key;
                              if (userAnswer != "") {
                                contentWidgets.add(
                                  Text(
                                    "$feedback Answer. This is a $modelAnswer's drawing",
                                    style: TextStyle(
                                      color: feedback == "Correct"
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                );
                              }

                              contentWidgets.addAll(
                                sortedResults.map((e) {
                                  var percentage =
                                      (e.value * 100).toStringAsFixed(0);
                                  return Text("${e.key}: $percentage%");
                                }),
                              );

                              return AlertDialog(
                                backgroundColor: Colors.white,
                                title: const Text(
                                  "Prediction Results",
                                  style: TextStyle(color: Colors.black),
                                ),
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: contentWidgets,
                                ),
                                actions: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
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
                                                                                // reportFeedback();
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
                                          isPatientButtonSelected = false;
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red),
                                        child: const SizedBox(
                                          width: 60,
                                          child: Text(
                                            'Report',
                                            textAlign: TextAlign.center,
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          isPatientButtonSelected = false;
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green),
                                        child: const SizedBox(
                                          width: 60,
                                          child: Text(
                                            'Close',
                                            textAlign: TextAlign.center,
                                            style:
                                                TextStyle(color: Colors.white),
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
                          MaterialStateProperty.resolveWith<Color>((states) {
                        if (isHealthyButtonSelected == true &&
                            isPatientButtonSelected == false) {
                          return Colors.blue;
                        } else {
                          return Colors.grey.withOpacity(0.5);
                        }
                      }),
                    ),
                    child: const Text(
                      'Healthy',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      logger.d(isLoading);
                      if (!isHealthyButtonSelected) {
                        isPatientButtonSelected = true;
                        if (classification != null) {
                          var sortedResults = (classification!.entries.toList()
                                ..sort((a, b) => a.value.compareTo(b.value)))
                              .reversed
                              .take(3)
                              .toList();
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              List<Widget> contentWidgets = [];
                              userAnswer = "Patient";
                              feedback = userAnswer == sortedResults.first.key
                                  ? "Correct"
                                  : "Wrong";
                              modelAnswer = sortedResults.first.key;
                              if (userAnswer != "") {
                                contentWidgets.add(
                                  Text(
                                    "$feedback Answer. This is a $modelAnswer's drawing",
                                    style: TextStyle(
                                      color: feedback == "Correct"
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                );
                              }

                              contentWidgets.addAll(
                                sortedResults.map((e) {
                                  var percentage =
                                      (e.value * 100).toStringAsFixed(0);
                                  return Text("${e.key}: $percentage%");
                                }),
                              );

                              return AlertDialog(
                                backgroundColor: Colors.white,
                                title: const Text(
                                  "Prediction Results",
                                  style: TextStyle(color: Colors.black),
                                ),
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: contentWidgets,
                                ),
                                actions: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
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
                                                                                // reportFeedback();
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
                                          isPatientButtonSelected = false;
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red),
                                        child: const SizedBox(
                                          width: 60,
                                          child: Text(
                                            'Report',
                                            textAlign: TextAlign.center,
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          isPatientButtonSelected = false;
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green),
                                        child: const SizedBox(
                                          width: 60,
                                          child: Text(
                                            'Close',
                                            textAlign: TextAlign.center,
                                            style:
                                                TextStyle(color: Colors.white),
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
                          MaterialStateProperty.resolveWith<Color>((states) {
                        if (isPatientButtonSelected == true &&
                            isHealthyButtonSelected == false) {
                          return Colors.blue;
                        } else {
                          return Colors.grey.withOpacity(0.5);
                        }
                      }),
                    ),
                    child: const Text(
                      'Patient',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ));

    return SafeArea(
      child: Stack(
        children: list,
      ),
    );
  }
}
