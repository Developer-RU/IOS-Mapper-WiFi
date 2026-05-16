
import Foundation
import WiFiMapperCore
@MainActor
final class DatabaseBrowserViewModel: ObservableObject {
    @Published var filter = NetworkFilter()
    @Published private(set) var networks: [WiFiNetworkSnapshot] = []
    @Published private(set) var availableChannels: [Int] = []
    @Published var exportedFileURL: URL?
    @Published var exportError: String?

    private let appModel: AppModel

    init(appModel: AppModel) {
        self.appModel = appModel
    }

    func load() async {
        do {
            networks = try await appModel.repository.fetchNetworks(filter: filter)
            availableChannels = Array(Set(networks.compactMap(\.channel))).sorted()
        } catch {
            exportError = error.localizedDescription
        }
    }

    func delete(at offsets: IndexSet) async {
        let ids = offsets.compactMap { networks[safe: $0]?.id }
        do {
            try await appModel.repository.delete(networkIDs: ids)
            await load()
            await appModel.scannerService.refreshHistory()
        } catch {
            exportError = error.localizedDescription
        }
    }

    func delete(networkID: UUID) async {
        do {
            try await appModel.repository.delete(networkIDs: [networkID])
            await load()
            await appModel.scannerService.refreshHistory()
        } catch {
            exportError = error.localizedDescription
        }
    }

    func export(_ format: ExportService.ExportFormat) async {
        do {
            exportedFileURL = try await appModel.exportService.export(format: format)
        } catch {
            exportError = error.localizedDescription
        }
    }

    func resetFilters() {
        filter = NetworkFilter()
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
