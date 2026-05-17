
import SwiftUI
import WiFiMapperCore
struct HistoryComparisonView: View {
    @StateObject var viewModel: HistoryComparisonViewModel

    var body: some View {
        ZStack {
            GradientBackdrop()

            ScrollView {
                VStack(spacing: 18) {
                    ScreenHeader(
                        eyebrow: "history.header.eyebrow",
                        title: "history.header.title",
                        subtitle: "history.header.subtitle"
                    )

                    ExternalScannerStatusBanner()

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            GlowBadge(title: "history.hero.badge")
                            Text("history.hero.title")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                            Text("history.hero.subtitle")
                                .foregroundStyle(.secondary)

                            VStack(alignment: .leading, spacing: 10) {
                                Text("history.hero.center \(viewModel.currentCoordinateDescription)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Text("history.hero.radius")
                                    Spacer()
                                    Text("\(Int(viewModel.radiusMeters)) m")
                                        .foregroundStyle(.secondary)
                                }
                                Slider(value: $viewModel.radiusMeters, in: 50 ... 500, step: 25)
                                Picker("history.hero.window", selection: $viewModel.comparisonWindow) {
                                    ForEach(ComparisonWindow.allCases) { item in
                                        Text(item.localizedTitle).tag(item)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatTile(title: "history.kpi.new.title", value: "\(viewModel.comparison.newNetworks.count)", subtitle: "history.kpi.new.subtitle", tint: .green)
                        StatTile(title: "history.kpi.stable.title", value: "\(viewModel.comparison.stableNetworks.count)", subtitle: "history.kpi.stable.subtitle", tint: .blue)
                        StatTile(title: "history.kpi.missing.title", value: "\(viewModel.comparison.disappearedNetworks.count)", subtitle: "history.kpi.missing.subtitle", tint: .orange)
                        StatTile(title: "history.kpi.strongest.title", value: viewModel.comparison.strongestLabel, subtitle: "history.kpi.strongest.subtitle", tint: .teal)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        GlassCard {
                            Label(errorMessage, systemImage: "location.slash")
                                .foregroundStyle(.orange)
                        }
                    }

                    comparisonSection(title: AppStrings.localized("history.section.new"), items: viewModel.comparison.newNetworks, tint: .green)
                    comparisonSection(title: AppStrings.localized("history.section.stable"), items: viewModel.comparison.stableNetworks, tint: .blue)
                    comparisonSection(title: AppStrings.localized("history.section.disappeared"), items: viewModel.comparison.disappearedNetworks, tint: .orange)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, LayoutMetrics.bottomContentPadding)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .onChange(of: viewModel.radiusMeters) { _, _ in
            Task { await viewModel.refresh() }
        }
        .onChange(of: viewModel.comparisonWindow) { _, _ in
            Task { await viewModel.refresh() }
        }
    }

    private func comparisonSection(title: String, items: [AreaComparisonItem], tint: Color) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(tint)

                if items.isEmpty {
                    Text("history.section.empty")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(items.prefix(6)) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.ssid)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                Text(item.bssid)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(item.rssi) dBm")
                                    .font(.footnote.weight(.medium))
                                    .lineLimit(1)
                                Text(item.lastSeen.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .frame(minHeight: 48)
                        if item.id != items.prefix(6).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}
