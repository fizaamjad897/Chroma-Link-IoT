// ChromaLink IoT - Arduino C reference implementation.
// Same behavior as firmware/avr-asm/main.asm, handy for quick testing
// in the Arduino IDE before flashing the assembly version.

const uint8_t PIN_RED = 9;
const uint8_t PIN_GREEN = 10;
const uint8_t PIN_BLUE = 11;
const uint8_t PIN_BUZZER = 12;

enum Mode : uint8_t { MODE_OFF, MODE_YELLOW, MODE_MAGENTA, MODE_WHITE, MODE_CYCLE };

// Button pin -> mode it selects (active low)
struct Button { uint8_t pin; Mode mode; };
const Button BUTTONS[] = {
  { 2, MODE_YELLOW }, { 3, MODE_MAGENTA }, { 4, MODE_WHITE }, { 5, MODE_CYCLE }, { 6, MODE_OFF },
};

// Colors packed as 0bRGB
const uint8_t OFF = 0b000, RED = 0b100, GREEN = 0b010, BLUE = 0b001;
const uint8_t YELLOW = RED | GREEN, MAGENTA = RED | BLUE, CYAN = GREEN | BLUE, WHITE = RED | GREEN | BLUE;

const uint8_t MODE_COLORS[] = { OFF, YELLOW, MAGENTA, WHITE };
const uint8_t CYCLE_COLORS[] = { RED, GREEN, BLUE, YELLOW, CYAN, MAGENTA, WHITE, OFF };
const unsigned long CYCLE_STEP_MS = 500;

Mode mode = MODE_OFF;
uint8_t cycleStep = 0;
unsigned long lastStepAt = 0;

void setColor(uint8_t rgb) {
  digitalWrite(PIN_RED, rgb & RED ? HIGH : LOW);
  digitalWrite(PIN_GREEN, rgb & GREEN ? HIGH : LOW);
  digitalWrite(PIN_BLUE, rgb & BLUE ? HIGH : LOW);
}

void showCycleStep() {
  setColor(CYCLE_COLORS[cycleStep]);
  cycleStep = (cycleStep + 1) % sizeof(CYCLE_COLORS);
  lastStepAt = millis();
}

void applyMode(Mode m) {
  mode = m;
  if (mode == MODE_CYCLE) {
    cycleStep = 0;
    showCycleStep();
  } else {
    setColor(MODE_COLORS[mode]);
  }
}

// Returns true and sets `out` when a button or serial command asks for a mode.
bool readInput(Mode &out) {
  for (const Button &b : BUTTONS) {
    if (digitalRead(b.pin) == LOW) {
      out = b.mode;
      return true;
    }
  }
  if (Serial.available()) {
    char c = Serial.read();
    if (c >= '1' && c <= '5') {
      out = (c == '5') ? MODE_OFF : static_cast<Mode>(c - '0');
      return true;
    }
  }
  return false;
}

void setup() {
  pinMode(PIN_RED, OUTPUT);
  pinMode(PIN_GREEN, OUTPUT);
  pinMode(PIN_BLUE, OUTPUT);
  pinMode(PIN_BUZZER, OUTPUT);
  for (const Button &b : BUTTONS) pinMode(b.pin, INPUT_PULLUP);
  Serial.begin(9600);

  // Startup sequence: 3 s beep, then all LEDs on for 2 s
  digitalWrite(PIN_BUZZER, HIGH);
  delay(3000);
  digitalWrite(PIN_BUZZER, LOW);
  setColor(WHITE);
  delay(2000);
  applyMode(MODE_OFF);
}

void loop() {
  Mode requested;
  if (readInput(requested) && requested != mode) applyMode(requested);

  if (mode == MODE_CYCLE && millis() - lastStepAt >= CYCLE_STEP_MS) showCycleStep();
}
