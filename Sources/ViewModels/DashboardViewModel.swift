
import Combine
import CoreLocation
import Foundation
import UIKit
import WiFiMapperCore
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var sessionState = ScanSessionState()
    @Published private(set) var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var localNetworkAuthorizationStatus: PermissionService.LocalNetworkStatus = .unknown
    @Published private(set) var locationStatus = AppStrings.localized("location.status.notAuthorized")
    @Published private(set) var localNetworkStatus = AppStrings.localized("permission.localNetwork.unknown")
    @Published private(set) var accuracy = AppStrings.localized("location.status.unknown")
    @Published private(set) var currentSSID = AppStrings.localized("dashboard.kpi.currentSsid.noData")
    @Published private(set) var lastScanText = AppStrings.localized("general.waiting")
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
                self?.currentSSID = networks.first?.ssid ?? AppStrings.localized("dashboard.kpi.currentSsid.empty")
            }
            .store(in: &cancellables)

        appModel.scannerService.$lastScanDate
            .receive(on: RunLoop.main)
            .sink { [weak self] date in
                self?.lastScanText = date.map { Self.relativeFormatter.localizedString(for: $0, relativeTo: Date()) } ?? AppStrings.localized("general.waiting")
            }
            .store(in: &cancellables)

        appModel.locationService.$authorizationStatus
            .combineLatest(appModel.locationService.$accuracyDescription)
            .receive(on: RunLoop.main)
            .sink { [weak self] status, accuracy in
                self?.locationAuthorizationStatus = status
                self?.locationStatus = Self.describe(status)
                self?.accuracy = accuracy
            }
            .store(in: &cancellables)

        appModel.permissionService.$localNetworkStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] status in
                self?.localNetworkAuthorizationStatus = status
                self?.localNetworkStatus = Self.describe(status)
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
        if sessionState.isScanning {
            appModel.scannerService.stopScanning()
            return
        }

        guard canStartScanning else {
            sessionState.lastErrorMessage = AppStrings.localized("dashboard.permissions.body")
            return
        }

        appModel.scannerService.startScanning()
    }

    func requestPermissions() {
        appModel.permissionService.requestLocation(using: appModel.locationService)
        appModel.permissionService.requestLocalNetwork()
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
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

    var permissionSummaryTitle: String {
        AppStrings.localized("dashboard.permissions.title")
    }

    var permissionSummaryBody: String {
        AppStrings.localized("dashboard.permissions.body")
    }

    var locationPermissionLabel: String {
        AppStrings.localized("dashboard.permissions.location")
    }

    var localNetworkPermissionLabel: String {
        AppStrings.localized("dashboard.permissions.localNetwork")
    }

    var canStartScanning: Bool {
        if appModel.scannerService.settings.inputSource == .externalScanner {
            return true
        }
        let locationGranted = locationAuthorizationStatus == .authorizedAlways || locationAuthorizationStatus == .authorizedWhenInUse
        return locationGranted
    }

    private static func describe(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedAlways: return AppStrings.localized("location.status.always")
        case .authorizedWhenInUse: return AppStrings.localized("location.status.whenInUse")
        case .denied: return AppStrings.localized("location.status.denied")
        case .restricted: return AppStrings.localized("location.status.restricted")
        case .notDetermined: return AppStrings.localized("location.status.pending")
        @unknown default: return AppStrings.localized("location.status.unknown")
        }
    }

    private static func describe(_ status: PermissionService.LocalNetworkStatus) -> String {
        switch status {
        case .unknown: return AppStrings.localized("permission.localNetwork.unknown")
        case .granted: return AppStrings.localized("permission.localNetwork.granted")
        case .denied: return AppStrings.localized("permission.localNetwork.denied")
        }
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
}
