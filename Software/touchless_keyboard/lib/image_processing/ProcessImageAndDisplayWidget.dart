

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'BitmapHandler.dart';
import 'package:bitmap/bitmap.dart';
import 'dart:typed_data';
import 'dart:io';
import '../keypad_configuration/KeypadCellDescriptor.dart';
import '../keypad_configuration/KeypadConfigurationPage.dart';


// A widget that processes and displays the picture taken by the user.
class ProcessImageAndDisplay extends StatefulWidget {

  final String imagePath;
  final writeConfigurationLayout;

  ProcessImageAndDisplay(this.imagePath, this.writeConfigurationLayout);

  @override 
  ProcessImageAndDisplayState createState() => ProcessImageAndDisplayState();

}


class ProcessImageAndDisplayState extends State<ProcessImageAndDisplay> {

  Image processedImage;

  // future used by the FutureBuilder to know when the image loading iso complete
  Future<void> loadImageFuture;

  BitmapHandler imageBitmap = new BitmapHandler();
  Bitmap bitmap;

  RectangleFrame tagFrame;
  double pixelToMmRatio;

  List<List<int>> tag = [
    [1, 1, 1, 1, 1, 1, 1, 1, 1], 
    [1, 0, 0, 1, 1, 1, 0, 0, 1], 
    [1, 0, 1, 1, 1, 1, 1, 0, 1], 
    [1, 1, 1, 1, 0, 1, 1, 1, 1], 
    [1, 1, 1, 0, 0, 0, 1, 1, 1], 
    [1, 1, 1, 1, 0, 1, 1, 1, 1], 
    [1, 0, 1, 1, 1, 1, 1, 0, 1], 
    [1, 0, 0, 1, 1, 1, 0, 0, 1], 
    [1, 1, 1, 1, 1, 1, 1, 1, 1],
  ];

  int displayWidth, displayHeight;

  List<Button> buttonList = [];

  final _writeController = TextEditingController();



  @override 
  void initState() {
    super.initState();

    loadImageFuture = loadImageAsBitmap(widget.imagePath);
  }

  @override
  Widget build(BuildContext context) {

    displayWidth =  MediaQuery.of(context).size.width.toInt();
    displayHeight = MediaQuery.of(context).size.height.toInt();

    return Scaffold(
      appBar: AppBar(

        title: Text('Display the Picture'),
        actions: [
          FlatButton(
            onPressed: () async{

              final configuration = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KeypadConfigurationPage(buttonList, widget.writeConfigurationLayout),
                ),
              );
              if(configuration != null){
                Navigator.pop(context, configuration);
              }
            },
            child: Text("Next",style:TextStyle(color: Colors.white)),
            textColor: Colors.white,  
          )

        ],
      ),

      body: FutureBuilder<void>(
        future: loadImageFuture,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return  Center(
            child:Container(
              
              decoration: BoxDecoration(
                color:Colors.black87,
              ),
            child: GestureDetector(
              onTapDown: (TapDownDetails details) {

                var pointX = details.localPosition.dx / displayWidth * bitmap.width;
                var pointY = details.localPosition.dy / displayWidth * bitmap.width;
                print("(${pointX.toInt()}, ${pointY.toInt()})");

                setState((){

                  imageBitmap.drawPoint(pointX.toInt(), pointY.toInt());
                  int pathID = imageBitmap.isPointInsidePath(pointX.toInt(), pointY.toInt());
                  if(pathID != 0){
                    imageBitmap.hilightPath(pathID);

                    RectangleFrame frame = imageBitmap.getPathFrame(pathID);
                    if(frame != null){

                      RectangleFrame tagReferencedFrame = new RectangleFrame(
                        ((frame.centerX-tagFrame.centerX) * pixelToMmRatio).toInt(),
                        ((frame.centerY-tagFrame.centerY) * pixelToMmRatio).toInt(),
                        (frame.width * pixelToMmRatio).toInt(),
                        (frame.height * pixelToMmRatio).toInt()
                      );

                      print("\nPATH FRAME -> (${tagReferencedFrame.x} mm, ${tagReferencedFrame.y} mm)  [${tagReferencedFrame.width}mm x ${tagReferencedFrame.height} mm]");

                      showInsertButtonValueDialog();
                      buttonList.add(Button(tagReferencedFrame.x, tagReferencedFrame.y, tagReferencedFrame.width, tagReferencedFrame.height, " ", true, buttonList.length));
                    }
                  }
                  refreshImage();                
                });  
              },
                child: processedImage,// processedImage,
            ),
            ),
            );


          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){

          if(buttonList.length > 0){

            setState ((){
              imageBitmap.unhilightLastPath();
              buttonList.removeLast();
              refreshImage();
            });
          }
        },

        child: Icon(Icons.replay),
      ),
    );
  } 


  void showInsertButtonValueDialog () async {
    _writeController.clear();
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {

        return CupertinoAlertDialog(
          title: Text("Insert new value"),
          content: Row(
            children: <Widget>[
              Expanded(
                child: CupertinoTextField(
                  controller: _writeController,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text("Confirm"),
              onPressed: () {
                print(_writeController.value.text);
                Navigator.pop(context);

                if(_writeController.value.text.isNotEmpty){
                    print(_writeController.value.text);
                    buttonList[buttonList.length-1].value = _writeController.value.text;
                }
              },
            ),
            FlatButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      });
  }



  void refreshImage() {

    Bitmap closePathImage = Bitmap.fromHeadless(bitmap.width, bitmap.height, imageBitmap.getClosedPathBitmapAsIntList());
    Uint8List headedBitmap = closePathImage.buildHeaded();
    

    processedImage = Image.memory(
      headedBitmap, 
      width: bitmap.width.toDouble(), 
      height: 560);
  }


  Future<void> loadImageAsBitmap (path) async {

    bitmap = await Bitmap.fromProvider(FileImage(File(path)));
    imageBitmap.init(bitmap);

    print("IMAGE SIZE: ${bitmap.width} x ${bitmap.height}");

    processImage();
  }

  void processImage(){

    imageBitmap.applyGaussianBlurFilter(5);
    imageBitmap.performSobelEdgeDetection();
    imageBitmap.performNonMaximaSuppression();
    imageBitmap.lookForClosedPaths();

    RectangleFrame patternFrame = imageBitmap.searchPattern(tag);

    if(patternFrame != null){
      tagFrame = new RectangleFrame(patternFrame.x, patternFrame.y, patternFrame.width, patternFrame.height);
      double tagDimension = (tagFrame.width + tagFrame.height) / 2;
      pixelToMmRatio = 24.0 / (tagDimension);
    }

    else {
      print("TAG NOT FOUND");

      showDialog(
        context: context,
        
        builder: (BuildContext context) => new CupertinoAlertDialog(
            title: Text("Tag not found"),
            
            content: Text("The tag was not found in the taken picture. please try again."),

            actions: [
              FlatButton(
                onPressed: (){
                  Navigator.pop(context);
                   Navigator.pop(context);
                },
                child: Text("Try again"),
              )
            ],
        )
      );
    }
    refreshImage();
  }
}