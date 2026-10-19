# Chroma Link IoT

Chroma Link IoT is a firmware + hardware project that links RGB lighting to IoT-enabled controls. This repository contains firmware, documentation, and configuration to build, test, and extend the Chroma Link device.

## Live demo video

https://github.com/user-attachments/assets/f3f0dfc5-99c8-4c83-9238-d70c4f7115d7

A walkthrough of the RGB modes, MQTT-to-UART control path, timing, and cloud logging, including footage of the original hardware build.

[Download video](docs/media/chroma-motion.mp4) · [HTML presentation source](docs/media/chroma-motion.html)

> NOTE: This README was added to provide a clear project overview. Please update the hardware and firmware details below (MCU model, LED driver IC, wiring diagram, etc.) so the documentation fully matches your implementation.

## Highlights

- Firmware source for the Chroma Link IoT device
- Docs to get started, architecture notes, and contribution guidelines
- Issue and PR templates to help collaboration

## Repository layout

- `firmware/` — firmware source code and build files
- `docs/` — design notes, getting started, and architecture docs
- `README.md` — project overview (this file)
- `CHANGELOG.md` — release notes and history

## Quick start

1. Clone the repository:

   git clone https://github.com/fizaamjad897/Chroma-Link-IoT.git
   cd Chroma-Link-IoT

2. Read docs/GETTING_STARTED.md for platform-specific setup and build instructions.

## What you should add (TODOs)
- Hardware schematic and BOM (add under `docs/` or attach images)
- Wiring diagram and photos of a working device
- Exact MCU/board used (ESP32/STM32/Arduino etc.) and toolchain steps
- Any binary releases (attach in Releases) and changelog entries

## Contributing

See CONTRIBUTING.md for contribution guidelines and the code of conduct.

## License

This project is licensed under the MIT License — see the LICENSE file for details.
