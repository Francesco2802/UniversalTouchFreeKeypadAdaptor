

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'KeypadCellDescriptor.dart';
import 'KeypadConfigurationButtonWidget.dart';

import 'dart:math';



class KeypadConfigurationPage extends StatefulWidget {

  KeypadConfigurationPage(this.buttonList, this.writeConfigurationLayout) {

  }
  
  List<Button> buttonList; 
  final writeConfigurationLayout;

  @override
  KeypadConfigurationPageState createState() => KeypadConfigurationPageState(buttonList);
}


class KeypadConfigurationPageState extends State<KeypadConfigurationPage>{

  int displayWidth;
  int displayHeight;

  KeypadConfigurationPageState(this.buttonList){

  }

  List<Button> buttonList;

  @override 
  void initState() {

    super.initState();
  }


  @override 
  Widget build(BuildContext context) {

    displayWidth =  MediaQuery.of(context).size.width.toInt()-40;
    displayHeight = MediaQuery.of(context).size.height.toInt()-40;
    
    return Scaffold(

      appBar: AppBar(
        title: Text("Keypad Configuration"),

        actions: [
          FlatButton(

            onPressed: () {
              print("Save");

            int numberOfButtons = buttonList.length;
            print("Number of buttons: $numberOfButtons");

            List<int> configurationArray = List(numberOfButtons*11);

            print("OK");


            for(int i=0;i<numberOfButtons; i+=1){

              print(i);
              for(int j=0;j<buttonList[i].value.length; j++)configurationArray[i*11+j] = buttonList[i].value.codeUnitAt(j);
              for(int j=buttonList[i].value.length;j<6; j++)configurationArray[i*11+j] = 0;

              configurationArray[i*11+6] = buttonList[i].x & 0xff;
              configurationArray[i*11+7] = (buttonList[i].x>>8) & 0xff;

              configurationArray[i*11+8] = buttonList[i].y & 0xff;
              configurationArray[i*11+9] = (buttonList[i].y>>8) & 0xff;

              configurationArray[i*11+10] = buttonList[i].buttonTag;
            }

            print("config array length: ${configurationArray.length}");
            widget.writeConfigurationLayout(configurationArray);

            Navigator.pop(context, buttonList);
            },

            child: Text("Save"),
          ),
        ],
      ),


      body: Padding(
        padding: EdgeInsets.all(20),
        child: Stack(

          children: buildButtonMatrix(),

        ),
      ),
    );
  }



  List<Widget> buildButtonMatrix () {

    int offsetX = displayWidth, offsetY = displayHeight, neededWidth, neededHeight;
    int maxX=0, maxY=0;

    widget.buttonList.forEach((button ) {
      if(button.x < offsetX) offsetX = button.x;
      if(button.y < offsetY) offsetY = button.y;

      if(button.x + button.width > maxX ) maxX = button.x + button.width;
      if(button.y + button.height > maxY) maxY = button.y + button.height;
    });

    neededWidth  = maxX - offsetX;
    neededHeight = maxY - offsetY;

    double ratio = min(displayWidth/neededWidth, displayHeight/neededHeight);

    List<KeypadConfigurationButtonWidget> buttons = [];

    widget.buttonList.forEach((button) { 
      print("<${button.width*ratio} x ${button.height*ratio}>");
      buttons.add(KeypadConfigurationButtonWidget(button, offsetX, offsetY, ratio, 
        (String newValue, int buttonTag){

          setState((){
            for(int i=0;i<buttonList.length; i+=1){
              if(buttonList[i].buttonTag == buttonTag){
                buttonList[i].value = newValue;
                break;
              }
            }
          });
        }
      ));
    });

    return buttons;
  }
}