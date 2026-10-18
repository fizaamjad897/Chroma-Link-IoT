// Copy this file to config.h and fill in your own values.
// config.h is gitignored so credentials never end up on GitHub.
#pragma once

#define WIFI_SSID "your-wifi-name"
#define WIFI_PASSWORD "your-wifi-password"

#define MQTT_BROKER "broker.hivemq.com"
#define MQTT_PORT 1883
// Public broker: pick a topic nobody else is likely to use.
#define MQTT_TOPIC "chromalink-iot/your-name/mode"

#define THINGSPEAK_API_KEY "your-thingspeak-write-key"
