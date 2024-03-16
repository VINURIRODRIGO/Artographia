import 'dart:io';
import 'package:camera/camera.dart';
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
            if (showButtons) // Show buttons only when showButtons is true
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (classification != null) {
                        var sortedResults = (classification!.entries.toList()
                              ..sort((a, b) => a.value.compareTo(b.value)))
                            .reversed
                            .take(3)
                            .toList();
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Prediction Results"),
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: sortedResults.map((e) {
                                  var percentage =
                                      (e.value * 100).toStringAsFixed(0);
                                  return Text("${e.key}: $percentage%");
                                }).toList(),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Close'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    child: const Text('Healthy'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Handle Patient button press
                    },
                    child: const Text('Patient'),
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
