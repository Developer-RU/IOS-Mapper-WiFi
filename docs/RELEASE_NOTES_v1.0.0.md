# IOS-Mapper WiFi Release Notes v1.0.0

Release date: 2026-05-17

## Highlights

- Project branding updated to **IOS-Mapper WiFi**.
- External scanner flow improved for command-driven operation.
- Manual AP connection model enforced for iOS.
- Scanner status UX improved with richer state detail.
- Localization coverage expanded for scanner status and settings blocks.
- Documentation introduced for architecture and scanner integration.

## Main Changes

- Added external scanner integration service and status model alignment.
- Added real-time scanner status updates in UI banner.
- Added scanner information block in settings.
- Removed automatic AP join behavior from the app.
- Added full project documentation in `docs/`.

## Compatibility

- iOS 18+
- External scanner companion: ESP32-Mapper WiFi

## Upgrade Notes

- Rebuild the app after pulling latest `main`.
- Ensure scanner firmware is updated to the latest companion release.
