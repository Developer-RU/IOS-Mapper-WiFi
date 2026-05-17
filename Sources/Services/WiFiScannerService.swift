
import Combine
import CoreLocation
import Foundation
import NetworkExtension
import UIKit
import WiFiMapperCore
@MainActor
final class WiFiScannerService: ObservableObject {
    @Published private(set) var liveNetworks: [WiFiNetworkSnapshot] = []
    @Published private(set) var sessionState = ScanSessionState()
    @Published private(set) var settings: ScannerSettings
    @Published private(set) var lastScanDate: Date?

    private let repository: NetworkRepository
    private let locationService: LocationService
    private let externalScannerService: ExternalScannerService
    private let settingsKey = "scanner.settings"
    private var scanTask: Task<Void, Never>?
    private var externalStatusTask: Task<Void, Never>?
    private var demoDataSeeded = false
    private var isRefreshingHistory = false

    init(repository: NetworkRepository, locationService: LocationService, externalScannerService: ExternalScannerService) {
        self.repository = repository
        self.locationService = locationService
        self.externalScannerService = externalScannerService
        self.settings = Self.loadSettings()
        configureExternalStatusTracking(for: self.settings.inputSource)
    }

    func updateSettings(_ update: (inout ScannerSettings) -> Void) {
        let previousInputSource = settings.inputSource
        var draft = settings
        update(&draft)
        settings = draft
        saveSettings()

        if previousInputSource != draft.inputSource {
            configureExternalStatusTracking(for: draft.inputSource)
        }
    }

    deinit {
        externalStatusTask?.cancel()
    }

    func startScanning() {
        guard !sessionState.isScanning else { return }

        sessionState.isScanning = true
        sessionState.startedAt = Date()
        sessionState.lastErrorMessage = nil
        UIApplication.shared.isIdleTimerDisabled = true
        locationService.start(highAccuracy: settings.highAccuracyGPS)

        scanTask = Task {
            do {
                if settings.inputSource == .externalScanner {
                    let connected = await externalScannerService.connectAndProbe(using: settings.externalScanner)
                    guard connected else {
                        throw NSError(
                            domain: "ExternalScannerService",
                            code: 1,
                            userInfo: [NSLocalizedDescriptionKey: externalScannerService.status.lastErrorMessage ?? AppStrings.localized("external.scanner.error.unreachable")]
                        )
                    }
                    try await externalScannerService.configureRemoteScanner(using: settings)
                }

                let sessionID = try await repository.startSession()
                await MainActor.run {
                    sessionState.sessionID = sessionID
                }
                await scanLoop(sessionID: sessionID)
            } catch {
                await MainActor.run {
                    sessionState.isScanning = false
                    sessionState.lastErrorMessage = error.localizedDescription
                    UIApplication.shared.isIdleTimerDisabled = false
                }
            }
        }
    }

    func stopScanning() {
        scanTask?.cancel()
        scanTask = nil
        locationService.stop()
        UIApplication.shared.isIdleTimerDisabled = false

        if settings.inputSource == .externalScanner {
            Task {
                await externalScannerService.stopScan(using: settings.externalScanner)
            }
        }

        if let sessionID = sessionState.sessionID {
            Task {
                try? await repository.stopSession(sessionID)
            }
        }

        sessionState.isScanning = false
        sessionState.sessionID = nil
    }

    func refreshHistory() async {
        guard !isRefreshingHistory else { return }
        isRefreshingHistory = true
        defer { isRefreshingHistory = false }

        do {
            if settings.demoModeEnabled, !demoDataSeeded {
                await seedDemoDataset()
            }
            liveNetworks = try await repository.fetchNetworks()
            sessionState.uniqueNetworks = liveNetworks.count
            sessionState.totalObservations = liveNetworks.reduce(into: 0) { $0 += $1.history.count }
        } catch {
            sessionState.lastErrorMessage = error.localizedDescription
        }
    }

    func seedDemoDataset() async {
        guard !demoDataSeeded else { return }

        let center = locationService.currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let sessionID = sessionState.sessionID
        let snapshots = DemoDataFactory.makeSnapshots(around: center)

        for snapshot in snapshots {
            _ = try? await repository.upsert(snapshot: snapshot, sessionID: sessionID)
        }

        demoDataSeeded = true
        lastScanDate = snapshots.map(\.lastSeen).max()
        do {
            liveNetworks = try await repository.fetchNetworks()
            sessionState.uniqueNetworks = liveNetworks.count
            sessionState.totalObservations = liveNetworks.reduce(into: 0) { $0 += $1.history.count }
        } catch {
            sessionState.lastErrorMessage = error.localizedDescription
        }
    }

    func performBackgroundRefresh() async {
        _ = try? await captureCurrentNetwork(sessionID: sessionState.sessionID)
        await refreshHistory()
    }

    func testExternalScannerConnection() async {
        guard settings.inputSource == .externalScanner else { return }
        _ = await externalScannerService.connectAndProbe(using: settings.externalScanner)
    }

    private func scanLoop(sessionID: UUID) async {
        while !Task.isCancelled {
            _ = try? await captureCurrentNetwork(sessionID: sessionID)
            await refreshHistory()
            let delay = UInt64(settings.mode.interval * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delay)
        }
    }

    private func captureCurrentNetwork(sessionID: UUID?) async throws -> WiFiNetworkSnapshot? {
        if settings.demoModeEnabled {
            if !demoDataSeeded {
                await seedDemoDataset()
            } else {
                lastScanDate = Date()
            }
            return liveNetworks.first
        }

        if settings.inputSource == .externalScanner {
            return try await captureExternalNetworks(sessionID: sessionID)
        }

#if targetEnvironment(simulator)
        sessionState.lastErrorMessage = AppStrings.localized("scan.simulatorUnsupported")
        return nil
#endif

        guard let location = locationService.currentLocation?.coordinate else {
            sessionState.lastErrorMessage = AppStrings.localized("scan.waitingForLocation")
            return nil
        }

        guard let hotspot = await fetchCurrentNetwork(timeout: 2.5) else {
            sessionState.lastErrorMessage = AppStrings.localized("scan.connectToWifi")
            return nil
        }

        let rssi = max(-95, Int((hotspot.signalStrength * 60) - 100))
        guard !settings.ignoreWeakNetworks || rssi >= settings.signalThreshold else {
            return nil
        }

        var snapshot = WiFiNetworkSnapshot(
            id: UUID(),
            ssid: hotspot.ssid,
            bssid: hotspot.bssid,
            latitude: location.latitude,
            longitude: location.longitude,
            timestamp: Date(),
            rssi: rssi,
            frequencyMHz: nil,
            channel: nil,
            band: .unknown,
            security: hotspot.isSecure ? .secure : .open,
            encryption: hotspot.isSecure ? "Secure (public API limited)" : "Open",
            encoding: nil,
            captivePortalHint: nil,
            authenticationHint: nil,
            scanCount: 1,
            lastSeen: Date(),
            history: []
        )

        snapshot = try await repository.upsert(snapshot: snapshot, sessionID: sessionID)
        lastScanDate = snapshot.lastSeen
        sessionState.lastErrorMessage = nil
        return snapshot
    }

    private func captureExternalNetworks(sessionID: UUID?) async throws -> WiFiNetworkSnapshot? {
        do {
            try await externalScannerService.startScan(using: settings.externalScanner)
            let result = try await externalScannerService.pollResults(using: settings.externalScanner)

            let fallbackCoordinate = locationService.currentLocation?.coordinate
            var inserted: [WiFiNetworkSnapshot] = []

            for network in result.networks {
                let latitude = network.latitude ?? fallbackCoordinate?.latitude
                let longitude = network.longitude ?? fallbackCoordinate?.longitude
                guard let latitude, let longitude else { continue }

                guard !settings.ignoreWeakNetworks || network.rssi >= settings.signalThreshold else { continue }

                var snapshot = WiFiNetworkSnapshot(
                    id: UUID(),
                    ssid: network.ssid,
                    bssid: network.bssid,
                    latitude: latitude,
                    longitude: longitude,
                    timestamp: Date(),
                    rssi: max(-100, min(-20, network.rssi)),
                    frequencyMHz: network.frequencyMHz,
                    channel: network.channel,
                    band: band(for: network.frequencyMHz),
                    security: securityType(from: network.security),
                    encryption: network.encryption,
                    encoding: nil,
                    captivePortalHint: nil,
                    authenticationHint: "External scanner \(result.deviceID)",
                    scanCount: 1,
                    lastSeen: Date(),
                    history: []
                )

                snapshot = try await repository.upsert(snapshot: snapshot, sessionID: sessionID)
                inserted.append(snapshot)
            }

            lastScanDate = Date()
            if inserted.isEmpty {
                sessionState.lastErrorMessage = AppStrings.localized("external.scanner.error.noResults")
            } else {
                sessionState.lastErrorMessage = nil
            }
            return inserted.first
        } catch {
            sessionState.lastErrorMessage = error.localizedDescription
            return nil
        }
    }

    private func band(for frequencyMHz: Int?) -> WiFiBand {
        guard let frequencyMHz else { return .unknown }
        switch frequencyMHz {
        case 2_400 ... 2_500:
            return .band24
        case 4_900 ... 5_900:
            return .band5
        case 5_925 ... 7_125:
            return .band6
        default:
            return .unknown
        }
    }

    private func securityType(from value: String?) -> WiFiSecurity {
        guard let value else { return .unknown }
        let normalized = value.lowercased()
        if normalized.contains("wpa3") { return .wpa3 }
        if normalized.contains("wpa2") { return .wpa2 }
        if normalized.contains("wpa") { return .wpa }
        if normalized.contains("open") { return .open }
        if normalized.contains("secure") { return .secure }
        return .unknown
    }

    private func fetchCurrentNetwork(timeout: TimeInterval) async -> NEHotspotNetwork? {
        await withTaskGroup(of: NEHotspotNetwork?.self) { group in
            group.addTask {
                await withCheckedContinuation { continuation in
                    NEHotspotNetwork.fetchCurrent { network in
                        continuation.resume(returning: network)
                    }
                }
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return nil
            }

            let result = await group.next() ?? nil
            group.cancelAll()
            return result
        }
    }

    private func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: settingsKey)
    }

    private func configureExternalStatusTracking(for inputSource: ScannerInputSource) {
        externalStatusTask?.cancel()
        externalStatusTask = nil

        guard inputSource == .externalScanner else {
            externalScannerService.resetStatus()
            return
        }

        externalStatusTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                if !self.sessionState.isScanning {
                    _ = await self.externalScannerService.connectAndProbe(using: self.settings.externalScanner)
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }

    private static func loadSettings() -> ScannerSettings {
        guard let data = UserDefaults.standard.data(forKey: "scanner.settings"),
              var settings = try? JSONDecoder().decode(ScannerSettings.self, from: data) else {
            return ScannerSettings()
        }

        // Migrate legacy default AP password to match ESP32 firmware default.
        if settings.externalScanner.ssid == "WIFI-MAPPER-SCANNER",
           settings.externalScanner.host == "192.168.4.1",
           settings.externalScanner.password == "wifimapper123" {
            settings.externalScanner.password = "12345678"
            if let migratedData = try? JSONEncoder().encode(settings) {
                UserDefaults.standard.set(migratedData, forKey: "scanner.settings")
            }
        }

        return settings
    }
}
