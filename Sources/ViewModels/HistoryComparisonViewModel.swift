
import Combine
import CoreLocation
import Foundation
import WiFiMapperCore
@MainActor
final class HistoryComparisonViewModel: ObservableObject {
    @Published var radiusMeters: Double = 150
    @Published var comparisonWindow: ComparisonWindow = .last24Hours
    @Published private(set) var comparison = AreaHistoryComparison()
    @Published private(set) var currentCoordinateDescription = "Location pending"
    @Published var errorMessage: String?

    private let appModel: AppModel
    private var cancellables: Set<AnyCancellable> = []

    init(appModel: AppModel) {
        self.appModel = appModel

        appModel.locationService.$currentLocation
            .receive(on: RunLoop.main)
            .sink { [weak self] location in
                guard let self else { return }
                currentCoordinateDescription = location.map {
                    "\($0.coordinate.latitude.formatted(.number.precision(.fractionLength(4)))), \($0.coordinate.longitude.formatted(.number.precision(.fractionLength(4))))"
                } ?? "Location pending"
            }
            .store(in: &cancellables)
    }

    func load() async {
        await appModel.scannerService.refreshHistory()
        await refresh()
    }

    func refresh() async {
        guard let coordinate = appModel.locationService.currentLocation?.coordinate else {
            errorMessage = "Move with location enabled to compare the current area against stored history."
            return
        }

        do {
            comparison = try await appModel.repository.compareArea(
                around: coordinate,
                radiusMeters: radiusMeters,
                recentWindow: comparisonWindow.interval
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
