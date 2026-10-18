# Getting Started

This document outlines general steps to get a development environment ready and how to build the firmware. Update the sections below with platform-specific details.

1) Install toolchain

- If using PlatformIO: https://platformio.org/install
- If using Arduino CLI: https://arduino.github.io/arduino-cli/latest/installation/
- If using a vendor toolchain (ESP-IDF, STM32Cube): follow vendor docs

2) Clone the repo

   git clone https://github.com/fizaamjad897/Chroma-Link-IoT.git
   cd Chroma-Link-IoT

3) Build firmware

- PlatformIO example:

  pio run -e <environment>

- Arduino CLI example:

  arduino-cli compile --fqbn <board> firmware

4) Flash to device

- PlatformIO: pio run -t upload -e <environment>
- Arduino CLI: arduino-cli upload -p /dev/ttyUSB0 --fqbn <board> firmware

5) Monitor serial output

- PlatformIO: pio device monitor
- minicom / screen / picocom

Notes

- Add specific environment names and board IDs used by your project in the
  firmware folder and the README so contributors can build quickly.
