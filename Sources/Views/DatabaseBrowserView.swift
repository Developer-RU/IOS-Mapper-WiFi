
import SwiftUI
import WiFiMapperCore
struct DatabaseBrowserView: View {
    @StateObject var viewModel: DatabaseBrowserViewModel

    var body: some View {
        ZStack {
            GradientBackdrop()

            ScrollView {
                VStack(spacing: 18) {
                    ScreenHeader(
                        eyebrow: "database.header.eyebrow",
                        title: "database.header.title",
                        subtitle: "database.header.subtitle"
                    )

                    if let exportError = viewModel.exportError {
                        GlassCard {
                            Label(exportError, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("database.filters.title")
                                .font(.headline)

                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                TextField("database.filters.search", text: $viewModel.filter.searchText)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                            Toggle("database.filters.openOnly", isOn: $viewModel.filter.openNetworksOnly)

                            Picker("database.filters.sort", selection: $viewModel.filter.sortOrder) {
                                ForEach(NetworkSortOrder.allCases) { order in
                                    Text(order.localizedTitle).tag(order)
                                }
                            }

                            Picker("database.filters.date", selection: $viewModel.filter.dateScope) {
                                ForEach(HistoryTimeScope.allCases) { scope in
                                    Text(scope.localizedTitle).tag(scope)
                                }
                            }
                            .pickerStyle(.segmented)

                            Stepper("database.filters.minScans \(viewModel.filter.minimumScanCount)", value: $viewModel.filter.minimumScanCount, in: 0 ... 50)

                            Picker("database.filters.channel", selection: $viewModel.filter.selectedChannel) {
                                Text("database.filters.channel.any").tag(Int?.none)
                                ForEach(viewModel.availableChannels, id: \.self) { channel in
                                    Text("\(channel)").tag(Int?.some(channel))
                                }
                            }

                            Button("database.filters.reset") {
                                viewModel.resetFilters()
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("database.savedNetworks.title")
                                .font(.headline)

                            if viewModel.networks.isEmpty {
                                Text("database.savedNetworks.empty")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(viewModel.networks) { network in
                                    HStack(alignment: .top, spacing: 12) {
                                        NavigationLink {
                                            NetworkDetailsView(network: network)
                                        } label: {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(network.ssid)
                                                    .font(.headline)
                                                    .lineLimit(1)
                                                Text(network.bssid)
                                                    .font(.caption.monospaced())
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                                HStack {
                                                    Text(network.security.localizedTitle)
                                                    Text(network.band.localizedTitle)
                                                    Text("\(network.rssi) dBm")
                                                }
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                            }
                                        }
                                        .buttonStyle(.plain)

                                        Spacer()

                                        Button {
                                            Task { await viewModel.delete(networkID: network.id) }
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundStyle(.red)
                                                .padding(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .frame(minHeight: 68)

                                    if network.id != viewModel.networks.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("database.export.title")
                                .font(.headline)

                            HStack(spacing: 10) {
                                ForEach(ExportService.ExportFormat.allCases) { format in
                                    Button(format.rawValue) {
                                        Task { await viewModel.export(format) }
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }

                            if let exportedFileURL = viewModel.exportedFileURL {
                                ShareLink(item: exportedFileURL) {
                                    Label("database.export.share", systemImage: "square.and.arrow.up")
                                }
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
