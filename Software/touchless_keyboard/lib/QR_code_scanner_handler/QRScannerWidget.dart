
import 'package:flutter/material.dart';
import 'package:qrcode/qrcode.dart';

class QRCodeScannerView extends StatefulWidget {

  QRCodeScannerView(this.onCaputreCallbackFunction);

  final onCaputreCallbackFunction;

  @override 
  _QRCodeScannerState createState() => _QRCodeScannerState();
}


class _QRCodeScannerState extends State<QRCodeScannerView> {

  QRCaptureController _captureController = QRCaptureController();
  bool _isTorchOn = false;

  void capture (data) {

    _captureController.pause();
    widget.onCaputreCallbackFunction(data);

    _captureController.pause();
  }


  @override
  void initState() {
    super.initState();

    _captureController.onCapture(capture);
    _captureController.resume();
  }

  @override
  Widget build(BuildContext context) {

    _captureController.resume();

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          QRCaptureView(controller: _captureController),

          Align(
            alignment: Alignment(-0.95, 0.95),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.all(Radius.circular(29)),
              ),
              height:58, 
              width:58, 
              child: _buildFlashToggleButton()
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFlashToggleButton() {

    return IconButton(
      onPressed: () {

        if (_isTorchOn) {
          _captureController.torchMode = CaptureTorchMode.off;
        } else {
          _captureController.torchMode = CaptureTorchMode.on;

        }
        setState((){_isTorchOn = !_isTorchOn;});
      },
      icon: Icon( _isTorchOn ? Icons.flash_on:  Icons.flash_off),
      color: Colors.white60,
      iconSize: 40,

    );
  }
}