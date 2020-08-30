

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:camera/camera.dart';

import 'fromBaseToDecConverter.dart';
import 'QR_code_scanner_handler/QRScannerWidget.dart';

import 'keypad/KeypadPage.dart';



enum ApplicationState {showQRScanner, showKeypad, showConfigurationPage }


Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;


  runApp(HomePage(firstCamera));
}


class HomePage extends StatefulWidget {

  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final Map<BluetoothDevice, String> devicesList = Map<BluetoothDevice, String>();

  final String keypadServiceUUID = "19b10000-e8f2-537e-4f6c-d104768a1214";
  final String keypadCharacteristicUUID = "19b10001-e8f2-537e-4f6c-d104768a1214";
  final String keypadConfigurationLayoutServiceUUID = "19b10000-e8f2-537e-4f6c-d104768a9183";
  final String keypadConfiguationLayoutCharacteristicUUID = "19b10001-e8f2-537e-4f6c-d104768a9183";

  final camera;

  HomePage(this.camera);

  
  @override
_HomePageState createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {

  ApplicationState applicationState = ApplicationState.showQRScanner;


  var showQRCodereader = true;
  List<int> keypadLayoutConfigurationArray = [];

  BluetoothDevice _connectedDevice = null;
  List<BluetoothService> _servicesList;
  BluetoothCharacteristic _keypadCharacteristic;
  BluetoothCharacteristic _keypadConfigurationLayoutCharacteristic;

  bool connecting = false;


  @override 
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,
      
      home: applicationState == ApplicationState.showQRScanner? 
                                  QRCodeScannerView(QRScannerOnCaptureCallback) :
                                  KeypadPage(disconnectCallbackFunction, widget.camera, writeKeypadConfigurationLayout, keypadLayoutConfigurationArray, keyPressedCallback),
      
    );
  }

  @override 
  void initState() {
    super.initState();

    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {

        widget.devicesList[device] = "";
      }
    });

    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        var data = "";

        result.advertisementData.manufacturerData.forEach((key, value) { 

          int keyData1 = (key >> 8);
          int keyData2 = (key & 0xff);

          List newList = [keyData2, keyData1];
          newList.addAll(value);

          data = "";

          for(int element in newList) {
            data += convertDecTo(element, 16);
          }
        });
        print("${result.device.name} -> $data");

         widget.devicesList[result.device] = data;
      }
    });
    widget.flutterBlue.startScan();
  }


  void updateKeypadConfigurationString (List<int> newConfigString) {
    keypadLayoutConfigurationArray = newConfigString;
  }

  void readButtonList () {


  }
  
  void writeKeypadConfigurationLayout(List<int> newKeypadLayoutConfiguration) {

    print("Write config.");

    _keypadConfigurationLayoutCharacteristic.write(newKeypadLayoutConfiguration);
  }

  void configureKeypadLayoutCallback() {

    setState(() {
      applicationState = ApplicationState.showConfigurationPage;
    });
  }

  Future <bool> _connectToDevice(BluetoothDevice device) async {

    if(_connectedDevice != null)return false;

    widget.flutterBlue.stopScan();

    try {
      connecting = true;
      await device.connect();
    } 
    catch (e) {
      if (e.code != 'already_connected') {
        return false;
      }
    } finally {
      print("Device already connected");
      _servicesList = await device.discoverServices();

      print("--------------------------------------- Discovered Services ----------------------------------");

      for (BluetoothService service in _servicesList) {

        if(service.uuid.toString() == widget.keypadServiceUUID) {
          print("Found keypad service UUID!");

          for(BluetoothCharacteristic characteristic in service.characteristics){

            if(characteristic.uuid.toString() == widget.keypadCharacteristicUUID) {

              print("Found keypad characteristic UUID!");
              _keypadCharacteristic = characteristic;
              break;
            }
          }
        }
        print(service.uuid.toString());
        if (service.uuid.toString() == widget.keypadConfigurationLayoutServiceUUID) {
          print("Found keypad config service UUID!");

          for(BluetoothCharacteristic characteristic in service.characteristics){

            if(characteristic.uuid.toString() == widget.keypadConfiguationLayoutCharacteristicUUID) {
              print("Found keypad config characteristic UUID!");

              _keypadConfigurationLayoutCharacteristic = characteristic;

              keypadLayoutConfigurationArray = await _readKeypadConfiguration();
              break;
            }
          }
        }
      }
      connecting = false;
    }
    
    return true;
  }

  Future<List<int>> _readKeypadConfiguration() async {

    print("Try to read keypad config");

    List<int> returnString = List<int>();

    var sub = _keypadConfigurationLayoutCharacteristic.value.listen((value) {
        returnString = value;
    });
    await _keypadConfigurationLayoutCharacteristic.read();
    await _keypadConfigurationLayoutCharacteristic.read();
    sub.cancel();
    return returnString;
  }


 void QRScannerOnCaptureCallback(data) async {

   if(_connectedDevice != null)return;
   if(connecting == true) return;

    if(data is String) {

      print(data);

      var foundMatch = false;

      widget.devicesList.forEach((device, value) async {
        print("$value, $data");
        if(value == data){
          foundMatch = true;

          print("Found Device -> ${device.name}");

          var success = await _connectToDevice(device);

          if(success) {
            print("Connected!");
            _connectedDevice = device;

            setState(() {
              applicationState = ApplicationState.showKeypad;
            });
          }
          else print("Connection failed");
        }
        
      });
      if(foundMatch == false)setState((){});
    }
  }

  void disconnectCallbackFunction() async {

    try {
      await _connectedDevice.disconnect();
    } catch (err){
      print("an error occurred while trying to disconnect from device ${_connectedDevice.name}");
    }
    finally {
      setState(() {
        applicationState = ApplicationState.showQRScanner;
      });
      widget.flutterBlue.startScan();
      _connectedDevice = null;
    }
  }

  void keyPressedCallback (int buttonTag) {

    List<int> data = [buttonTag];
    _keypadCharacteristic.write(data);
  }

}

