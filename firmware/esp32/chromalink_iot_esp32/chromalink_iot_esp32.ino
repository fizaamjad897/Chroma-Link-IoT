// ChromaLink IoT - ESP32 IoT bridge.
//
// Subscribes to an MQTT topic (driven by the MQTT Dash phone app),
// forwards each command '1'..'5' to the Arduino UNO over UART2, and logs
// the resulting LED state to ThingSpeak.
//
// Wiring: ESP32 GPIO17 (TX2) -> UNO D0 (RX), and a shared GND.

#include <WiFi.h>
#include <PubSubClient.h>
#include <HTTPClient.h>
#include "config.h"

const int UNO_TX_PIN = 17;
const int UNO_RX_PIN = 16;  // unused, UNO never replies
const unsigned long THINGSPEAK_MIN_INTERVAL_MS = 15000;  // free-tier rate limit

// ThingSpeak fields: red, green, blue, cycle - indexed by command '1'..'5'
struct LedState { uint8_t r, g, b, cycle; };
const LedState STATES[] = {
  { 1, 1, 0, 0 },  // '1' yellow
  { 1, 0, 1, 0 },  // '2' magenta
  { 1, 1, 1, 0 },  // '3' white
  { 0, 0, 0, 1 },  // '4' color cycle
  { 0, 0, 0, 0 },  // '5' off
};

WiFiClient wifiClient;
PubSubClient mqtt(wifiClient);

int pendingLog = -1;  // index into STATES waiting to be sent to ThingSpeak
unsigned long lastLogAt = 0;

void onMqttMessage(char *topic, byte *payload, unsigned int length) {
  for (unsigned int i = 0; i < length; i++) {
    char c = (char)payload[i];
    if (c < '1' || c > '5') continue;
    Serial2.write(c);
    pendingLog = c - '1';
    Serial.printf("Command %c forwarded to UNO\n", c);
  }
}

void ensureWifi() {
  if (WiFi.status() == WL_CONNECTED) return;
  Serial.print("Connecting to WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print('.');
  }
  Serial.printf("\nConnected, IP %s\n", WiFi.localIP().toString().c_str());
}

void ensureMqtt() {
  while (!mqtt.connected()) {
    String clientId = "chromalink-iot-" + WiFi.macAddress();
    Serial.printf("Connecting to MQTT broker %s as %s\n", MQTT_BROKER, clientId.c_str());
    if (mqtt.connect(clientId.c_str())) {
      mqtt.subscribe(MQTT_TOPIC);
      Serial.printf("Subscribed to %s\n", MQTT_TOPIC);
    } else {
      Serial.printf("MQTT connect failed (state %d), retrying\n", mqtt.state());
      delay(2000);
    }
  }
}

// Sends the latest state only; rapid taps in the app collapse into one update.
void flushThingSpeakLog() {
  if (pendingLog < 0 || millis() - lastLogAt < THINGSPEAK_MIN_INTERVAL_MS) return;

  const LedState &s = STATES[pendingLog];
  char url[160];
  snprintf(url, sizeof(url),
           "http://api.thingspeak.com/update?api_key=%s&field1=%u&field2=%u&field3=%u&field4=%u",
           THINGSPEAK_API_KEY, s.r, s.g, s.b, s.cycle);

  HTTPClient http;
  http.begin(url);
  int status = http.GET();
  http.end();

  if (status == HTTP_CODE_OK) {
    Serial.println("Logged to ThingSpeak");
  } else {
    Serial.printf("ThingSpeak update failed (%d)\n", status);
  }
  pendingLog = -1;
  lastLogAt = millis();
}

void setup() {
  Serial.begin(115200);  // debug console only
  Serial2.begin(9600, SERIAL_8N1, UNO_RX_PIN, UNO_TX_PIN);
  WiFi.mode(WIFI_STA);
  mqtt.setServer(MQTT_BROKER, MQTT_PORT);
  mqtt.setCallback(onMqttMessage);
}

void loop() {
  ensureWifi();
  ensureMqtt();
  mqtt.loop();
  flushThingSpeakLog();
}
