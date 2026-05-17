
import SwiftUI
import WiFiMapperCore
struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel

    private func readinessRow(_ titleKey: LocalizedStringKey, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(titleKey)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 210, alignment: .trailing)
        }
    }

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

                    ExternalScannerStatusBanner()

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("scanner.source.title")
                                .font(.headline)
                            Picker("scanner.source.picker", selection: Binding(
                                get: { viewModel.settings.inputSource },
                                set: { newValue in viewModel.update { $0.inputSource = newValue } }
                            )) {
                                ForEach(ScannerInputSource.allCases) { source in
                                    Text(source.localizedTitle).tag(source)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    if viewModel.settings.inputSource == .externalScanner {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("external.scanner.title")
                                    .font(.headline)

                                Text("external.scanner.manualConnectHint")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                TextField("external.scanner.host", text: Binding(
                                    get: { viewModel.settings.externalScanner.host },
                                    set: { value in viewModel.update { $0.externalScanner.host = value } }
                                ))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                                Stepper("external.scanner.port \(viewModel.settings.externalScanner.port)", value: Binding(
                                    get: { viewModel.settings.externalScanner.port },
                                    set: { value in viewModel.update { $0.externalScanner.port = value } }
                                ), in: 1 ... 65_535)

                                Stepper("external.scanner.maxResults \(viewModel.settings.externalScanner.maxResults)", value: Binding(
                                    get: { viewModel.settings.externalScanner.maxResults },
                                    set: { value in viewModel.update { $0.externalScanner.maxResults = value } }
                                ), in: 10 ... 500)

                                Stepper("external.scanner.timeout \(Int(viewModel.settings.externalScanner.scanTimeoutSeconds))", value: Binding(
                                    get: { Int(viewModel.settings.externalScanner.scanTimeoutSeconds) },
                                    set: { value in viewModel.update { $0.externalScanner.scanTimeoutSeconds = Double(value) } }
                                ), in: 3 ... 60)

                                if let lastError = viewModel.externalScannerStatus.lastErrorMessage {
                                    Text(lastError)
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                        .lineLimit(2)
                                }
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("external.scanner.info.title")
                                    .font(.headline)

                                LabeledContent("external.scanner.info.serial", value: viewModel.externalScannerStatus.deviceID)
                                LabeledContent("external.scanner.info.firmware", value: viewModel.externalScannerStatus.firmware)
                                LabeledContent("external.scanner.info.networkTypes", value: viewModel.externalScannerStatus.scanNetworkTypes)
                            }
                        }
                    }

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
                            readinessRow("settings.readiness.buildTarget", AppStrings.localized("settings.readiness.buildTarget.value"))
                            readinessRow("settings.readiness.locationMode", AppStrings.localized("settings.readiness.locationMode.value"))
                            readinessRow("settings.readiness.localNetwork", AppStrings.localized("settings.readiness.localNetwork.value"))
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
