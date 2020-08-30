


void compileButtonGrid() {
  int columns = 0, rows = 0;

  int rowPosition[10] {};
  int columnPosition[10] {};


  for (uint8_t i = 0; i < numberOfButtons; i += 1) {

    bool existingRow = false;
    for (uint8_t j = 0; j < rows; j++) {

      if (abs(buttons[i].xPos - rowPosition[j]) < 10) {
        existingRow = true;
        break;
      }
    }
    if (!existingRow) {
      rowPosition[rows] = buttons[i].xPos;

      for (uint8_t pos = rows; pos > 0; pos -= 1) {

        if (buttons[i].xPos < rowPosition[pos - 1]) {
          rowPosition[pos] = rowPosition[pos - 1];
          rowPosition[pos - 1] = buttons[i].xPos;
        } else break;
      }
      rows += 1;
    }

    bool existingColumn = false;
    for (uint8_t j = 0; j < columns; j++) {

      if (abs(buttons[i].yPos - columnPosition[j]) < 10) {
        existingColumn = true;
        break;
      }
    }
    if (!existingColumn) {
      columnPosition[columns] = buttons[i].yPos;

      for (uint8_t pos = columns; pos > 0; pos -= 1) {

        if (buttons[i].yPos < columnPosition[pos - 1]) {
          columnPosition[pos] = columnPosition[pos - 1];
          columnPosition[pos - 1] = buttons[i].yPos;
        } else break;
      }
      columns += 1;
    }
  }
  gridColumns = columns;
  gridRows = rows;

  for (uint8_t i = 0; i < rows; i++) {
    Serial.print(rowPosition[i]); Serial.print(", ");
  } Serial.println();

  for (uint8_t i = 0; i < columns; i++) {
    Serial.print(columnPosition[i]); Serial.print(", ");
  } Serial.println();


  for (uint8_t i = 0; i < numberOfButtons; i++) {

    uint8_t c, r;
    for (c = 0; c < columns; c++) {
      if (abs(buttons[i].xPos - rowPosition[c]) < 10)break;
    }
    for (r = 0; r < rows; r++) {
      if (abs(buttons[i].yPos - columnPosition[r]) < 10)break;
    }
    buttonGrid[r][c] = buttons[i].tag;
    Serial.print(c); Serial.print("   "); Serial.println(r);
  }

  for (uint8_t r = 0; r < rows; r++) {
    Serial.print("| ");
    for (uint8_t c = 0; c < columns; c++) {
      Serial.print(buttonGrid[r][c]); Serial.print("   ");
    }
    Serial.println("|");
  }
}
