# WiFi Mapper

WiFi Mapper is an offline iPhone app for local Wi-Fi observation logging, route-aware mapping, heatmap visualization, historical browsing, and export. The project uses SwiftUI, MVVM, Core Data, MapKit, CoreLocation, Combine, BackgroundTasks, and Charts.

## Current capability model

This project uses only public Apple APIs.

That means:
- The app can persist GPS-tagged observations of the currently associated Wi-Fi network.
- The app can maintain local history, map overlays, analytics, exports, and background refresh around location updates.
- The app cannot passively enumerate all nearby Wi-Fi networks on stock iOS without private entitlements or specialized enterprise infrastructure.

The UI and architecture are prepared for a richer scanner provider, but the default implementation remains production-safe and App Store-compatible.

## Included product features

- Live dashboard with session stats and area comparison summary
- Full-screen map with point, route, heatmap, and congestion layers
- Historical comparison tab with adjustable radius and time window
- Local database browser with search, sort, delete, and export
- Demo mode with generated offline sample observations for UI testing
- Analytics for bands, security mix, channels, and observation trend

## Project setup

1. Install Xcode 26+ and XcodeGen.
2. Run `xcodegen generate` in the project root.
3. Open `WiFiMapper.xcodeproj`.
4. Set your Apple Development Team in Signing & Capabilities.
5. Build for a physical iPhone to validate location and associated-network behavior.

## Required permissions

The app requests:
- When In Use location
- Always location
- Local network access
- Background location runtime behavior via Info.plist background modes

## Physical iPhone checklist

1. Use a real iPhone, not only Simulator.
2. In Signing & Capabilities, set a valid Team and unique bundle identifier if needed.
3. In iOS Settings, allow Always location access.
4. Enable Precise Location for best route/heatmap quality.
5. Join a Wi-Fi network before starting a scan session.
6. Lock the screen and background the app to test location/background refresh behavior.
7. Export CSV, JSON, and SQLite backup from the Database tab to verify local persistence.

## Architecture overview

- `Sources/App`: app composition and service wiring
- `Sources/Models`: domain models, filter definitions, comparison/analytics types
- `Sources/Persistence`: Core Data stack and repository queries
- `Sources/Services`: location, scanning, permissions, export, background refresh
- `Sources/ViewModels`: MVVM presentation logic
- `Sources/Views`: SwiftUI screens and map overlay components

## Notes on background behavior

Background location updates are enabled where iOS allows them. BackgroundTasks are scheduled for refresh-oriented work, but iOS still controls actual execution timing. Continuous full-spectrum Wi-Fi scanning in the background is not possible through public APIs.

## Local-only storage

All data stays on-device.
- No cloud sync
- No external server dependency
- No remote database
- Export is user-initiated and file-based only
