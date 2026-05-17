import Foundation

enum AppStrings {
    static func localized(_ key: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: bundleForSelectedLanguage(), value: key, comment: "")
    }

    static func localized(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: localized(key), locale: localeForSelectedLanguage(), arguments: arguments)
    }

    private static func bundleForSelectedLanguage() -> Bundle {
        guard let language = selectedLanguageCode() else { return .main }
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let localizedBundle = Bundle(path: path) else {
            return .main
        }
        return localizedBundle
    }

    private static func localeForSelectedLanguage() -> Locale {
        guard let language = selectedLanguageCode() else { return .autoupdatingCurrent }
        return Locale(identifier: language)
    }

    private static func selectedLanguageCode() -> String? {
        let key = "app.language"
        guard let value = UserDefaults.standard.string(forKey: key),
              let appLanguage = AppLanguage(rawValue: value) else {
            return nil
        }

        switch appLanguage {
        case .system:
            return nil
        case .english:
            return "en"
        case .russian:
            return "ru"
        case .spanish:
            return "es"
        case .german:
            return "de"
        case .french:
            return "fr"
        case .italian:
            return "it"
        case .japanese:
            return "ja"
        }
    }
}
