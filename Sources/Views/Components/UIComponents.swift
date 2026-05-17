
import Charts
import SwiftUI
import WiFiMapperCore

extension WiFiBand {
    var localizedTitle: String {
        switch self {
        case .band24: return AppStrings.localized("wifi.band.24")
        case .band5: return AppStrings.localized("wifi.band.5")
        case .band6: return AppStrings.localized("wifi.band.6")
        case .unknown: return AppStrings.localized("wifi.band.unknown")
        }
    }
}

extension WiFiSecurity {
    var localizedTitle: String {
        switch self {
        case .open: return AppStrings.localized("wifi.security.open")
        case .wpa: return AppStrings.localized("wifi.security.wpa")
        case .wpa2: return AppStrings.localized("wifi.security.wpa2")
        case .wpa3: return AppStrings.localized("wifi.security.wpa3")
        case .secure: return AppStrings.localized("wifi.security.secure")
        case .unknown: return AppStrings.localized("wifi.security.unknown")
        }
    }
}

extension ScannerMode {
    var localizedTitle: String {
        switch self {
        case .continuous: return AppStrings.localized("scanner.mode.continuous")
        case .every5Seconds: return AppStrings.localized("scanner.mode.every5s")
        case .every10Seconds: return AppStrings.localized("scanner.mode.every10s")
        case .every30Seconds: return AppStrings.localized("scanner.mode.every30s")
        case .everyMinute: return AppStrings.localized("scanner.mode.everyMinute")
        }
    }
}

extension ScannerInputSource {
    var localizedTitle: String {
        switch self {
        case .iphoneAssociated: return AppStrings.localized("scanner.source.iphone")
        case .externalScanner: return AppStrings.localized("scanner.source.external")
        }
    }
}

extension MapLayer {
    var localizedTitle: String {
        switch self {
        case .points: return AppStrings.localized("map.layer.points")
        case .heatmap: return AppStrings.localized("map.layer.heatmap")
        case .congestion: return AppStrings.localized("map.layer.congestion")
        case .route: return AppStrings.localized("map.layer.route")
        }
    }
}

extension MapPresentationStyle {
    var localizedTitle: String {
        switch self {
        case .standard: return AppStrings.localized("map.style.standard")
        case .hybrid: return AppStrings.localized("map.style.hybrid")
        case .imagery: return AppStrings.localized("map.style.imagery")
        }
    }
}

extension NetworkSortOrder {
    var localizedTitle: String {
        switch self {
        case .newest: return AppStrings.localized("sort.newest")
        case .strongest: return AppStrings.localized("sort.strongest")
        case .mostSeen: return AppStrings.localized("sort.mostSeen")
        case .ssid: return AppStrings.localized("sort.ssid")
        }
    }
}

extension HistoryTimeScope {
    var localizedTitle: String {
        switch self {
        case .all: return AppStrings.localized("timeScope.all")
        case .last24Hours: return AppStrings.localized("timeScope.24h")
        case .last7Days: return AppStrings.localized("timeScope.7d")
        case .last30Days: return AppStrings.localized("timeScope.30d")
        }
    }
}

extension ComparisonWindow {
    var localizedTitle: String {
        switch self {
        case .lastHour: return AppStrings.localized("comparison.1h")
        case .last24Hours: return AppStrings.localized("comparison.24h")
        case .last7Days: return AppStrings.localized("comparison.7d")
        case .all: return AppStrings.localized("comparison.all")
        }
    }
}

enum LayoutMetrics {
    static let bottomContentPadding: CGFloat = 123
}

enum ResponsiveMetrics {
    static func scale(for dynamicTypeSize: DynamicTypeSize, horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        var scale: CGFloat = horizontalSizeClass == .regular ? 1.08 : 1.0
        if dynamicTypeSize.isAccessibilitySize {
            scale *= 1.12
        } else if dynamicTypeSize >= .xxxLarge {
            scale *= 1.05
        }
        return scale
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case map
    case database
    case analytics
    case history
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return AppStrings.localized("tab.dashboard")
        case .map: return AppStrings.localized("tab.map")
        case .database: return AppStrings.localized("tab.database")
        case .analytics: return AppStrings.localized("tab.analytics")
        case .history: return AppStrings.localized("tab.history")
        case .settings: return AppStrings.localized("tab.settings")
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "dot.scope.display"
        case .map: return "map"
        case .database: return "internaldrive"
        case .analytics: return "waveform.path.ecg.rectangle"
        case .history: return "clock.arrow.trianglehead.counterclockwise.rotate.90"
        case .settings: return "slider.horizontal.3"
        }
    }
}

struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ViewBuilder var content: Content

    var body: some View {
        let scale = ResponsiveMetrics.scale(for: dynamicTypeSize, horizontalSizeClass: horizontalSizeClass)

        content
            .padding(20 * scale)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(colorScheme == .dark ? Color(red: 0.90, green: 0.94, blue: 0.96) : Color(red: 0.13, green: 0.18, blue: 0.20))
            .background(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(red: 0.14, green: 0.18, blue: 0.21).opacity(0.96), Color(red: 0.08, green: 0.12, blue: 0.15).opacity(0.94)]
                        : [Color(red: 0.99, green: 0.98, blue: 0.95), Color.white.opacity(0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.16) : Color.white.opacity(0.42), lineWidth: 1)
            )
            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.38) : Color(red: 0.09, green: 0.19, blue: 0.24).opacity(0.08), radius: 20, x: 0, y: 12)
    }
}

struct StatTile: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let title: LocalizedStringKey
    let value: String
    let subtitle: LocalizedStringKey
    let tint: Color

    private var tileHeight: CGFloat {
        148 * ResponsiveMetrics.scale(for: dynamicTypeSize, horizontalSizeClass: horizontalSizeClass)
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.74) : Color(red: 0.23, green: 0.29, blue: 0.31))
                    .lineLimit(1)
                Text(value)
                    .font(.system(size: 26 * ResponsiveMetrics.scale(for: dynamicTypeSize, horizontalSizeClass: horizontalSizeClass), weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.7) : Color(red: 0.25, green: 0.33, blue: 0.35))
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity)
        .frame(height: tileHeight)
    }
}

struct SignalHistoryChart: View {
    let history: [WiFiObservation]

    var body: some View {
        Chart(history) { item in
            LineMark(
                x: .value("Time", item.timestamp),
                y: .value("RSSI", item.rssi)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Color.blue.gradient)

            AreaMark(
                x: .value("Time", item.timestamp),
                y: .value("RSSI", item.rssi)
            )
            .foregroundStyle(Color.blue.opacity(0.18).gradient)
        }
        .frame(height: 200)
        .chartYScale(domain: -100 ... -20)
    }
}

struct GradientBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.05, green: 0.08, blue: 0.11), Color(red: 0.08, green: 0.11, blue: 0.14), Color(red: 0.06, green: 0.10, blue: 0.12)]
                    : [Color(red: 0.98, green: 0.96, blue: 0.92), Color(red: 0.99, green: 0.98, blue: 0.95), Color(red: 0.90, green: 0.96, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.15, green: 0.61, blue: 0.74).opacity(colorScheme == .dark ? 0.22 : 0.14))
                .frame(width: 320, height: 320)
                .blur(radius: 28)
                .offset(x: 150, y: -250)

            Circle()
                .fill(Color(red: 0.95, green: 0.45, blue: 0.24).opacity(colorScheme == .dark ? 0.18 : 0.12))
                .frame(width: 250, height: 250)
                .blur(radius: 24)
                .offset(x: -170, y: 240)

            Circle()
                .fill(Color(red: 0.90, green: 0.72, blue: 0.24).opacity(colorScheme == .dark ? 0.16 : 0.10))
                .frame(width: 210, height: 210)
                .blur(radius: 18)
                .offset(x: 140, y: 260)
        }
        .ignoresSafeArea()
    }
}

struct GlowBadge: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let title: LocalizedStringKey

    private var textColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.92) : Color(red: 0.10, green: 0.17, blue: 0.20)
    }

    private var badgeBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.16) : Color.white.opacity(0.9)
    }

    private var badgeBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.22) : Color.white.opacity(0.72)
    }

    var body: some View {
        let scale = ResponsiveMetrics.scale(for: dynamicTypeSize, horizontalSizeClass: horizontalSizeClass)

        Text(title)
            .font(.system(size: 12 * scale, weight: .semibold, design: .rounded))
            .foregroundStyle(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(badgeBackgroundColor, in: Capsule())
            .overlay(Capsule().stroke(badgeBorderColor, lineWidth: 1))
            .shadow(color: Color.blue.opacity(0.12), radius: 10, x: 0, y: 6)
    }
}

struct ScreenHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let eyebrow: LocalizedStringKey
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        let scale = ResponsiveMetrics.scale(for: dynamicTypeSize, horizontalSizeClass: horizontalSizeClass)

        VStack(alignment: .leading, spacing: 10) {
            GlowBadge(title: eyebrow)
            Text(title)
                .font(.system(size: 36 * scale, weight: .bold, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? Color.white : Color(red: 0.10, green: 0.16, blue: 0.18))
            Text(subtitle)
                .font(.system(size: 15 * scale, weight: .medium, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.78) : Color(red: 0.24, green: 0.32, blue: 0.34))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DemoModeBanner: View {
    @Environment(\.colorScheme) private var colorScheme
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.title3)
                .foregroundStyle(Color.orange)

            VStack(alignment: .leading, spacing: 3) {
                Text("demo.mode.active")
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.78) : Color(red: 0.27, green: 0.31, blue: 0.33))
            }

            Spacer()
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color.orange.opacity(0.28), Color.yellow.opacity(0.16)]
                    : [Color.orange.opacity(0.18), Color.yellow.opacity(0.08)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.18) : Color.white.opacity(0.5), lineWidth: 1)
        )
    }
}

struct ExternalScannerStatusBanner: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var scannerService: WiFiScannerService
    @EnvironmentObject private var externalScannerService: ExternalScannerService

    private var isExternalMode: Bool {
        scannerService.settings.inputSource == .externalScanner
    }

    private var stateText: String {
        switch externalScannerService.status.state {
        case .disconnected: return AppStrings.localized("external.scanner.state.disconnected")
        case .connecting: return AppStrings.localized("external.scanner.state.connecting")
        case .connected: return AppStrings.localized("external.scanner.state.connected")
        case .scanning: return AppStrings.localized("external.scanner.state.scanning")
        case .failed: return AppStrings.localized("external.scanner.state.failed")
        }
    }

    private var statusDetailText: String {
        let status = externalScannerService.status

        switch status.state {
        case .disconnected:
            return AppStrings.localized("external.scanner.detail.disconnected")
        case .connecting:
            return AppStrings.localized("external.scanner.detail.connecting")
        case .failed:
            if let lastError = status.lastErrorMessage, !lastError.isEmpty {
                return AppStrings.localized("external.scanner.detail.failed %@", lastError)
            }
            return stateText
        case .scanning:
            return AppStrings.localized("external.scanner.detail.dataExchange %@", stateText)
        case .connected:
            if status.inProgress || status.lastCommand == "start" {
                return AppStrings.localized("external.scanner.detail.dataExchange %@", AppStrings.localized("external.scanner.state.scanning"))
            }
            if status.lastCommand == "stop" {
                return AppStrings.localized("external.scanner.detail.ready %@", stateText)
            }
            return AppStrings.localized("external.scanner.detail.monitoring %@", stateText)
        }
    }

    private var metadataText: String {
        let status = externalScannerService.status
        return AppStrings.localized("external.scanner.detail.metadata %@ %@", status.deviceID, status.firmware)
    }

    private var tint: Color {
        switch externalScannerService.status.state {
        case .connected, .scanning:
            return .green
        case .connecting:
            return .orange
        case .failed:
            return .red
        case .disconnected:
            return .secondary
        }
    }

    var body: some View {
        if isExternalMode {
            HStack(spacing: 12) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title3)
                    .foregroundStyle(tint)

                VStack(alignment: .leading, spacing: 3) {
                    Text("external.scanner.banner.title")
                        .font(.subheadline.weight(.semibold))
                    Text(statusDetailText)
                        .font(.footnote)
                        .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.78) : Color(red: 0.27, green: 0.31, blue: 0.33))
                        .lineLimit(2)
                    Text(metadataText)
                        .font(.caption2)
                        .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.66) : Color(red: 0.35, green: 0.39, blue: 0.41))
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color.green.opacity(0.22), Color.cyan.opacity(0.12)]
                        : [Color.green.opacity(0.14), Color.cyan.opacity(0.08)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.16) : Color.white.opacity(0.5), lineWidth: 1)
            )
        }
    }
}

struct AppTabBar: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var selection: AppTab

    @ViewBuilder
    private func tabBackground(isSelected: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(red: 0.10, green: 0.63, blue: 0.72), Color(red: 0.04, green: 0.45, blue: 0.52)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        } else {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.14) : Color.white.opacity(0.38))
        }
    }

    var body: some View {
        let scale = ResponsiveMetrics.scale(for: dynamicTypeSize, horizontalSizeClass: horizontalSizeClass)

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AppTab.allCases) { tab in
                    let isSelected = selection == tab
                    Button {
                        withAnimation(.smooth(duration: 0.28)) {
                            selection = tab
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 19 * scale, weight: .bold))
                            Text(tab.title)
                                .font(.system(size: 12 * scale, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(isSelected ? Color.white : (colorScheme == .dark ? Color.white.opacity(0.84) : Color(red: 0.14, green: 0.22, blue: 0.24)))
                        .frame(width: 102 * scale)
                        .padding(.vertical, 14 * scale)
                        .background(tabBackground(isSelected: isSelected))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.12, green: 0.15, blue: 0.18).opacity(0.94), Color(red: 0.08, green: 0.10, blue: 0.13).opacity(0.94)]
                    : [Color.white.opacity(0.90), Color(red: 0.98, green: 0.96, blue: 0.93).opacity(0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.16) : Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.34) : Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }
}
