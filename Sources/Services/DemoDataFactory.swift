import CoreLocation
import Foundation

public enum DemoDataFactory {
    public static func makeSnapshots(around center: CLLocationCoordinate2D) -> [WiFiNetworkSnapshot] {
        let baseDate = Date()
        let templates: [(String, String, WiFiBand, WiFiSecurity, Int, Int?, Int?)] = [
            ("Cafe North", "10:22:33:44:55:01", .band24, .wpa2, -58, 2412, 1),
            ("Lobby Mesh", "10:22:33:44:55:02", .band5, .wpa3, -46, 5200, 40),
            ("Studio Guest", "10:22:33:44:55:03", .band5, .open, -71, 5500, 100),
            ("Office Core", "10:22:33:44:55:04", .band6, .wpa3, -52, 6115, 5),
            ("Atrium Secure", "10:22:33:44:55:05", .band24, .wpa2, -67, 2437, 6),
            ("Warehouse Link", "10:22:33:44:55:06", .band5, .wpa2, -74, 5745, 149),
            ("Open Plaza", "10:22:33:44:55:07", .band24, .open, -63, 2462, 11),
            ("Meeting Room", "10:22:33:44:55:08", .band6, .wpa3, -49, 6175, 17)
        ]

        return templates.enumerated().map { index, item in
            let latitudeOffset = (Double(index % 4) - 1.5) * 0.00045
            let longitudeOffset = (Double(index / 4) - 0.5) * 0.00055
            let coordinate = CLLocationCoordinate2D(
                latitude: center.latitude + latitudeOffset,
                longitude: center.longitude + longitudeOffset
            )
            let history = makeHistory(
                networkID: UUID(),
                center: coordinate,
                baseRSSI: item.4,
                baseDate: baseDate.addingTimeInterval(Double(-index) * 1_800)
            )
            let latest = history.last
            return WiFiNetworkSnapshot(
                id: history.first?.networkID ?? UUID(),
                ssid: item.0,
                bssid: item.1,
                latitude: latest?.latitude ?? coordinate.latitude,
                longitude: latest?.longitude ?? coordinate.longitude,
                timestamp: latest?.timestamp ?? baseDate,
                rssi: latest?.rssi ?? item.4,
                frequencyMHz: item.5,
                channel: item.6,
                band: item.2,
                security: item.3,
                encryption: item.3 == .open ? "Open" : item.3.rawValue,
                encoding: "UTF-8",
                captivePortalHint: item.3 == .open ? "Potential landing page" : nil,
                authenticationHint: item.3 == .wpa3 ? "SAE likely" : nil,
                scanCount: history.count,
                lastSeen: latest?.timestamp ?? baseDate,
                history: history
            )
        }
    }

    private static func makeHistory(networkID: UUID, center: CLLocationCoordinate2D, baseRSSI: Int, baseDate: Date) -> [WiFiObservation] {
        (0 ..< 6).map { index in
            let drift = Double(index - 2) * 0.00008
            return WiFiObservation(
                id: UUID(),
                networkID: networkID,
                timestamp: baseDate.addingTimeInterval(Double(index) * 5_400),
                latitude: center.latitude + drift,
                longitude: center.longitude - drift,
                rssi: baseRSSI + (index % 3) - 1,
                sessionID: nil
            )
        }
    }
}
