import SwiftUI
import UIKit

struct CalculatorView: View {
    @EnvironmentObject private var store: AppStore
    @State private var ticketNumber = ""
    @State private var series = ""
    @State private var drawType: DrawType = .regular
    @State private var period: StatisticsPeriod = .sixty
    @State private var result: CalculationResult?
    @State private var isLoading = false
    @State private var validationMessage: String?
    @State private var exportedURL: URL?
    @State private var exportError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                BrandCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(store.t("calculate_chance"))
                            .font(.title2.weight(.bold))
                        TextField(store.t("ticket_number"), text: $ticketNumber)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        TextField(store.t("series"), text: $series)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        Picker(store.t("draw_type"), selection: $drawType) {
                            ForEach(DrawType.allCases) { type in
                                Text(type.title(language: store.language)).tag(type)
                            }
                        }
                        Picker(store.t("statistics_period"), selection: $period) {
                            ForEach(StatisticsPeriod.allCases) { period in
                                Text(period.title(language: store.language)).tag(period)
                            }
                        }
                        if let validationMessage {
                            Label(validationMessage, systemImage: "exclamationmark.triangle")
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                        LoadingButton(title: store.t("calculate"), systemName: "sparkles", isLoading: isLoading) {
                            Task { await calculate() }
                        }
                    }
                }

                if isLoading {
                    BrandCard {
                        HStack {
                            ProgressView()
                            Text(store.t("calculating"))
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if let result {
                    resultsView(result)
                } else {
                    BrandCard {
                        VStack(spacing: 14) {
                            AssetSlotView(name: AppAsset.calculatorOrb.rawValue, mode: .contain)
                                .frame(height: 120)
                            EmptyStateView(systemName: "chart.pie", title: store.t("no_calculation"), message: store.t("no_calculation_message"))
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(store.t("win_chances"))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(store.t("done")) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .alert(store.t("export_failed"), isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
    }

    private func resultsView(_ result: CalculationResult) -> some View {
        VStack(spacing: 14) {
            BrandCard {
                VStack(alignment: .leading, spacing: 18) {
                    Text(store.t("probability_analysis"))
                        .font(.title3.weight(.bold))
                    DonutChartView(result: result)
                }
            }
            BrandCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text(store.t("prize_ranges"))
                        .font(.title3.weight(.bold))
                    HistogramView(ranges: result.prizeRanges)
                }
            }
            HStack(spacing: 12) {
                MetricTile(title: store.t("expected_value"), value: "€\(result.expectedValue.formatted(.number.precision(.fractionLength(2))))", tint: .orange)
                MetricTile(title: store.t("win_chances"), value: "\(result.winChance.formatted(.number.precision(.fractionLength(2))))%", tint: .green)
            }
            if let exportedURL {
                ShareLink(item: exportedURL) {
                    Label(store.t("share_pdf"), systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    export(result)
                } label: {
                    Label(store.t("export_pdf"), systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
        }
    }

    private func calculate() async {
        let cleanNumber = ticketNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSeries = series.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanNumber.count >= 4 else {
            validationMessage = store.t("valid_ticket_number")
            return
        }
        guard cleanSeries.count >= 2 else {
            validationMessage = store.t("valid_series")
            return
        }

        validationMessage = nil
        exportedURL = nil
        isLoading = true
        let input = CalculationInput(ticketNumber: cleanNumber, series: cleanSeries, drawType: drawType, period: period)
        result = await store.calculate(input: input)
        isLoading = false
    }

    private func export(_ result: CalculationResult) {
        do {
            exportedURL = try ReportExporter.export(result: result)
        } catch {
            exportError = store.t("export_failed_message")
        }
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(tint)
                .monospacedDigit()
                .minimumScaleFactor(0.75)
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
