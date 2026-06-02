import Foundation
import UIKit
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var data: AppData
    @Published var lastErrorMessage: String?

    private let fileURL: URL

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let appDirectory = directory.appendingPathComponent("StaatsloterijMyLottery", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        fileURL = appDirectory.appendingPathComponent("app-data.json")
        data = Self.load(from: fileURL)
    }

    func save() {
        do {
            let encoded = try JSONEncoder.appEncoder.encode(data)
            try encoded.write(to: fileURL, options: [.atomic])
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "Gegevens konden niet worden opgeslagen. Probeer het opnieuw."
        }
    }

    func updateProfile(_ profile: UserProfile) {
        data.profile = profile
        save()
    }

    func updateSettings(_ settings: AppSettings) {
        data.settings = settings
        save()
    }

    func addTicket(_ ticket: LotteryTicket) {
        data.tickets.insert(ticket, at: 0)
        save()
    }

    func updateTicket(_ ticket: LotteryTicket) {
        guard let index = data.tickets.firstIndex(where: { $0.id == ticket.id }) else { return }
        data.tickets[index] = ticket
        save()
    }

    func deleteTicket(_ ticket: LotteryTicket) {
        data.tickets.removeAll { $0.id == ticket.id }
        save()
    }

    func result(for input: CalculationInput) -> CalculationResult? {
        data.results.first { $0.input == input }
    }

    func calculate(input: CalculationInput) async -> CalculationResult {
        if let existing = result(for: input) {
            try? await Task.sleep(for: .milliseconds(550))
            return existing
        }

        try? await Task.sleep(for: .seconds(1))
        let result = CalculationEngine.makeResult(for: input)
        data.results.insert(result, at: 0)
        save()
        return result
    }

    func upsertJackpot(date: Date, amount: Double) {
        let day = Calendar.current.startOfDay(for: date)
        if let index = data.jackpotEntries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) {
            data.jackpotEntries[index].amount = amount
        } else {
            data.jackpotEntries.append(JackpotEntry(id: UUID(), date: day, amount: amount))
        }
        save()
    }

    func activateBonus(_ bonus: Bonus) {
        data.activatedBonusIDs.insert(bonus.id)
        save()
    }

    func isBonusActivated(_ bonus: Bonus) -> Bool {
        data.activatedBonusIDs.contains(bonus.id)
    }

    private static func load(from url: URL) -> AppData {
        do {
            let data = try Data(contentsOf: url)
            var decoded = try JSONDecoder.appDecoder.decode(AppData.self, from: data)
            if decoded.profile.isGuest {
                decoded.profile = .guest
            }
            return decoded
        } catch {
            return .initial
        }
    }
}

enum CalculationEngine {
    static func makeResult(for input: CalculationInput) -> CalculationResult {
        let seed = stableSeed(input.ticketNumber + input.series + input.drawType.rawValue + "\(input.period.rawValue)")
        let winChance = rounded(42.01 + Double(seed % 1798) / 100)
        let jackpotChance = rounded(0.001 + Double((seed / 7) % 9) / 1000, places: 3)
        let noPrizeChance = max(0, rounded(100 - winChance - jackpotChance))
        let expectedValue = rounded(5 + Double((seed / 17) % 950) / 100)

        let first = rounded(40 + Double((seed / 3) % 1001) / 100)
        let second = rounded(2 + Double((seed / 5) % 301) / 100)
        let third = rounded(0.1 + Double((seed / 11) % 61) / 100)
        let fourth = rounded(0.05 + Double((seed / 13) % 6) / 100)
        let jackpot = 0.00001

        return CalculationResult(
            id: UUID(),
            input: input,
            winChance: winChance,
            noPrizeChance: noPrizeChance,
            jackpotChance: jackpotChance,
            expectedValue: expectedValue,
            prizeRanges: [
                PrizeRange(id: UUID(), label: "€5-25", chance: first),
                PrizeRange(id: UUID(), label: "€25-100", chance: second),
                PrizeRange(id: UUID(), label: "€100-1k", chance: third),
                PrizeRange(id: UUID(), label: "€1k+", chance: fourth),
                PrizeRange(id: UUID(), label: "Jackpot", chance: jackpot)
            ],
            createdAt: .now
        )
    }

    private static func stableSeed(_ text: String) -> UInt64 {
        text.utf8.reduce(14_695_981_039_346_656_037) { ($0 ^ UInt64($1)) &* 1_099_511_628_211 }
    }

    private static func rounded(_ value: Double, places: Int = 2) -> Double {
        let scale = pow(10, Double(places))
        return (value * scale).rounded() / scale
    }
}

enum ReportExporter {
    static func export(result: CalculationResult) throws -> URL {
        let page = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("staatsloterij-rapport-\(result.input.ticketNumber)-\(result.input.series).pdf")

        try renderer.writePDF(to: url) { context in
            context.beginPage()
            let title = "Staatsloterij My Lottery"
            let subtitle = "Kansrapport"
            draw(title, at: CGPoint(x: 48, y: 54), font: .boldSystemFont(ofSize: 28))
            draw(subtitle, at: CGPoint(x: 48, y: 92), font: .systemFont(ofSize: 18), color: .darkGray)
            draw("Lotnummer: \(result.input.ticketNumber)", at: CGPoint(x: 48, y: 145))
            draw("Serie: \(result.input.series)", at: CGPoint(x: 48, y: 173))
            draw("Trekking: \(result.input.drawType.title)", at: CGPoint(x: 48, y: 201))
            draw("Periode: \(result.input.period.title)", at: CGPoint(x: 48, y: 229))
            draw("Winkans: \(result.winChance.formatted(.number.precision(.fractionLength(2))))%", at: CGPoint(x: 48, y: 290), font: .boldSystemFont(ofSize: 18), color: .systemGreen)
            draw("Geen prijs: \(result.noPrizeChance.formatted(.number.precision(.fractionLength(2))))%", at: CGPoint(x: 48, y: 325), font: .boldSystemFont(ofSize: 18), color: .systemRed)
            draw("Jackpot: \(result.jackpotChance.formatted(.number.precision(.fractionLength(3))))%", at: CGPoint(x: 48, y: 360), font: .boldSystemFont(ofSize: 18), color: .systemOrange)
            draw("Verwachte waarde: €\(result.expectedValue.formatted(.number.precision(.fractionLength(2))))", at: CGPoint(x: 48, y: 410), font: .boldSystemFont(ofSize: 20))
            draw("Deze berekening toont statistische trends en is geen garantie op winst. Elke trekking is onafhankelijk.", at: CGPoint(x: 48, y: 690), font: .systemFont(ofSize: 12), color: .darkGray, width: 500)
        }

        return url
    }

    private static func draw(_ text: String, at point: CGPoint, font: UIFont = .systemFont(ofSize: 15), color: UIColor = .black, width: CGFloat = 420) {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        text.draw(in: CGRect(x: point.x, y: point.y, width: width, height: 90), withAttributes: attributes)
    }
}

extension JSONEncoder {
    static var appEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var appDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
