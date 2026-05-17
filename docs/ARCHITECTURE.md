# IOS-Mapper WiFi Architecture

## Overview

IOS-Mapper WiFi follows an offline-first layered architecture:

1. UI Layer (`Views`)
2. Presentation Layer (`ViewModels`)
3. Service Layer (`Services`)
4. Persistence Layer (`Persistence`)
5. Domain Models (`Models`)

## Core Components

### AppModel

`AppModel` wires global dependencies and shared application state:
- `NetworkRepository`
- `LocationService`
- `PermissionService`
- `ExternalScannerService`
- `WiFiScannerService`

### WiFiScannerService

Coordinates scan sessions and routes incoming observations to persistence.

Responsibilities:
- Start/stop scan sessions.
- Manage scanner mode (iPhone or external scanner).
- Trigger history refresh and maintain session state.
- Track external scanner status polling in external mode.

### ExternalScannerService

Implements scanner HTTP client behavior:
- `connectAndProbe`
- `configureRemoteScanner`
- `startScan`
- `stopScan`
- `pollResults`

Also exposes a status snapshot consumed by UI banners and settings screens.

### Persistence Layer

`NetworkRepository` encapsulates Core Data operations and query patterns for:
- upsert snapshots
- historical fetches
- area comparison
- analytics-ready datasets

## Data Flow

1. User starts scan from dashboard.
2. Service captures iPhone or external scanner data.
3. Observations are normalized into `WiFiNetworkSnapshot`.
4. Repository writes to Core Data.
5. View models subscribe and update UI.

## Localization

All user-facing text should be stored in `Resources/*/Localizable.strings` and accessed through `AppStrings.localized(...)`.

## Related Project

Companion firmware: [ESP32-Mapper WiFi](../../WIFI-MAPPER)
