/*
  author: Gritti Francesco
  date:   7/7/2020

  class: Encoderhandler

  Constructor: default

  methods: 

  - init
    @paramters _signalAPin<uint8_t>, signalBPin<uint8_t> pin connected to the output A and B of the quadrature output encoder
    @return: none
    @description: initialize the GPIO used by the encoder

  - getPos
    @parameter: none
    @return: pos<int16>
    @description: return the current encoder position

  - setZero
    @paramter: none
    @return : none
    @description reset the encoder counter

  - BSignalCallbackhandler
    @parameter: none
    @return: none
    @description: this method updates the encoder value. It must be called by the ISR that handles the interrupt thrown
                  by the pin connected to the output signal B of the encoder.
*/


class EncoderHandler {

  private:

    uint8_t signalAPin;
    uint8_t signalBPin;

    volatile uint8_t prevEncoderAPinState;
    volatile uint8_t prevEncoderBPinState;

    volatile int16_t pos;

    void gpioInit() {
      pinMode(signalAPin, INPUT);
      pinMode(signalBPin, INPUT);

      prevEncoderAPinState = digitalRead(signalAPin);
      prevEncoderBPinState = digitalRead(signalBPin);

      Serial.println("init");
    }

  public:


    void init(uint8_t _signalAPin, uint8_t _signalBPin) {
      signalAPin = _signalAPin;
      signalBPin = _signalBPin;
      
      gpioInit();
    }

    int16_t getPos() {
      return pos;
    }

    void setZero() {
      pos = 0;
    }

    void B_SignalCallbackHandler() {
      uint8_t A_state = digitalRead(signalAPin);
      uint8_t B_state = digitalRead(signalBPin);

      if (B_state != prevEncoderBPinState) {
        prevEncoderBPinState = B_state;

        if (B_state) {

          if (A_state) {
            pos --;
          }
          else pos ++;
        }
        else {
          if (A_state) {
            pos ++;
          }
          else pos --;
        }
      }
    }
};
