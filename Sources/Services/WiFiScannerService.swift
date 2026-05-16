
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
    private let settingsKey = "scanner.settings"
    private var scanTask: Task<Void, Never>?
    private var demoDataSeeded = false
    private var isRefreshingHistory = false

    init(repository: NetworkRepository, locationService: LocationService) {
        self.repository = repository
        self.locationService = locationService
        self.settings = Self.loadSettings()
    }

    func updateSettings(_ update: (inout ScannerSettings) -> Void) {
        var draft = settings
        update(&draft)
        settings = draft
        saveSettings()
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

        guard let location = locationService.currentLocation?.coordinate else {
            sessionState.lastErrorMessage = "Waiting for location fix before scanning."
            return nil
        }

        guard let hotspot = await fetchCurrentNetwork(timeout: 2.5) else {
            sessionState.lastErrorMessage = String(localized: "dashboard.platformNote.body")
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
        return snapshot
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

    private static func loadSettings() -> ScannerSettings {
        guard let data = UserDefaults.standard.data(forKey: "scanner.settings"),
              let settings = try? JSONDecoder().decode(ScannerSettings.self, from: data) else {
            return ScannerSettings()
        }
        return settings
    }
}
