import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:ez_queue_app/app_configs.dart';
import 'package:ez_queue_app/utils/cameraImage.util.dart';

class Scanner extends StatefulWidget {
  Scanner({Key? key}) : super(key: key);

  @override
  _ScannerState createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  BarcodeScanner barcodeScanner = GoogleMlKit.vision.barcodeScanner();

  CameraDescription? cameraActive;
  CameraController? controller;
  List<CameraDescription>? cameras;

  bool isInitialized = false;
  bool isScanning = false;
  bool isBarcodeHandling = false;

  initializeCamera() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      cameras = await availableCameras();
      setState(() {
        isInitialized = true;
        cameraActive = cameras!.length > 0 ? cameras![1] : null;
      });
    } catch (e, stack) {
      print(e);
      print(stack);
    }
  }

  handleToggleCamera() async {
    final newCamera = cameras!.where((element) => element.lensDirection != cameraActive!.lensDirection);
    if (newCamera.isNotEmpty) {
      cameraActive = newCamera.first;
      await handleStartScan();
    }
  }

  handleStartScan() async {
    controller = CameraController(cameraActive!, ResolutionPreset.max);
    await controller!.initialize();
    controller!.startImageStream((image) => handleDetectQRCode(image));

    setState(() {
      isScanning = true;
    });
  }

  handleStopScan() async {
    try {
      if (isScanning == false) return;
      setState(() {
        isScanning = false;
      });

      await controller!.stopImageStream();
      await controller!.dispose();
    } catch (e, stack) {
      print(e);
      print(stack);
    }
  }

  handleDetectQRCode(CameraImage cameraImage) async {
    if (isBarcodeHandling == true) return;
    isBarcodeHandling = true;

    try {
      var inputImage = convertCameraImage(cameraImage, cameraActive!);
      List<Barcode> barcodes = await barcodeScanner.processImage(inputImage);

      if (barcodes.length != 0) {
        final barcodeResult = barcodes[0].value.rawValue as String;
        print("Barcode: $barcodeResult");
      }
    } catch (e, stack) {
      print(e);
      print(stack);
    }

    await Future.delayed(Duration(milliseconds: 200));
    isBarcodeHandling = false;
  }

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) return Container();
    if (cameraActive == null) return Text("Cannot find any camera");

    if (isScanning)
      return Container(
        child: Column(
          children: [
            CameraPreview(controller!),
            Container(
              margin: EdgeInsets.only(top: rem(0.7)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(onPressed: handleStopScan, child: Text("Stop")),
                  ElevatedButton(onPressed: handleToggleCamera, child: Text("Switch")),
                ],
              ),
            ),
          ],
        ),
      );

    return Container(
      child: ElevatedButton(
        onPressed: handleStopScan,
        child: Text("Start Scan"),
      ),
    );
  }
}
