
import SwiftUI
import WiFiMapperCore
struct MapScreen: View {
    @StateObject var viewModel: MapViewModel

    var body: some View {
        ZStack(alignment: .top) {
            MapViewRepresentable(
                networks: viewModel.displayedNetworks,
                route: viewModel.route,
                selectedStyle: viewModel.selectedStyle,
                activeLayers: viewModel.activeLayers,
                userLocation: viewModel.userLocation,
                selectionHandler: { viewModel.selectedNetwork = $0 }
            )
            .ignoresSafeArea()

            topControls
                .padding(.horizontal, 16)
                .padding(.top, 8)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $viewModel.isFilterSheetPresented) {
            MapFilterSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $viewModel.selectedNetwork) { network in
            NetworkDetailsView(network: network)
        }
        .task { viewModel.load() }
    }

    private var topControls: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("map.header.title")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("map.header.subtitle")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.82))
                }
                Spacer()
            }
            .padding(16)
            .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            if viewModel.isDemoMode {
                DemoModeBanner(subtitle: AppStrings.localized("map.demo.subtitle"))
            }

            ExternalScannerStatusBanner()

            HStack(spacing: 12) {
                Picker("map.style.picker", selection: $viewModel.selectedStyle) {
                    ForEach(MapPresentationStyle.allCases) { style in
                        Text(style.localizedTitle).tag(style)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    viewModel.isFilterSheetPresented = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MapLayer.allCases) { layer in
                        let enabled = viewModel.activeLayers.contains(layer)
                        Button(layer.localizedTitle) {
                            if enabled {
                                viewModel.activeLayers.remove(layer)
                            } else {
                                viewModel.activeLayers.insert(layer)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(enabled ? .blue : .gray)
                    }
                }
            }
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

struct MapFilterSheet: View {
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("map.filter.search") {
                    TextField("map.filter.search.placeholder", text: $viewModel.filter.searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("map.filter.signal") {
                    Slider(value: Binding(
                        get: { Double(viewModel.filter.minimumRSSI) },
                        set: { viewModel.filter.minimumRSSI = Int($0) }
                    ), in: -100 ... -30, step: 1)
                    Text("map.filter.minRssi \(viewModel.filter.minimumRSSI)")

                    Picker("map.filter.channel", selection: Binding(
                        get: { viewModel.filter.selectedChannel },
                        set: { viewModel.filter.selectedChannel = $0 }
                    )) {
                        Text("map.filter.channel.any").tag(Int?.none)
                        ForEach(viewModel.availableChannels, id: \.self) { channel in
                            Text("\(channel)").tag(Int?.some(channel))
                        }
                    }
                }

                Section("map.filter.bands") {
                    ForEach(WiFiBand.allCases) { band in
                        Toggle(band.localizedTitle, isOn: Binding(
                            get: { viewModel.filter.bands.contains(band) },
                            set: { enabled in
                                if enabled { viewModel.filter.bands.insert(band) } else { viewModel.filter.bands.remove(band) }
                            }
                        ))
                    }
                }

                Section("map.filter.security") {
                    ForEach(WiFiSecurity.allCases) { security in
                        Toggle(security.localizedTitle, isOn: Binding(
                            get: { viewModel.filter.securityTypes.contains(security) },
                            set: { enabled in
                                if enabled { viewModel.filter.securityTypes.insert(security) } else { viewModel.filter.securityTypes.remove(security) }
                            }
                        ))
                    }
                    Toggle("map.filter.openOnly", isOn: $viewModel.filter.openNetworksOnly)
                }
            }
            .navigationTitle("map.filter.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("map.filter.reset") {
                        viewModel.resetFilters()
                    }
                }
            }
        }
    }
}
