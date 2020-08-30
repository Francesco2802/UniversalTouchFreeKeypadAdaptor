

/*
  class: AxisHandler

  Constructor:

  - AxisHandler
    @parameters: _motorAPin<uint8_t>, _motorBPin<uint8_t> pin connected to the motor
    @parameters: _encoderA<uint8_t>, _encoderB<uint8_t>  pin connected to the encoder
    @parameter:  _zeroSwitch<uint8_t> pin connected to the home switch

  methods:

  - init
    @parameters: none
    @return: none
    @description: initialize the GPIO's

  - setTarget
    @parameter: targetPosition<int>
    @return: none
    @description: set the axis target position and makes the axis move in that direction

  - run
    @parameter: none
    @return none
    @description: check if the axis has reached the target position. This function must be called periodically.

  - reachedTarget
    @parameter: none
    @return: targetReached<bool>
    @description: return true if the axis has reached the target position, otherwise false

  - calibrate
    @parameter: none
    @return: none
    @description: brings the axis to it's home position (where the home switch is pressed)
                  and resets the encoder counter


*/

class AxisHandler {

  private:

    uint8_t motorAPin;
    uint8_t motorBPin;

    uint8_t encoderAPin;
    uint8_t encoderBPin;

    uint8_t pwmPin;

    uint8_t zeroSwitchPin;

    int16_t targetPos;
    uint8_t targetReached;


  public:
    EncoderHandler encoderHandler;


    AxisHandler(uint8_t _motorAPin, uint8_t _motorBPin, uint8_t _encoderA, uint8_t _encoderB, uint8_t _zeroSwitch): motorAPin(_motorAPin), motorBPin(_motorBPin), encoderAPin(_encoderA), encoderBPin(_encoderB), zeroSwitchPin(_zeroSwitch) {
    }


    void init() {

      encoderHandler.init(encoderAPin, encoderBPin);

      pinMode(motorAPin, OUTPUT);
      pinMode(motorBPin, OUTPUT);

      digitalWrite(motorBPin, LOW);
      digitalWrite(motorAPin, LOW);

      pinMode(zeroSwitchPin, INPUT);
    }

    void setTarget(int16_t _targetPos) {
      targetPos = _targetPos;

      run();
    }

    void run() {

      if (targetPos > encoderHandler.getPos() + 1) {

        digitalWrite(motorBPin, LOW);
        digitalWrite(motorAPin, HIGH);
        targetReached = 0;
      }
      else if (targetPos < encoderHandler.getPos() - 1) {
        digitalWrite(motorAPin, LOW);
        digitalWrite(motorBPin, HIGH);
        targetReached = 0;
      }
      else {
        digitalWrite(motorBPin, LOW);
        digitalWrite(motorAPin, LOW);
        targetReached = 1;
      }
    }

    uint8_t reachedTarget() {
      return targetReached;
    }


    void calibrate() {

      while (digitalRead(zeroSwitchPin) == 1) {

        digitalWrite(motorAPin, LOW);
        digitalWrite(motorBPin, HIGH);
      }

      digitalWrite(motorBPin, LOW);
      digitalWrite(motorAPin, LOW);

      encoderHandler.setZero();
    }
    void stop() {
      digitalWrite(motorBPin, LOW);
      digitalWrite(motorAPin, LOW);
    }
};
