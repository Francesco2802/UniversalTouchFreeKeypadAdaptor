

/*
|------------------------------------------------------------------------------------------------------------------------|
|  Francesco Gritti  26/08/2020                                                                                          |
|------------------------------------------------------------------------------------------------------------------------|  
|  This Program combines the manual keypad configuration and the image-processed keypad configurations.                  |
|------------------------------------------------------------------------------------------------------------------------|
 */


import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';


import 'ProcessImageAndDisplayWidget.dart';



/* --------------------------------------------------------------------------- */
/* --------------------------- Take Picture Screen --------------------------- */ 
/* --------------------------------------------------------------------------- */


// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {

  final CameraDescription camera;   // the camera to use to take pictures
  final writeConfigurationlayout;

  // class initializer
  const TakePictureScreen(this.camera, this.writeConfigurationlayout);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}


/* --------------------------------------------------------------------------------- */
/* --------------------------- Take Picture Screen State --------------------------- */ 
/* --------------------------------------------------------------------------------- */

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;

  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    // To display the current output from the Camera, create a CameraController specifying the needed camera
    _controller = CameraController(widget.camera, ResolutionPreset.medium);

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take a picture')),


      /* Wait until the controller is initialized before displaying the camera preview. 
         Use a FutureBuilder to display a loading spinner until the controller has finished initializing. */

      body: FutureBuilder<void>(

        future: _initializeControllerFuture,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture

          try {
            // Ensure that the camera is initialized, since CameraController.initialize() returns a future
            await _initializeControllerFuture;

            // Construct the path where the image should be saved using the pattern package.
            final path = join( (await getTemporaryDirectory()).path, '${DateTime.now()}.png' );

            // Attempt to take a picture and log where it's been saved.
            await _controller.takePicture(path);

            // If the picture was taken, pass it to the processing stage and display it
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProcessImageAndDisplay(path, widget.writeConfigurationlayout),
              ),
            );
            Navigator.pop(context, result);
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
      ),
    );
  }
}

