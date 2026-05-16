
import SwiftUI
import WiFiMapperCore
struct ContentView: View {
    @ObservedObject var appModel: AppModel
    @State private var selection: AppTab = .dashboard

    var body: some View {
        ZStack {
            Group {
                switch selection {
                case .dashboard:
                    NavigationStack {
                        DashboardView(viewModel: DashboardViewModel(appModel: appModel))
                    }
                case .map:
                    NavigationStack {
                        MapScreen(viewModel: MapViewModel(appModel: appModel))
                    }
                case .database:
                    NavigationStack {
                        DatabaseBrowserView(viewModel: DatabaseBrowserViewModel(appModel: appModel))
                    }
                case .analytics:
                    NavigationStack {
                        AnalyticsView(viewModel: AnalyticsViewModel(appModel: appModel))
                    }
                case .history:
                    NavigationStack {
                        HistoryComparisonView(viewModel: HistoryComparisonViewModel(appModel: appModel))
                    }
                case .settings:
                    NavigationStack {
                        SettingsView(viewModel: SettingsViewModel(appModel: appModel))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppTabBar(selection: $selection)
        }
    }
}
