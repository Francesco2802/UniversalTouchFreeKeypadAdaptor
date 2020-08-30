


import 'package:flutter/material.dart';
import '../keypad_configuration/KeypadCellDescriptor.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';





class KeypadButtonWidget extends StatelessWidget {


  KeypadButtonWidget(this.button, this.offsetX, this.offsetY, this.ratio, this.buttonPressedCallback);


  Button button;
  int offsetX, offsetY;
  double ratio;

  final buttonPressedCallback;


  @override 
  Widget build(BuildContext context) {


    return Positioned(

      top: (button.y-offsetY)*ratio,
      left: (button.x-offsetX)*ratio,

      width: button.width*ratio,
      height: button.height*ratio,

      child: Container(

        decoration: BoxDecoration(
          //color: Colors.red,
        ),
        child: Center(

          child: RaisedButton(

            onPressed: () {
              buttonPressedCallback(button);
            },

            color: Colors.blueGrey,
            child: FittedBox(child: Text(button.value, style: TextStyle(fontSize: 100))),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(min(button.width*ratio, button.height*ratio)/3.5))
            ),
          ),
        )
      )
    );
  }

}