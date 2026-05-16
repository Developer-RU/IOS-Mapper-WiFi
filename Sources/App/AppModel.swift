
import BackgroundTasks
import Combine
import Foundation
import SwiftUI
import WiFiMapperCore

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return String(localized: "settings.appearance.system")
        case .light: return String(localized: "settings.appearance.light")
        case .dark: return String(localized: "settings.appearance.dark")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case russian
    case spanish
    case german
    case french
    case italian
    case japanese

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return String(localized: "settings.language.system")
        case .english: return String(localized: "settings.language.english")
        case .russian: return String(localized: "settings.language.russian")
        case .spanish: return String(localized: "settings.language.spanish")
        case .german: return String(localized: "settings.language.german")
        case .french: return String(localized: "settings.language.french")
        case .italian: return String(localized: "settings.language.italian")
        case .japanese: return String(localized: "settings.language.japanese")
        }
    }

    var locale: Locale {
        switch self {
        case .system: return .autoupdatingCurrent
        case .english: return Locale(identifier: "en")
        case .russian: return Locale(identifier: "ru")
        case .spanish: return Locale(identifier: "es")
        case .german: return Locale(identifier: "de")
        case .french: return Locale(identifier: "fr")
        case .italian: return Locale(identifier: "it")
        case .japanese: return Locale(identifier: "ja")
        }
    }
}

enum AppTextSize: String, CaseIterable, Identifiable {
    case system
    case xSmall
    case small
    case medium
    case large
    case xLarge
    case xxLarge
    case xxxLarge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return String(localized: "settings.textSize.system")
        case .xSmall: return String(localized: "settings.textSize.xSmall")
        case .small: return String(localized: "settings.textSize.small")
        case .medium: return String(localized: "settings.textSize.medium")
        case .large: return String(localized: "settings.textSize.large")
        case .xLarge: return String(localized: "settings.textSize.xLarge")
        case .xxLarge: return String(localized: "settings.textSize.xxLarge")
        case .xxxLarge: return String(localized: "settings.textSize.xxxLarge")
        }
    }

    var dynamicTypeSize: DynamicTypeSize? {
        switch self {
        case .system: return nil
        case .xSmall: return .xSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .xLarge: return .xLarge
        case .xxLarge: return .xxLarge
        case .xxxLarge: return .xxxLarge
        }
    }
}

@MainActor
final class AppModel: ObservableObject {
    let persistence: PersistenceController
    let repository: NetworkRepository
    let locationService: LocationService
    let permissionService: PermissionService
    let scannerService: WiFiScannerService
    let exportService: ExportService
    let backgroundTaskService: BackgroundTaskService
    @Published var appearance: AppAppearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: Self.appearanceDefaultsKey)
        }
    }
    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.languageDefaultsKey)
        }
    }
    @Published var textSize: AppTextSize {
        didSet {
            UserDefaults.standard.set(textSize.rawValue, forKey: Self.textSizeDefaultsKey)
        }
    }

    private static let appearanceDefaultsKey = "app.appearance"
    private static let languageDefaultsKey = "app.language"
    private static let textSizeDefaultsKey = "app.textSize"

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        let repository = NetworkRepository(persistence: persistence)
        let locationService = LocationService()
        let permissionService = PermissionService()
        let scannerService = WiFiScannerService(repository: repository, locationService: locationService)
        let exportService = ExportService(repository: repository, persistence: persistence)
        let backgroundTaskService = BackgroundTaskService(scannerService: scannerService)

        self.repository = repository
        self.locationService = locationService
        self.permissionService = permissionService
        self.scannerService = scannerService
        self.exportService = exportService
        self.backgroundTaskService = backgroundTaskService
        let savedAppearance = UserDefaults.standard.string(forKey: Self.appearanceDefaultsKey)
        let savedLanguage = UserDefaults.standard.string(forKey: Self.languageDefaultsKey)
        let savedTextSize = UserDefaults.standard.string(forKey: Self.textSizeDefaultsKey)
        self.appearance = AppAppearance(rawValue: savedAppearance ?? "") ?? .system
        self.language = AppLanguage(rawValue: savedLanguage ?? "") ?? .system
        self.textSize = AppTextSize(rawValue: savedTextSize ?? "") ?? .system
    }

    func configureBackgroundTasks() {
        backgroundTaskService.register()
    }

    func scheduleRefresh() {
        backgroundTaskService.scheduleRefresh()
    }

    func seedDemoData() async {
        await scannerService.seedDemoDataset()
    }
}
