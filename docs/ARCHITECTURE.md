# Architecture

This document explains the high level structure of the Chroma Link IoT project.

Repository structure

- `firmware/` — firmware source and build files. Subfolders may contain separate modules, e.g. `firmware/src`, `firmware/lib`.
- `docs/` — documentation, diagrams and design notes.
- `hardware/` (suggested) — schematics, PCB files, BOM. Add this directory if you have hardware design files.

Core components

- Hardware layer: LED drivers, MCU, power management
- Firmware layer: device initialization, LED control logic, network connectivity (Wi-Fi / BLE / MQTT), OTA updates
- Cloud / integration (optional): APIs, dashboards, or integrations with home automation platforms

Extension points

- Add drivers for new LED controllers
- Add supported board configurations/environments for PlatformIO or other build systems

