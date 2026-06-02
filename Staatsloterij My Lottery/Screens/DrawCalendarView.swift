import SwiftUI
import UIKit

struct DrawCalendarView: View {
    @EnvironmentObject private var store: AppStore
    @State private var visibleMonth = Calendar.current.startOfMonth(for: .now)
    @State private var jackpotDate: Date?
    @State private var jackpotAmount = 0.0

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                monthHeader
                calendarGrid
                legend
            }
            .padding()
        }
        .navigationTitle(store.t("calendar"))
        .sheet(isPresented: Binding(
            get: { jackpotDate != nil },
            set: { if !$0 { jackpotDate = nil } }
        )) {
            NavigationStack {
                Form {
                    Section("\(store.t("jackpot_for")) \((jackpotDate ?? .now).formatted(date: .abbreviated, time: .omitted))") {
                        TextField(store.t("amount"), value: $jackpotAmount, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
                .navigationTitle("Jackpot")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(store.t("cancel")) { jackpotDate = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(store.t("save")) {
                            if let jackpotDate {
                                store.upsertJackpot(date: jackpotDate, amount: jackpotAmount)
                            }
                            jackpotDate = nil
                        }
                        .disabled(jackpotAmount <= 0)
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(store.t("done")) {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                visibleMonth = Calendar.current.date(byAdding: .month, value: -1, to: visibleMonth) ?? visibleMonth
            } label: {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel(store.t("previous_month"))
            Spacer()
            Text(visibleMonth.formatted(.dateTime.month(.wide).year()))
                .font(.title3.weight(.bold))
            Spacer()
            Button {
                visibleMonth = Calendar.current.date(byAdding: .month, value: 1, to: visibleMonth) ?? visibleMonth
            } label: {
                Image(systemName: "chevron.right")
            }
            .accessibilityLabel(store.t("next_month"))
        }
        .buttonStyle(.bordered)
    }

    private var calendarGrid: some View {
        let days = Calendar.current.monthGrid(for: visibleMonth)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(Calendar.current.veryShortWeekdaySymbols, id: \.self) { day in
                Text(day)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            ForEach(days, id: \.self) { date in
                CalendarDayCell(
                    date: date,
                    visibleMonth: visibleMonth,
                    jackpot: jackpotAmount(for: date)
                ) {
                    if Calendar.current.component(.day, from: date) == 10 {
                        jackpotAmount = jackpotAmount(for: date) ?? 0
                        jackpotDate = Calendar.current.startOfDay(for: date)
                    }
                }
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    private var legend: some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 10) {
                Label(store.t("future_draw"), systemImage: "circle.fill")
                    .foregroundStyle(.blue)
                Label(store.t("past_draw"), systemImage: "circle.fill")
                    .foregroundStyle(.green)
                Text(store.t("calendar_hint"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
    }

    private func jackpotAmount(for date: Date) -> Double? {
        store.data.jackpotEntries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }?.amount
    }
}

struct CalendarDayCell: View {
    let date: Date
    let visibleMonth: Date
    let jackpot: Double?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.subheadline.weight(isDrawDay ? .bold : .regular))
                    .monospacedDigit()
                if let jackpot {
                    Text("€\(jackpot.formatted(.number.notation(.compactName)))")
                        .font(.caption2.weight(.bold))
                        .minimumScaleFactor(0.65)
                        .lineLimit(1)
                } else if isDrawDay {
                    Circle()
                        .fill(isPast ? .green : .blue)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 54)
            .frame(maxWidth: .infinity)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .foregroundStyle(isCurrentMonth ? Color.primary : Color.secondary.opacity(0.45))
        }
        .buttonStyle(.plain)
        .disabled(!isDrawDay)
        .accessibilityLabel(accessibilityText)
    }

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(date, equalTo: visibleMonth, toGranularity: .month)
    }

    private var isDrawDay: Bool {
        Calendar.current.component(.day, from: date) == 10 && isCurrentMonth
    }

    private var isPast: Bool {
        date < Calendar.current.startOfDay(for: .now)
    }

    private var backgroundColor: Color {
        guard isDrawDay else { return .clear }
        if jackpot != nil { return .green.opacity(0.16) }
        return (isPast ? Color.green : Color.blue).opacity(0.12)
    }

    private var accessibilityText: String {
        if isDrawDay {
            return "Trekking op \(date.formatted(date: .abbreviated, time: .omitted))"
        }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }

    func monthGrid(for date: Date) -> [Date] {
        let start = startOfMonth(for: date)
        let weekday = component(.weekday, from: start)
        let leadingDays = (weekday - firstWeekday + 7) % 7
        let gridStart = self.date(byAdding: .day, value: -leadingDays, to: start) ?? start
        return (0..<42).compactMap { self.date(byAdding: .day, value: $0, to: gridStart) }
    }
}
