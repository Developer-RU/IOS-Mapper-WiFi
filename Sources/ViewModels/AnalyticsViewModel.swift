
import Foundation
import WiFiMapperCore
@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published var filter: NetworkFilter = {
        var filter = NetworkFilter()
        filter.sortOrder = .strongest
        return filter
    }()
    @Published private(set) var summary = AnalyticsSummary()
    @Published private(set) var latestNetworks: [WiFiNetworkSnapshot] = []
    @Published var errorMessage: String?

    private let appModel: AppModel

    init(appModel: AppModel) {
        self.appModel = appModel
    }

    func load() async {
        do {
            summary = try await appModel.repository.analyticsSummary(filter: filter)
            latestNetworks = try await appModel.repository.fetchNetworks(filter: filter).prefix(5).map { $0 }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
