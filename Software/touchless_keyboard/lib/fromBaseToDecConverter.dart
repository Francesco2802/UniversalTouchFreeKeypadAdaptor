
import 'dart:math';

final alphaDigitConversion = {10:'A',11:'B', 12:'C', 13:'D', 14:'E', 15:'F'};
  
String convertDecTo(int dec, int base) {
    String convertedString = "";

    var greatestPower =  0;
    var n = dec;

    while (n >= base) { 
      n = n ~/ base;
      greatestPower ++;
    } 
    n=dec;
    for(; greatestPower >= 0; greatestPower --){

      var power = pow(base, greatestPower);
      var digit = n ~/ power;
      
      if ( alphaDigitConversion[digit] != null) convertedString += alphaDigitConversion[digit];
      else convertedString += digit.toString();
      n -= (power*digit);
    }
    return convertedString;
  }