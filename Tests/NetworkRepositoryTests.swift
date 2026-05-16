import XCTest
@testable import WiFiMapperCore

final class NetworkRepositoryTests: XCTestCase {
    func testUpsertAndAnalyticsPersistObservationsInMemory() async throws {
        let persistence = PersistenceController(inMemory: true)
        let repository = NetworkRepository(persistence: persistence)
        let sessionID = try await repository.startSession()

        let first = WiFiNetworkSnapshot(
            id: UUID(),
            ssid: "TestNet",
            bssid: "AA:BB:CC:DD:EE:01",
            latitude: 51.5000,
            longitude: -0.1200,
            timestamp: Date().addingTimeInterval(-600),
            rssi: -55,
            frequencyMHz: 5200,
            channel: 40,
            band: .band5,
            security: .wpa2,
            encryption: "WPA2",
            encoding: "UTF-8",
            captivePortalHint: nil,
            authenticationHint: nil,
            scanCount: 1,
            lastSeen: Date().addingTimeInterval(-600),
            history: []
        )

        let second = WiFiNetworkSnapshot(
            id: first.id,
            ssid: "TestNet",
            bssid: "AA:BB:CC:DD:EE:01",
            latitude: 51.5003,
            longitude: -0.1203,
            timestamp: Date(),
            rssi: -49,
            frequencyMHz: 5200,
            channel: 40,
            band: .band5,
            security: .wpa2,
            encryption: "WPA2",
            encoding: "UTF-8",
            captivePortalHint: nil,
            authenticationHint: nil,
            scanCount: 1,
            lastSeen: Date(),
            history: []
        )

        _ = try await repository.upsert(snapshot: first, sessionID: sessionID)
        _ = try await repository.upsert(snapshot: second, sessionID: sessionID)

        let networks = try await repository.fetchNetworks()
        let summary = try await repository.analyticsSummary()

        XCTAssertEqual(networks.count, 1)
        XCTAssertEqual(networks.first?.scanCount, 2)
        XCTAssertEqual(networks.first?.history.count, 2)
        XCTAssertEqual(summary.totalNetworks, 1)
        XCTAssertEqual(summary.totalObservations, 2)
        XCTAssertEqual(summary.strongestSSID, "TestNet")
    }
}
