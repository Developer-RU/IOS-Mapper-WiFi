
import Foundation
import WiFiMapperCore
final class ExportService {
    enum ExportFormat: String, CaseIterable, Identifiable {
        case csv = "CSV"
        case json = "JSON"
        case sqlite = "SQLite Backup"

        var id: String { rawValue }
        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            case .sqlite: return "sqlite"
            }
        }
    }

    private let repository: NetworkRepository
    private let persistence: PersistenceController

    init(repository: NetworkRepository, persistence: PersistenceController) {
        self.repository = repository
        self.persistence = persistence
    }

    func export(format: ExportFormat) async throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("WiFiMapperExports", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let filename = "wifi-mapper-\(Int(Date().timeIntervalSince1970)).\(format.fileExtension)"
        let url = folder.appendingPathComponent(filename)

        switch format {
        case .csv:
            let rows = try await repository.fetchNetworks().flatMap { network in
                network.history.map { observation in
                    [
                        network.ssid,
                        network.bssid,
                        String(observation.latitude),
                        String(observation.longitude),
                        ISO8601DateFormatter().string(from: observation.timestamp),
                        String(observation.rssi),
                        network.frequencyMHz.map(String.init) ?? "",
                        network.channel.map(String.init) ?? "",
                        network.band.rawValue,
                        network.security.rawValue,
                        network.captivePortalHint ?? "",
                        network.scanCount.description,
                        ISO8601DateFormatter().string(from: network.lastSeen)
                    ].joined(separator: ",")
                }
            }
            let header = "SSID,BSSID,Latitude,Longitude,Timestamp,RSSI,Frequency,Channel,Band,Security,CaptivePortal,ScanCount,LastSeen"
            try ([header] + rows).joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        case .json:
            let payload = try await repository.fetchNetworks()
            let data = try JSONEncoder.pretty.encode(payload)
            try data.write(to: url)
        case .sqlite:
            guard let storeURL = persistence.storeURL else {
                throw CocoaError(.fileNoSuchFile)
            }
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            try FileManager.default.copyItem(at: storeURL, to: url)
        }

        return url
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
