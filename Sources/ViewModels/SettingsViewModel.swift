
import Combine
import Foundation
import WiFiMapperCore
@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings = ScannerSettings()
    @Published var appearance: AppAppearance = .system
    @Published var language: AppLanguage = .system
    @Published var textSize: AppTextSize = .system

    private let appModel: AppModel
    private var cancellables: Set<AnyCancellable> = []

    init(appModel: AppModel) {
        self.appModel = appModel
        settings = appModel.scannerService.settings
        appearance = appModel.appearance
        language = appModel.language
        textSize = appModel.textSize

        appModel.scannerService.$settings
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.settings = $0 }
            .store(in: &cancellables)

        appModel.$appearance
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.appearance = $0 }
            .store(in: &cancellables)

        appModel.$language
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.language = $0 }
            .store(in: &cancellables)

        appModel.$textSize
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.textSize = $0 }
            .store(in: &cancellables)
    }

    func update(_ transform: @escaping (inout ScannerSettings) -> Void) {
        appModel.scannerService.updateSettings(transform)
    }

    func seedDemoData() {
        Task {
            await appModel.seedDemoData()
        }
    }

    func setAppearance(_ appearance: AppAppearance) {
        appModel.appearance = appearance
    }

    func setLanguage(_ language: AppLanguage) {
        appModel.language = language
    }

    func setTextSize(_ textSize: AppTextSize) {
        appModel.textSize = textSize
    }
}
