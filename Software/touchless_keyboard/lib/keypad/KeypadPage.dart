



import 'package:flutter/material.dart';
import 'package:touchless_keyboard/image_processing/CameraHandler.dart';
import 'KeypadButtonWidget.dart';
import 'dart:math';
import '../keypad_configuration/KeypadCellDescriptor.dart';


class KeypadPage extends StatefulWidget {

  KeypadPage(this.disconnectFromDeviceCallback, this.camera, this.writeConfigurationLayout, this.keypadLayoutConfigurationList, this.buttonPressedCallback);

  final disconnectFromDeviceCallback;
  final camera;
  final writeConfigurationLayout;
  final keypadLayoutConfigurationList;
  final buttonPressedCallback;

  final configurationButtonLength = 11;

  @override 
  KeypadPageState createState() => KeypadPageState();

}


class KeypadPageState extends State<KeypadPage> {

  int displayWidth;
  int displayHeight;

  List<Button> buttonList = [];


  @override 
  void initState() {

    super.initState();

    int numberOfButtons = widget.keypadLayoutConfigurationList.length ~/  widget.configurationButtonLength;

    print("\n\n\nConfiguration string length: ${widget.keypadLayoutConfigurationList.length}, N buttons:$numberOfButtons");

    for(int i=0; i<numberOfButtons; i+=1){

      String value = "";
      for(int j=0;j<5; j+=1)value += String.fromCharCode(widget.keypadLayoutConfigurationList[i*widget.configurationButtonLength+j]);
      int xPos = (widget.keypadLayoutConfigurationList[i*widget.configurationButtonLength+7] << 8) | widget.keypadLayoutConfigurationList[i*widget.configurationButtonLength+6];
      int yPos = (widget.keypadLayoutConfigurationList[i*widget.configurationButtonLength+9] << 8) | widget.keypadLayoutConfigurationList[i*widget.configurationButtonLength+8];
      int tag = widget.keypadLayoutConfigurationList[i*widget.configurationButtonLength+10];

      if(xPos > 32768) xPos = -(65536 - xPos);
      if(yPos > 32768) yPos = -(65536 - yPos);
      
      buttonList.add(Button(xPos,yPos, 10, 10, value, true, tag));
      print("$value, $xPos, $yPos, <$i>");
    }
  }



  @override 
  Widget build(BuildContext context) {
    
    displayWidth =  MediaQuery.of(context).size.width.toInt()-40;
    displayHeight = MediaQuery.of(context).size.height.toInt()-40;
    
    return Scaffold(

      appBar: AppBar(
        title: Text("Keypad"),

        actions: [
          FlatButton(
            onPressed: widget.disconnectFromDeviceCallback,
            child: Text("Disconnect", style:TextStyle(color: Colors.white)),
            textColor: Colors.white,
          ),

          FlatButton(
            onPressed: () async {
              print("Configure Keypad");

              List<Button> configButtonList = await Navigator.push(context, MaterialPageRoute(
                builder: (context) => TakePictureScreen(widget.camera, widget.writeConfigurationLayout),
              ));

              if(configButtonList != null){
                print("New config!");

                setState(() {
                  buttonList = configButtonList;
                });
              }
            },
            child: Text("Configure", style:TextStyle(color: Colors.white)),
            textColor: Colors.white,
          ),
        ],
      ),

      body: Center(
        child: Padding(
        padding: EdgeInsets.all(20),
        child: Stack(

          children: buildButtonMatrix(),
        ),
      ),
      ),
    );
  }




  List<Widget> buildButtonMatrix () {

    int offsetX = displayWidth, offsetY = displayHeight, neededWidth, neededHeight;
    int maxX=0, maxY=0;

    //print(buttonList.length);

    buttonList.forEach((button ) {
      if(button.x < offsetX) offsetX = button.x;
      if(button.y < offsetY) offsetY = button.y;

      if(button.x + button.width > maxX) maxX = button.x + button.width;
      if(button.y + button.height > maxY)maxY = button.y + button.height;
    });

    neededWidth = maxX - offsetX;
    neededHeight = maxY - offsetY;

    double ratio = min(displayWidth/neededWidth, displayHeight/neededHeight);

    List<KeypadButtonWidget> buttons = [];

    buttonList.forEach((button) { 

      buttons.add(KeypadButtonWidget(button, offsetX, offsetY, ratio, buttonPressedCallback));
    });

    return buttons;
  }

  void buttonPressedCallback(Button button){
    print(button.value);

  widget.buttonPressedCallback(button.buttonTag);

  }
}