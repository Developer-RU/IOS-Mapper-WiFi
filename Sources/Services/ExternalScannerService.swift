import Foundation
import NetworkExtension
import WiFiMapperCore

@MainActor
final class ExternalScannerService: ObservableObject {
    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case scanning
        case failed
    }

    struct StatusSnapshot: Equatable {
        var state: ConnectionState = .disconnected
        var deviceID = "-"
        var firmware = "-"
        var scanNetworkTypes = "-"
        var lastSeen: Date?
        var lastResultCount = 0
        var inProgress = false
        var lastCommand = "none"
        var lastErrorMessage: String?
    }

    struct ScanResult {
        let networks: [ExternalNetwork]
        let deviceID: String
        let firmware: String
    }

    struct ExternalNetwork {
        let ssid: String
        let bssid: String
        let rssi: Int
        let channel: Int?
        let frequencyMHz: Int?
        let security: String?
        let encryption: String?
        let latitude: Double?
        let longitude: Double?
    }

    @Published private(set) var status = StatusSnapshot()

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let legacyScannerSSIDs = ["WIFI-MAPPER-SCANNER", "WIFI-SCANNER"]

    init() {
        removeLegacyAutoJoinProfiles()
    }

    func resetStatus() {
        status = StatusSnapshot()
    }

    func removeLegacyAutoJoinProfiles() {
        for ssid in legacyScannerSSIDs {
            NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
        }
    }

    func connectAndProbe(using settings: ExternalScannerSettings) async -> Bool {
        status.state = .connecting
        status.lastErrorMessage = nil

        do {
            let response: StatusResponse = try await request(
                host: settings.host,
                port: settings.port,
                path: "/status",
                method: "GET",
                timeout: 6
            )

            status.state = response.inProgress ? .scanning : .connected
            status.deviceID = response.deviceID
            status.firmware = response.firmware
            status.scanNetworkTypes = response.scanNetworkTypes
            status.inProgress = response.inProgress
            status.lastCommand = response.lastCommand
            status.lastSeen = Date()
            status.lastErrorMessage = nil
            return true
        } catch {
            status.state = .failed
            status.deviceID = "-"
            status.firmware = "-"
            status.scanNetworkTypes = "-"
            status.inProgress = false
            status.lastErrorMessage = error.localizedDescription
            return false
        }
    }

    func configureRemoteScanner(using appSettings: ScannerSettings) async throws {
        let settings = appSettings.externalScanner
        let payload = ConfigureRequest(
            intervalMs: max(1000, Int(appSettings.mode.interval * 1000)),
            minRSSI: appSettings.signalThreshold,
            maxResults: max(10, settings.maxResults)
        )

        _ = try await request(
            host: settings.host,
            port: settings.port,
            path: "/configure",
            method: "POST",
            body: payload,
            timeout: 6
        ) as ConfigureResponse
    }

    func startScan(using settings: ExternalScannerSettings) async throws {
        let response: ScanStartResponse = try await request(
            host: settings.host,
            port: settings.port,
            path: "/scan/start",
            method: "POST",
            body: EmptyBody(),
            timeout: 6
        )

        status.inProgress = response.inProgress
        status.lastCommand = response.lastCommand
        status.state = response.inProgress ? .scanning : .connected
        status.lastSeen = Date()
        status.lastErrorMessage = nil
    }

    func stopScan(using settings: ExternalScannerSettings) async {
        let response: ScanStopResponse? = try? await request(
            host: settings.host,
            port: settings.port,
            path: "/scan/stop",
            method: "POST",
            body: EmptyBody(),
            timeout: 4
        )

        status.inProgress = response?.inProgress ?? false
        status.lastCommand = response?.lastCommand ?? "stop"
        status.lastSeen = Date()

        if response == nil {
            status.state = .failed
            status.deviceID = "-"
            status.firmware = "-"
            status.scanNetworkTypes = "-"
            status.lastErrorMessage = AppStrings.localized("external.scanner.error.unreachable")
            return
        }

        status.state = .connected
        status.lastErrorMessage = nil
    }

    func pollResults(using settings: ExternalScannerSettings) async throws -> ScanResult {
        let started = Date()
        while Date().timeIntervalSince(started) < settings.scanTimeoutSeconds {
            let response: ScanResultsResponse = try await request(
                host: settings.host,
                port: settings.port,
                path: "/scan/results",
                method: "GET",
                timeout: 6
            )

            if response.inProgress {
                status.inProgress = true
                status.lastCommand = response.lastCommand
                status.state = .scanning
                status.lastSeen = Date()
                try? await Task.sleep(nanoseconds: 450_000_000)
                continue
            }

            status.state = .connected
            status.deviceID = response.deviceID
            status.firmware = response.firmware
            status.scanNetworkTypes = response.scanNetworkTypes
            status.inProgress = false
            status.lastCommand = response.lastCommand
            status.lastSeen = Date()
            status.lastResultCount = response.networks.count
            status.lastErrorMessage = nil

            return ScanResult(
                networks: response.networks.map {
                    ExternalNetwork(
                        ssid: $0.ssid,
                        bssid: $0.bssid,
                        rssi: $0.rssi,
                        channel: $0.channel,
                        frequencyMHz: $0.frequencyMHz,
                        security: $0.security,
                        encryption: $0.encryption,
                        latitude: $0.latitude,
                        longitude: $0.longitude
                    )
                },
                deviceID: response.deviceID,
                firmware: response.firmware
            )
        }

        status.state = .failed
        status.deviceID = "-"
        status.firmware = "-"
        status.scanNetworkTypes = "-"
        status.inProgress = false
        status.lastErrorMessage = AppStrings.localized("external.scanner.timeout")
        throw ExternalScannerError.timeout
    }

    private func request<Response: Decodable, Body: Encodable>(
        host: String,
        port: Int,
        path: String,
        method: String,
        body: Body?,
        timeout: TimeInterval
    ) async throws -> Response {
        guard var components = URLComponents(string: "http://\(host):\(port)\(path)") else {
            throw ExternalScannerError.invalidEndpoint
        }

        // Ensure URLComponents keeps IPv4 hosts untouched.
        components.percentEncodedHost = host

        guard let url = components.url else {
            throw ExternalScannerError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeout

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExternalScannerError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw ExternalScannerError.httpError(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw ExternalScannerError.invalidResponse
        }
    }

    private func request<Response: Decodable>(
        host: String,
        port: Int,
        path: String,
        method: String,
        timeout: TimeInterval
    ) async throws -> Response {
        try await request(host: host, port: port, path: path, method: method, body: Optional<EmptyBody>.none, timeout: timeout)
    }
}

enum ExternalScannerError: LocalizedError {
    case invalidEndpoint
    case invalidResponse
    case timeout
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return AppStrings.localized("external.scanner.error.invalidEndpoint")
        case .invalidResponse:
            return AppStrings.localized("external.scanner.error.invalidResponse")
        case .timeout:
            return AppStrings.localized("external.scanner.timeout")
        case let .httpError(code):
            return AppStrings.localized("external.scanner.error.http %lld", Int64(code))
        }
    }
}

private struct EmptyBody: Encodable {}

private struct StatusResponse: Decodable {
    let deviceID: String
    let firmware: String
    let scanNetworkTypes: String
    let inProgress: Bool
    let lastCommand: String

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case firmware
        case scanNetworkTypes = "scan_network_types"
        case inProgress = "in_progress"
        case lastCommand = "last_command"
    }
}

private struct ConfigureRequest: Encodable {
    let intervalMs: Int
    let minRSSI: Int
    let maxResults: Int

    enum CodingKeys: String, CodingKey {
        case intervalMs = "interval_ms"
        case minRSSI = "min_rssi"
        case maxResults = "max_results"
    }
}

private struct ConfigureResponse: Decodable {
    let ok: Bool
}

private struct ScanStartResponse: Decodable {
    let ok: Bool
    let inProgress: Bool
    let lastCommand: String

    enum CodingKeys: String, CodingKey {
        case ok
        case inProgress = "in_progress"
        case lastCommand = "last_command"
    }
}

private struct ScanStopResponse: Decodable {
    let ok: Bool
    let inProgress: Bool
    let lastCommand: String

    enum CodingKeys: String, CodingKey {
        case ok
        case inProgress = "in_progress"
        case lastCommand = "last_command"
    }
}

private struct ScanResultsResponse: Decodable {
    struct Network: Decodable {
        let ssid: String
        let bssid: String
        let rssi: Int
        let channel: Int?
        let frequencyMHz: Int?
        let security: String?
        let encryption: String?
        let latitude: Double?
        let longitude: Double?

        enum CodingKeys: String, CodingKey {
            case ssid
            case bssid
            case rssi
            case channel
            case frequencyMHz = "frequency_mhz"
            case security
            case encryption
            case latitude
            case longitude
        }
    }

    let inProgress: Bool
    let deviceID: String
    let firmware: String
    let scanNetworkTypes: String
    let lastCommand: String
    let networks: [Network]

    enum CodingKeys: String, CodingKey {
        case inProgress = "in_progress"
        case deviceID = "device_id"
        case firmware
        case scanNetworkTypes = "scan_network_types"
        case lastCommand = "last_command"
        case networks
    }
}
