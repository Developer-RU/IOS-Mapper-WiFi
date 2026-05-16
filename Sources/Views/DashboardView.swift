
import SwiftUI
import WiFiMapperCore
struct DashboardView: View {
    @StateObject var viewModel: DashboardViewModel

    var body: some View {
        ZStack {
            GradientBackdrop()

            ScrollView {
                VStack(spacing: 20) {
                    ScreenHeader(
                        eyebrow: "dashboard.header.eyebrow",
                        title: "dashboard.header.title",
                        subtitle: "dashboard.header.subtitle"
                    )

                    heroCard

                    if viewModel.isDemoMode {
                        DemoModeBanner(subtitle: String(localized: "dashboard.demo.subtitle"))
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatTile(title: "dashboard.kpi.networks.title", value: "\(viewModel.sessionState.uniqueNetworks)", subtitle: "dashboard.kpi.networks.subtitle", tint: .blue)
                        StatTile(title: "dashboard.kpi.samples.title", value: "\(viewModel.sessionState.totalObservations)", subtitle: "dashboard.kpi.samples.subtitle", tint: .green)
                        StatTile(title: "dashboard.kpi.location.title", value: viewModel.locationStatus, subtitle: LocalizedStringKey(viewModel.accuracy), tint: .orange)
                        StatTile(title: "dashboard.kpi.currentSsid.title", value: viewModel.currentSSID, subtitle: "dashboard.kpi.currentSsid.subtitle \(viewModel.lastScanText)", tint: .teal)
                    }

                    if let error = viewModel.sessionState.lastErrorMessage {
                        GlassCard {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("dashboard.area.title")
                                .font(.headline)
                            Text("dashboard.area.radius \(Int(viewModel.areaComparison.radiusMeters)) \(viewModel.areaComparison.centerDescription)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                miniMetric(title: "dashboard.area.metric.current", value: viewModel.areaComparison.totalCurrent, tint: .blue)
                                miniMetric(title: "dashboard.area.metric.new", value: viewModel.areaComparison.newNetworks.count, tint: .green)
                                miniMetric(title: "dashboard.area.metric.gone", value: viewModel.areaComparison.disappearedNetworks.count, tint: .orange)
                                miniMetric(title: "dashboard.area.metric.stable", value: viewModel.areaComparison.stableNetworks.count, tint: .teal)
                            }

                            Text("dashboard.area.strongest \(viewModel.areaComparison.strongestLabel)")
                                .font(.subheadline.weight(.medium))

                            comparisonList(title: String(localized: "dashboard.area.list.new"), items: viewModel.areaComparison.newNetworks)
                            comparisonList(title: String(localized: "dashboard.area.list.disappeared"), items: viewModel.areaComparison.disappearedNetworks)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("dashboard.platformNote.title")
                                .font(.headline)
                            Text(viewModel.sessionState.capabilityMessage)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, LayoutMetrics.bottomContentPadding)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { viewModel.onAppear() }
    }

    private var heroCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 12) {
                        GlowBadge(title: "dashboard.hero.badge")
                        Text("dashboard.hero.title")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                        Text("dashboard.hero.subtitle")
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 16)

                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color(red: 0.12, green: 0.63, blue: 0.72), Color(red: 0.95, green: 0.49, blue: 0.23)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 72, height: 72)
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                HStack(spacing: 12) {
                    Button(viewModel.sessionState.isScanning ? String(localized: "dashboard.hero.stopScan") : String(localized: "dashboard.hero.startScan")) {
                        withAnimation(.smooth(duration: 0.25)) {
                            viewModel.toggleScanning()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.blue)

                    Button("dashboard.hero.permissions") {
                        viewModel.requestPermissions()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                if let startedAt = viewModel.sessionState.startedAt, viewModel.sessionState.isScanning {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text("dashboard.hero.activeSession \(viewModel.elapsedText(since: startedAt, now: context.date))")
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }

    private func miniMetric(title: LocalizedStringKey, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text("\(value)")
                .font(.headline)
                .foregroundStyle(tint)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 84, maxHeight: 84, alignment: .topLeading)
        .background(Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        )
    }

    private func comparisonList(title: String, items: [AreaComparisonItem]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            if items.isEmpty {
                Text("dashboard.area.list.empty")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(items.prefix(3))) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.ssid)
                            Text(item.bssid)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(item.rssi) dBm")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
