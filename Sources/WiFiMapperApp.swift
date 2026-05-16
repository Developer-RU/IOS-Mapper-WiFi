
import SwiftUI
import WiFiMapperCore
@main
struct WiFiMapperApp: App {
    @StateObject private var appModel = AppModel()
    @State private var showSplash = true

    init() {
        UITableView.appearance().backgroundColor = .clear
    }

    @ViewBuilder
    private var configuredRootView: some View {
        let root = ZStack {
            ContentView(appModel: appModel)
                .task {
                    try? await Task.sleep(for: .seconds(1.8))
                    withAnimation(.smooth(duration: 0.6)) {
                        showSplash = false
                    }
                }

            if showSplash {
                SplashView()
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
            }
        }
        .preferredColorScheme(appModel.appearance.colorScheme)
        .environment(\.locale, appModel.language.locale)

        if let dynamicTypeSize = appModel.textSize.dynamicTypeSize {
            root.dynamicTypeSize(dynamicTypeSize)
        } else {
            root
        }
    }

    var body: some Scene {
        WindowGroup {
            configuredRootView
        }
    }
}
