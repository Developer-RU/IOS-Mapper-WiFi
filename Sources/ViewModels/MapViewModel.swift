
import Combine
import CoreLocation
import Foundation
import WiFiMapperCore
@MainActor
final class MapViewModel: ObservableObject {
    @Published var filter = NetworkFilter()
    @Published var selectedStyle: MapPresentationStyle = .standard
    @Published var activeLayers: Set<MapLayer> = Set(MapLayer.allCases)
    @Published var displayedNetworks: [WiFiNetworkSnapshot] = []
    @Published private(set) var availableChannels: [Int] = []
    @Published private(set) var isDemoMode = false
    @Published var selectedNetwork: WiFiNetworkSnapshot?
    @Published var isFilterSheetPresented = false

    private let appModel: AppModel
    private var cancellables: Set<AnyCancellable> = []

    init(appModel: AppModel) {
        self.appModel = appModel

        appModel.scannerService.$liveNetworks
            .combineLatest($filter)
            .receive(on: RunLoop.main)
            .sink { [weak self] networks, filter in
                self?.displayedNetworks = networks.filter(filter.matches)
                self?.availableChannels = Array(Set(networks.compactMap(\.channel))).sorted()
            }
            .store(in: &cancellables)

        appModel.scannerService.$settings
            .map(\.demoModeEnabled)
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.isDemoMode = $0 }
            .store(in: &cancellables)
    }

    var route: [CLLocationCoordinate2D] { appModel.locationService.route }
    var userLocation: CLLocationCoordinate2D? { appModel.locationService.currentLocation?.coordinate }

    func load() {
        Task { await appModel.scannerService.refreshHistory() }
    }

    func resetFilters() {
        filter = NetworkFilter()
    }
}
