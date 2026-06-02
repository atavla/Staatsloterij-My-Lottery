import SwiftUI

struct DonutChartView: View {
    let result: CalculationResult

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                DonutSlice(start: .degrees(-90), end: .degrees(-90 + result.winChance * 3.6))
                    .stroke(.green, style: StrokeStyle(lineWidth: 22, lineCap: .butt))
                DonutSlice(start: .degrees(-90 + result.winChance * 3.6), end: .degrees(-90 + (result.winChance + result.noPrizeChance) * 3.6))
                    .stroke(.red, style: StrokeStyle(lineWidth: 22, lineCap: .butt))
                DonutSlice(start: .degrees(-90 + (result.winChance + result.noPrizeChance) * 3.6), end: .degrees(270))
                    .stroke(.orange, style: StrokeStyle(lineWidth: 22, lineCap: .butt))
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundStyle(.blue)
            }
            .frame(width: 160, height: 160)

            VStack(spacing: 10) {
                LegendRow(color: .green, title: "Winkans", value: result.winChance, precision: 2)
                LegendRow(color: .red, title: "Geen prijs", value: result.noPrizeChance, precision: 2)
                LegendRow(color: .orange, title: "Jackpot", value: result.jackpotChance, precision: 3)
            }
        }
    }
}

private struct DonutSlice: Shape {
    let start: Angle
    let end: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: min(rect.width, rect.height) / 2, startAngle: start, endAngle: end, clockwise: false)
        return path
    }
}

private struct LegendRow: View {
    let color: Color
    let title: String
    let value: Double
    let precision: Int

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 14, height: 14)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text("\(value.formatted(.number.precision(.fractionLength(precision))))%")
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct HistogramView: View {
    let ranges: [PrizeRange]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(ranges) { range in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(color(for: range))
                            .frame(height: barHeight(for: range))
                        Text(range.label)
                            .font(.caption2)
                            .minimumScaleFactor(0.65)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 180)
        }
    }

    private func barHeight(for range: PrizeRange) -> CGFloat {
        let maxChance = ranges.map(\.chance).max() ?? 1
        return max(8, CGFloat(range.chance / maxChance) * 150)
    }

    private func color(for range: PrizeRange) -> Color {
        switch range.label {
        case "€5-25": .orange
        case "€25-100": .green
        case "€100-1k": .yellow
        case "€1k+": .purple
        default: .red
        }
    }
}
