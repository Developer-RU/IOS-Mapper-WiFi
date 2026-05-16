
import SwiftUI
import WiFiMapperCore
struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel

    var body: some View {
        ZStack {
            GradientBackdrop()

            ScrollView {
                VStack(spacing: 18) {
                    ScreenHeader(
                        eyebrow: "settings.header.eyebrow",
                        title: "settings.header.title",
                        subtitle: "settings.header.subtitle"
                    )

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("settings.appearance.title")
                                .font(.headline)
                            Picker("settings.appearance.picker", selection: Binding(
                                get: { viewModel.appearance },
                                set: { newValue in viewModel.setAppearance(newValue) }
                            )) {
                                ForEach(AppAppearance.allCases) { appearance in
                                    Text(appearance.title).tag(appearance)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("settings.language.title")
                                .font(.headline)
                            Picker("settings.language.picker", selection: Binding(
                                get: { viewModel.language },
                                set: { newValue in viewModel.setLanguage(newValue) }
                            )) {
                                ForEach(AppLanguage.allCases) { language in
                                    Text(language.title).tag(language)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("settings.textSize.title")
                                .font(.headline)
                            Picker("settings.textSize.picker", selection: Binding(
                                get: { viewModel.textSize },
                                set: { newValue in viewModel.setTextSize(newValue) }
                            )) {
                                ForEach(AppTextSize.allCases) { size in
                                    Text(size.title).tag(size)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("settings.scanInterval.title")
                                .font(.headline)
                            Picker("settings.scanInterval.mode", selection: Binding(
                                get: { viewModel.settings.mode },
                                set: { newValue in viewModel.update { $0.mode = newValue } }
                            )) {
                                ForEach(ScannerMode.allCases) { mode in
                                    Text(mode.localizedTitle).tag(mode)
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("settings.performance.title")
                                .font(.headline)
                            Toggle("settings.performance.aggressive", isOn: Binding(
                                get: { viewModel.settings.aggressiveScanning },
                                set: { value in viewModel.update { $0.aggressiveScanning = value } }
                            ))
                            Toggle("settings.performance.batterySaver", isOn: Binding(
                                get: { viewModel.settings.batterySaver },
                                set: { value in viewModel.update { $0.batterySaver = value } }
                            ))
                            Toggle("settings.performance.highAccuracyGps", isOn: Binding(
                                get: { viewModel.settings.highAccuracyGPS },
                                set: { value in viewModel.update { $0.highAccuracyGPS = value } }
                            ))
                            Toggle("settings.performance.backgroundScanning", isOn: Binding(
                                get: { viewModel.settings.backgroundScanningEnabled },
                                set: { value in viewModel.update { $0.backgroundScanningEnabled = value } }
                            ))
                            Toggle("settings.performance.autoSave", isOn: Binding(
                                get: { viewModel.settings.autoSave },
                                set: { value in viewModel.update { $0.autoSave = value } }
                            ))
                            Toggle("settings.performance.demoMode", isOn: Binding(
                                get: { viewModel.settings.demoModeEnabled },
                                set: { value in viewModel.update { $0.demoModeEnabled = value } }
                            ))
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("settings.quality.title")
                                .font(.headline)
                            Stepper("settings.quality.repeatedChecks \(viewModel.settings.repeatedChecks)", value: Binding(
                                get: { viewModel.settings.repeatedChecks },
                                set: { value in viewModel.update { $0.repeatedChecks = value } }
                            ), in: 1 ... 6)
                            Stepper("settings.quality.retryCount \(viewModel.settings.retryCount)", value: Binding(
                                get: { viewModel.settings.retryCount },
                                set: { value in viewModel.update { $0.retryCount = value } }
                            ), in: 0 ... 6)
                            Stepper("settings.quality.signalThreshold \(viewModel.settings.signalThreshold)", value: Binding(
                                get: { viewModel.settings.signalThreshold },
                                set: { value in viewModel.update { $0.signalThreshold = value } }
                            ), in: -100 ... -40)
                            Toggle("settings.quality.ignoreWeak", isOn: Binding(
                                get: { viewModel.settings.ignoreWeakNetworks },
                                set: { value in viewModel.update { $0.ignoreWeakNetworks = value } }
                            ))
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("settings.readiness.title")
                                .font(.headline)
                            LabeledContent("settings.readiness.buildTarget", value: String(localized: "settings.readiness.buildTarget.value"))
                            LabeledContent("settings.readiness.locationMode", value: String(localized: "settings.readiness.locationMode.value"))
                            LabeledContent("settings.readiness.localNetwork", value: String(localized: "settings.readiness.localNetwork.value"))
                            Text("settings.readiness.note")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("settings.demoData.title")
                                .font(.headline)
                            Button("settings.demoData.generate") {
                                viewModel.seedDemoData()
                            }
                            .buttonStyle(.borderedProminent)
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
    }
}
