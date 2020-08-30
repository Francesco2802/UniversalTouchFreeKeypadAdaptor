

class KeypadCellDescriptor {

  String buttonValue;
  bool buttonState;
  int buttonTag;

  KeypadCellDescriptor(this.buttonValue, this.buttonState, this.buttonTag);
}

class KeypadStructure {

  List<KeypadCellDescriptor> buttonList = [];

  int rows;
  int columns;
}


class Button {
  int x;
  int y;

  int width;
  int height;

  String value;

  bool buttonState;
  int buttonTag;

  Button(this.x, this.y, this.width, this.height, this.value, this.buttonState, this.buttonTag);
}