

#define ADDRESS_A8_RESET  0x50
#define ADDRESS_A8_SET    0x51

#define PAGE_SIZE         16


int8_t EEPROM_writeBuffer (uint16_t address, uint8_t* buffer, uint16_t length) {

  Wire.beginTransmission(address < 0x0ff ? ADDRESS_A8_RESET : ADDRESS_A8_SET);
  uint8_t addr = (uint8_t) address;
  Wire.write(addr);

  for (uint16_t i = 0; i < length; i++) {

    Wire.write(buffer[i]);
    address += 1;

    uint8_t endOfPage = (uint8_t)address & 0b00001111;

    if (endOfPage == 0 && i > 0 ) {

      Wire.endTransmission();

      Wire.beginTransmission(ADDRESS_A8_RESET);
      while (Wire.endTransmission() != 0);

      Wire.beginTransmission(address < 0x0ff ? ADDRESS_A8_RESET : ADDRESS_A8_SET);
      uint8_t addr = (uint8_t) address;
      Wire.write(addr);
    }
  }
  uint8_t returnValue = 0;
  if (Wire.endTransmission() == 0)returnValue = 1;

  Wire.beginTransmission(ADDRESS_A8_RESET);
  while (Wire.endTransmission() != 0);

  return returnValue;
}

int8_t EEPROM_readBuffer(uint16_t address, uint8_t *buffer, uint16_t length) {

  uint16_t readIndex = 0;

  Wire.beginTransmission( address < 0x0ff ? ADDRESS_A8_RESET : ADDRESS_A8_SET );

  uint8_t addr = (uint8_t)address;
  Wire.write(addr);
  Wire.endTransmission(false);

  while (Wire.available() > 0)Wire.read();

  Wire.requestFrom(ADDRESS_A8_SET, length);

  while (Wire.available() == 0);
  while (Wire.available() > 0) {
    buffer[readIndex] = Wire.read();
    readIndex += 1;
  }

  return 0;
}

int8_t EEPROM_clear() {

  for (uint8_t i = 0; i < 32; i++) {

    Wire.beginTransmission( i < 16 ? ADDRESS_A8_RESET : ADDRESS_A8_SET );

    uint16_t addr = ((uint16_t)i << 4);
    Wire.write(addr);

    for (uint8_t j = 0; j < 16; j++) {
      Wire.write(0x00);
    }

    Wire.endTransmission();

    Wire.beginTransmission(ADDRESS_A8_RESET);
    while (Wire.endTransmission() != 0);
  }

  return 0;
}



