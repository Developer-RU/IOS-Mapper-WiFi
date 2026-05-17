
import SwiftUI
import WiFiMapperCore
struct NetworkDetailsView: View {
    let network: WiFiNetworkSnapshot

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(network.ssid)
                                .font(.title.bold())
                            Text(network.bssid)
                                .font(.footnote.monospaced())
                                .foregroundStyle(.secondary)
                            Label("networkDetails.lastSeen \(network.lastSeen.formatted(date: .abbreviated, time: .shortened))", systemImage: "clock")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("networkDetails.signalHistory")
                                .font(.headline)
                            SignalHistoryChart(history: network.history)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            detailRow("networkDetails.security", network.security.localizedTitle)
                            detailRow("networkDetails.band", network.band.localizedTitle)
                                detailRow("networkDetails.frequency", network.frequencyMHz.map { "\($0) MHz" } ?? AppStrings.localized("networkDetails.unavailable"))
                                detailRow("networkDetails.channel", network.channel.map(String.init) ?? AppStrings.localized("networkDetails.unavailable"))
                                detailRow("networkDetails.encryption", network.encryption ?? AppStrings.localized("networkDetails.unavailable"))
                                detailRow("networkDetails.captivePortal", network.captivePortalHint ?? AppStrings.localized("networkDetails.notDetected"))
                                detailRow("networkDetails.authHint", network.authenticationHint ?? AppStrings.localized("networkDetails.unavailable"))
                            detailRow("networkDetails.coordinates", "\(network.latitude.formatted(.number.precision(.fractionLength(5)))), \(network.longitude.formatted(.number.precision(.fractionLength(5))))")
                            detailRow("networkDetails.scanCount", String(network.scanCount))
                        }
                    }
                }
                .padding(20)
            }
            .background(GradientBackdrop())
            .navigationTitle("networkDetails.title")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func detailRow(_ title: LocalizedStringKey, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
