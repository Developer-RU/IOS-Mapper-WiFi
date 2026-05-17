# External Scanner Integration Guide

## Purpose

This document explains how IOS-Mapper WiFi integrates with the companion ESP32 scanner firmware.

## Companion Firmware

- [ESP32-Mapper WiFi](https://github.com/Developer-RU/ESP32-Mapper-WiFi)

## Expected Scanner Defaults

- Host: `192.168.4.1`
- Port: `80`

## Connection Model

1. User manually connects iPhone to scanner AP in iOS Wi-Fi settings.
2. App checks scanner availability with `GET /status`.
3. App configures scan parameters.
4. App sends explicit start/stop commands.
5. App polls result payloads until scan completes.

## Endpoints

- `GET /status`
- `POST /configure`
- `POST /scan/start`
- `POST /scan/stop`
- `GET /scan/results`

## Error Handling

Common failure states:
- Host unreachable
- Invalid endpoint
- Invalid JSON response
- HTTP non-2xx
- Scan timeout

The app maps these failures into user-facing status and banner messages.

## Notes

- Auto-join is not used.
- Device info (serial, firmware, network types) resets when scanner is unavailable.
