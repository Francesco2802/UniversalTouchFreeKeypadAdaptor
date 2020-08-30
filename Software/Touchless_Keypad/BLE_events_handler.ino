

void newConfigurationWrittenHandler(BLEDevice device, BLECharacteristic _characteristic) {

  int incomingDataLength = keypadConfigurationCharacteristic.valueLength();
  numberOfButtons = incomingDataLength / sizeof(Button);

  keypadConfigurationCharacteristic.readValue((uint8_t*)(& buttons), numberOfButtons * sizeof(Button));

  Serial.print("data length: "); Serial.println(incomingDataLength);
  Serial.print("number of buttons: "); Serial.println(numberOfButtons);

  for (uint8_t i = 0;  i < numberOfButtons; i ++) {
    Serial.println();
    Serial.println(buttons[i].value);
    Serial.print(buttons[i].xPos); Serial.print(" . "); Serial.println(buttons[i].yPos);
    Serial.println(buttons[i].tag);
  }
  saveKeypadLayout = true;
}

void buttonPressedHandler(BLEDevice device, BLECharacteristic _characteristic) {

  uint8_t buttonTag;
  _characteristic.readValue(&buttonTag, 1);
  Serial.println(buttonTag);

  int8_t pressedButtonIndex = buttonIndexForTag(buttonTag);

  if (pressedButtonIndex != -1) {
    pressButton(pressedButtonIndex);
  }
}
