
import Charts
import SwiftUI
import WiFiMapperCore
struct AnalyticsView: View {
    @StateObject var viewModel: AnalyticsViewModel

    var body: some View {
        ZStack {
            GradientBackdrop()

            ScrollView {
                VStack(spacing: 18) {
                    ScreenHeader(
                        eyebrow: "analytics.header.eyebrow",
                        title: "analytics.header.title",
                        subtitle: "analytics.header.subtitle"
                    )

                    ExternalScannerStatusBanner()

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatTile(title: "analytics.kpi.networks.title", value: "\(viewModel.summary.totalNetworks)", subtitle: "analytics.kpi.networks.subtitle", tint: .blue)
                        StatTile(title: "analytics.kpi.observations.title", value: "\(viewModel.summary.totalObservations)", subtitle: "analytics.kpi.observations.subtitle", tint: .green)
                        StatTile(title: "analytics.kpi.open.title", value: "\(viewModel.summary.openNetworks)", subtitle: "analytics.kpi.open.subtitle", tint: .orange)
                        StatTile(title: "analytics.kpi.avgRssi.title", value: String(format: "%.0f dBm", viewModel.summary.averageRSSI), subtitle: LocalizedStringKey(viewModel.summary.strongestSSID), tint: .teal)
                        StatTile(title: "analytics.kpi.avgScans.title", value: String(format: "%.1f", viewModel.summary.averageScanCount), subtitle: "analytics.kpi.avgScans.subtitle", tint: .indigo)
                        StatTile(title: "analytics.kpi.window.title", value: viewModel.filter.dateScope.localizedTitle, subtitle: "analytics.kpi.window.subtitle", tint: .mint)
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("analytics.filters.title")
                                .font(.headline)
                            Picker("analytics.filters.date", selection: $viewModel.filter.dateScope) {
                                ForEach(HistoryTimeScope.allCases) { scope in
                                    Text(scope.localizedTitle).tag(scope)
                                }
                            }
                            .pickerStyle(.segmented)

                            Picker("analytics.filters.sort", selection: $viewModel.filter.sortOrder) {
                                ForEach(NetworkSortOrder.allCases) { order in
                                    Text(order.localizedTitle).tag(order)
                                }
                            }

                            Toggle("analytics.filters.openOnly", isOn: $viewModel.filter.openNetworksOnly)
                            Stepper("analytics.filters.minScans \(viewModel.filter.minimumScanCount)", value: $viewModel.filter.minimumScanCount, in: 0 ... 50)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("analytics.bandDistribution.title")
                                .font(.headline)
                            Chart(viewModel.summary.bandDistribution) { item in
                                BarMark(
                                    x: .value("Band", item.label),
                                    y: .value("Count", item.value)
                                )
                                .foregroundStyle(Color.blue.gradient)
                            }
                            .frame(height: 220)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("analytics.securityMix.title")
                                .font(.headline)
                            Chart(viewModel.summary.securityDistribution) { item in
                                SectorMark(
                                    angle: .value("Count", item.value),
                                    innerRadius: .ratio(0.52)
                                )
                                .foregroundStyle(by: .value("Security", item.label))
                            }
                            .frame(height: 240)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("analytics.channelCongestion.title")
                                .font(.headline)
                            Chart(viewModel.summary.channelDistribution) { item in
                                BarMark(
                                    x: .value("Channel", item.label),
                                    y: .value("Networks", item.value)
                                )
                                .foregroundStyle(Color.orange.gradient)
                            }
                            .frame(height: 220)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("analytics.observationTrend.title")
                                .font(.headline)
                            Chart(viewModel.summary.dailyObservations) { item in
                                LineMark(
                                    x: .value("Day", item.label),
                                    y: .value("Observations", item.value)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Color.teal.gradient)

                                AreaMark(
                                    x: .value("Day", item.label),
                                    y: .value("Observations", item.value)
                                )
                                .foregroundStyle(Color.teal.opacity(0.18).gradient)
                            }
                            .frame(height: 220)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("analytics.latestNetworks.title")
                                .font(.headline)
                            ForEach(viewModel.latestNetworks) { network in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(network.ssid)
                                            .lineLimit(1)
                                        Text(network.bssid)
                                            .font(.caption.monospaced())
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Text("\(network.rssi) dBm")
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                .frame(minHeight: 44)
                            }
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
        .task { await viewModel.load() }
        .onChange(of: viewModel.filter) { _, _ in
            Task { await viewModel.load() }
        }
    }
}
