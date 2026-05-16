import Foundation
import CoreLocation

public enum WiFiBand: String, CaseIterable, Codable, Identifiable {
    case band24 = "2.4 GHz"
    case band5 = "5 GHz"
    case band6 = "6 GHz"
    case unknown = "Unknown"

    public var id: String { rawValue }

    public var colorHex: String {
        switch self {
        case .band24: return "#4DA3FF"
        case .band5: return "#5ED0A5"
        case .band6: return "#FFC96B"
        case .unknown: return "#B7BCC8"
        }
    }
}

public enum WiFiSecurity: String, CaseIterable, Codable, Identifiable {
    case open = "Open"
    case wpa = "WPA"
    case wpa2 = "WPA2"
    case wpa3 = "WPA3"
    case secure = "Secure"
    case unknown = "Unknown"

    public var id: String { rawValue }
}

public enum ScannerMode: String, CaseIterable, Codable, Identifiable {
    case continuous = "Continuous"
    case every5Seconds = "Every 5 sec"
    case every10Seconds = "Every 10 sec"
    case every30Seconds = "Every 30 sec"
    case everyMinute = "Every 1 min"

    public var id: String { rawValue }

    public var interval: TimeInterval {
        switch self {
        case .continuous: return 2
        case .every5Seconds: return 5
        case .every10Seconds: return 10
        case .every30Seconds: return 30
        case .everyMinute: return 60
        }
    }
}

public struct ScannerSettings: Codable, Equatable {
    public init() {}
    public var mode: ScannerMode = .every5Seconds
    public var aggressiveScanning = false
    public var batterySaver = true
    public var highAccuracyGPS = true
    public var repeatedChecks = 2
    public var retryCount = 1
    public var autoSave = true
    public var signalThreshold = -88
    public var ignoreWeakNetworks = true
    public var demoModeEnabled = false
}

public struct WiFiObservation: Identifiable, Codable, Equatable {
    public let id: UUID
    public let networkID: UUID
    public let timestamp: Date
    public let latitude: Double
    public let longitude: Double
    public let rssi: Int
    public let sessionID: UUID?
}

public struct WiFiNetworkSnapshot: Identifiable, Codable, Equatable {
    public let id: UUID
    public var ssid: String
    public var bssid: String
    public var latitude: Double
    public var longitude: Double
    public var timestamp: Date
    public var rssi: Int
    public var frequencyMHz: Int?
    public var channel: Int?
    public var band: WiFiBand
    public var security: WiFiSecurity
    public var encryption: String?
    public var encoding: String?
    public var captivePortalHint: String?
    public var authenticationHint: String?
    public var scanCount: Int
    public var lastSeen: Date
    public var history: [WiFiObservation]

    public init(
        id: UUID,
        ssid: String,
        bssid: String,
        latitude: Double,
        longitude: Double,
        timestamp: Date,
        rssi: Int,
        frequencyMHz: Int? = nil,
        channel: Int? = nil,
        band: WiFiBand,
        security: WiFiSecurity,
        encryption: String? = nil,
        encoding: String? = nil,
        captivePortalHint: String? = nil,
        authenticationHint: String? = nil,
        scanCount: Int,
        lastSeen: Date,
        history: [WiFiObservation] = []
    ) {
        self.id = id
        self.ssid = ssid
        self.bssid = bssid
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.rssi = rssi
        self.frequencyMHz = frequencyMHz
        self.channel = channel
        self.band = band
        self.security = security
        self.encryption = encryption
        self.encoding = encoding
        self.captivePortalHint = captivePortalHint
        self.authenticationHint = authenticationHint
        self.scanCount = scanCount
        self.lastSeen = lastSeen
        self.history = history
    }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public var signalQuality: Double {
        min(max((Double(rssi) + 100) / 60, 0), 1)
    }
}

public struct ScanSessionState: Equatable {
    public init() {}
    public var isScanning = false
    public var sessionID: UUID?
    public var startedAt: Date?
    public var totalObservations = 0
    public var uniqueNetworks = 0
    public var lastErrorMessage: String?
}

public struct NetworkFilter: Equatable {
    public init() {}
    public var searchText = ""
    public var bands = Set(WiFiBand.allCases)
    public var securityTypes = Set(WiFiSecurity.allCases)
    public var minimumRSSI = -100
    public var selectedChannel: Int?
    public var openNetworksOnly = false
    public var dateScope: HistoryTimeScope = .all
    public var minimumScanCount = 0
    public var sortOrder: NetworkSortOrder = .newest

    public func matches(_ network: WiFiNetworkSnapshot) -> Bool {
        let searchMatches = searchText.isEmpty || network.ssid.localizedCaseInsensitiveContains(searchText) || network.bssid.localizedCaseInsensitiveContains(searchText)
        let bandMatches = bands.contains(network.band)
        let securityMatches = securityTypes.contains(network.security)
        let signalMatches = network.rssi >= minimumRSSI
        let channelMatches = selectedChannel == nil || network.channel == selectedChannel
        let openMatches = !openNetworksOnly || network.security == .open
        let dateMatches = dateScope.contains(network.lastSeen)
        let scanCountMatches = network.scanCount >= minimumScanCount
        return searchMatches && bandMatches && securityMatches && signalMatches && channelMatches && openMatches && dateMatches && scanCountMatches
    }
}

public struct AnalyticsSummary {
    public init() {}
    public struct DistributionItem: Identifiable {
        public let id = UUID()
        public let label: String
        public let value: Int
    }

    public var totalNetworks = 0
    public var totalObservations = 0
    public var openNetworks = 0
    public var averageRSSI = -100.0
    public var strongestSSID = "-"
    public var averageScanCount = 0.0
    public var bandDistribution: [DistributionItem] = []
    public var securityDistribution: [DistributionItem] = []
    public var channelDistribution: [DistributionItem] = []
    public var dailyObservations: [DistributionItem] = []
}

public enum HistoryTimeScope: String, CaseIterable, Codable, Identifiable {
    case all = "All time"
    case last24Hours = "24h"
    case last7Days = "7d"
    case last30Days = "30d"

    public var id: String { rawValue }

    public func contains(_ date: Date, relativeTo referenceDate: Date = Date()) -> Bool {
        switch self {
        case .all:
            return true
        case .last24Hours:
            return date >= referenceDate.addingTimeInterval(-86_400)
        case .last7Days:
            return date >= referenceDate.addingTimeInterval(-604_800)
        case .last30Days:
            return date >= referenceDate.addingTimeInterval(-2_592_000)
        }
    }
}

public enum NetworkSortOrder: String, CaseIterable, Codable, Identifiable {
    case newest = "Newest"
    case strongest = "Strongest"
    case mostSeen = "Most seen"
    case ssid = "SSID"

    public var id: String { rawValue }
}

public enum ComparisonWindow: String, CaseIterable, Identifiable {
    case lastHour = "1h"
    case last24Hours = "24h"
    case last7Days = "7d"
    case all = "All"

    public var id: String { rawValue }

    public var interval: TimeInterval {
        switch self {
        case .lastHour:
            return 3_600
        case .last24Hours:
            return 86_400
        case .last7Days:
            return 604_800
        case .all:
            return 60 * 60 * 24 * 365 * 10
        }
    }
}

public enum AreaNetworkState: String {
    case new = "New"
    case stable = "Stable"
    case disappeared = "Disappeared"
}

public struct AreaComparisonItem: Identifiable, Equatable {
    public let id: UUID
    public let ssid: String
    public let bssid: String
    public let state: AreaNetworkState
    public let rssi: Int
    public let lastSeen: Date
}

public struct AreaHistoryComparison: Equatable {
    public init() {}
    public var centerDescription = "Waiting for location"
    public var radiusMeters = 150.0
    public var newNetworks: [AreaComparisonItem] = []
    public var stableNetworks: [AreaComparisonItem] = []
    public var disappearedNetworks: [AreaComparisonItem] = []

    public var totalCurrent: Int { newNetworks.count + stableNetworks.count }
    public var hasHistory: Bool { !stableNetworks.isEmpty || !disappearedNetworks.isEmpty || !newNetworks.isEmpty }
    public var strongestLabel: String {
        (newNetworks + stableNetworks).max { $0.rssi < $1.rssi }?.ssid ?? "-"
    }
}

public enum MapLayer: String, CaseIterable, Identifiable {
    case points = "Points"
    case heatmap = "Heatmap"
    case congestion = "Congestion"
    case route = "Route"

    public var id: String { rawValue }
}

public enum MapPresentationStyle: String, CaseIterable, Identifiable {
    case standard = "Streets"
    case hybrid = "Hybrid"
    case imagery = "Satellite"

    public var id: String { rawValue }
}
