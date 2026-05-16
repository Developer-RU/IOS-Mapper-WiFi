
import Combine
import CoreLocation
import Foundation
import WiFiMapperCore
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var sessionState = ScanSessionState()
    @Published private(set) var locationStatus = String(localized: "location.status.notAuthorized")
    @Published private(set) var accuracy = "Unknown"
    @Published private(set) var currentSSID = "No data"
    @Published private(set) var lastScanText = "Waiting"
    @Published private(set) var areaComparison = AreaHistoryComparison()
    @Published private(set) var isDemoMode = false

    private let appModel: AppModel
    private var cancellables: Set<AnyCancellable> = []

    init(appModel: AppModel) {
        self.appModel = appModel

        appModel.scannerService.$sessionState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.sessionState = state
            }
            .store(in: &cancellables)

        appModel.scannerService.$liveNetworks
            .receive(on: RunLoop.main)
            .sink { [weak self] networks in
                self?.currentSSID = networks.first?.ssid ?? "No Wi-Fi sample"
            }
            .store(in: &cancellables)

        appModel.scannerService.$lastScanDate
            .receive(on: RunLoop.main)
            .sink { [weak self] date in
                self?.lastScanText = date.map { Self.relativeFormatter.localizedString(for: $0, relativeTo: Date()) } ?? "Waiting"
            }
            .store(in: &cancellables)

        appModel.locationService.$authorizationStatus
            .combineLatest(appModel.locationService.$accuracyDescription)
            .receive(on: RunLoop.main)
            .sink { [weak self] status, accuracy in
                self?.locationStatus = Self.describe(status)
                self?.accuracy = accuracy
            }
            .store(in: &cancellables)

        appModel.scannerService.$settings
            .map(\.demoModeEnabled)
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.isDemoMode = $0 }
            .store(in: &cancellables)

        appModel.scannerService.$liveNetworks
            .combineLatest(appModel.locationService.$currentLocation)
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] _, location in
                guard let coordinate = location?.coordinate else { return }
                Task { await self?.refreshAreaComparison(for: coordinate) }
            }
            .store(in: &cancellables)
    }

    func onAppear() {
        appModel.permissionService.requestLocation(using: appModel.locationService)
        appModel.permissionService.requestLocalNetwork()
        Task {
            await appModel.scannerService.refreshHistory()
            if let coordinate = appModel.locationService.currentLocation?.coordinate {
                await refreshAreaComparison(for: coordinate)
            }
        }
    }

    func toggleScanning() {
        sessionState.isScanning ? appModel.scannerService.stopScanning() : appModel.scannerService.startScanning()
    }

    func requestPermissions() {
        appModel.permissionService.requestLocation(using: appModel.locationService)
        appModel.permissionService.requestLocalNetwork()
    }

    func elapsedText(since startDate: Date, now: Date) -> String {
        let components = Duration.seconds(now.timeIntervalSince(startDate)).formatted(
            .units(allowed: [.hours, .minutes, .seconds], width: .abbreviated, maximumUnitCount: 2)
        )
        return components
    }

    private func refreshAreaComparison(for coordinate: CLLocationCoordinate2D) async {
        do {
            areaComparison = try await appModel.repository.compareArea(around: coordinate)
        } catch {
            sessionState.lastErrorMessage = error.localizedDescription
        }
    }

    private static func describe(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedAlways: return String(localized: "location.status.always")
        case .authorizedWhenInUse: return String(localized: "location.status.whenInUse")
        case .denied: return String(localized: "location.status.denied")
        case .restricted: return String(localized: "location.status.restricted")
        case .notDetermined: return String(localized: "location.status.pending")
        @unknown default: return String(localized: "location.status.unknown")
        }
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
}
