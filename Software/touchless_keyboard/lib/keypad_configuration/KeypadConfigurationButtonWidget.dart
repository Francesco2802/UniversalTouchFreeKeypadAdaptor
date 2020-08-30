


import 'package:flutter/material.dart';
import 'KeypadCellDescriptor.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';





class KeypadConfigurationButtonWidget extends StatelessWidget {


  KeypadConfigurationButtonWidget(this.button, this.offsetX, this.offsetY, this.ratio, this.valueChangedCallback);


  Button button;
  int offsetX, offsetY;
  double ratio;

  final _writeController = TextEditingController();

  final valueChangedCallback;


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

            onPressed: () async {
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
                              valueChangedCallback(_writeController.value.text, button.buttonTag);
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