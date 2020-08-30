
#define Matrix_Row_Count  5
#define Matrix_Column_Count  5


#define IR_THRESHOLD_VALUE  900

class IREmitterMatrix_Handler {
  private:

    uint8_t b0_pin;
    uint8_t b1_pin;
    uint8_t b2_pin;
    uint8_t b3_pin;
    uint8_t _inputPin;

    uint8_t _index;

  public:

    IREmitterMatrix_Handler(uint8_t _b0, uint8_t _b1, uint8_t _b2, uint8_t _b3, uint8_t inputPin) : b0_pin(_b0), b1_pin(_b1), b2_pin(_b2), b3_pin(_b3), _inputPin(inputPin) {

    }

    void init() {

      pinMode(b0_pin, OUTPUT);
      pinMode(b1_pin, OUTPUT);
      pinMode(b2_pin, OUTPUT);
      pinMode(b3_pin, OUTPUT);

      digitalWrite(b0_pin, LOW);
      digitalWrite(b1_pin, LOW);
      digitalWrite(b2_pin, LOW);
      digitalWrite(b3_pin, LOW);
    }

    void setValue(uint8_t newIndex) {

      if(newIndex > 9) newIndex = 0;

      if ((newIndex & B00000001) != 0) digitalWrite(b0_pin, HIGH);
      else digitalWrite(b0_pin, LOW);

      if ((newIndex & B00000010) != 0) digitalWrite(b1_pin, HIGH);
      else digitalWrite(b1_pin, LOW);

      if ((newIndex & B00000100) != 0) digitalWrite(b2_pin, HIGH);
      else digitalWrite(b2_pin, LOW);

      if ((newIndex & B00001000) != 0) digitalWrite(b3_pin, HIGH);
      else digitalWrite(b3_pin, LOW);

      _index = newIndex;
    }

    void next () {
      setValue(_index + 1);
    }

    void previous() {
      setValue(_index - 1);
    }



    int8_t scan (uint8_t* _row, uint8_t* _column) {

      setValue(0);

      int8_t selectedRow = -1, selectedCol = -1;

      for (uint8_t col = 0; col < 5; col++) {

        int val = analogRead(_inputPin);

        if (val > IR_THRESHOLD_VALUE) {
          selectedCol = col;
        }

        next();

        delayMicroseconds(10);
      }

      for (uint8_t row = 0; row < 5; row++) {

        int val = analogRead(_inputPin);

        if (val > IR_THRESHOLD_VALUE) {
          selectedRow = row;
        }


        next();

        delayMicroseconds(10);
      }

      if (selectedRow >= 0 && selectedCol >= 0) {

        (*_row) = selectedRow;
        (*_column) = selectedCol;

        return 1;
      }
      return 0;
    }


};
