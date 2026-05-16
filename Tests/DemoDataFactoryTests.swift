import CoreLocation
import XCTest
@testable import WiFiMapperCore

final class DemoDataFactoryTests: XCTestCase {
    func testDemoSnapshotsContainExpectedVolumeAndHistory() {
        let center = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)

        let snapshots = DemoDataFactory.makeSnapshots(around: center)

        XCTAssertEqual(snapshots.count, 8)
        XCTAssertTrue(snapshots.allSatisfy { !$0.ssid.isEmpty })
        XCTAssertTrue(snapshots.allSatisfy { !$0.bssid.isEmpty })
        XCTAssertTrue(snapshots.allSatisfy { $0.history.count == 6 })
        XCTAssertTrue(snapshots.contains { $0.security == .open })
        XCTAssertTrue(snapshots.contains { $0.band == .band6 })
    }
}
