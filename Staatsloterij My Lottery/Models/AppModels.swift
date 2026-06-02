import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case dutch
    case english

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dutch: "Nederlands"
        case .english: "English"
        }
    }
}

enum TicketStatus: String, Codable, CaseIterable, Identifiable {
    case active
    case checked
    case won
    case lost

    var id: String { rawValue }

    var title: String {
        title(language: .dutch)
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .active: language == .dutch ? "Actief" : "Active"
        case .checked: language == .dutch ? "Gecontroleerd" : "Checked"
        case .won: language == .dutch ? "Gewonnen" : "Won"
        case .lost: language == .dutch ? "Geen prijs" : "No prize"
        }
    }
}

enum DrawType: String, Codable, CaseIterable, Identifiable {
    case regular
    case holiday

    var id: String { rawValue }

    var title: String {
        title(language: .dutch)
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .regular: language == .dutch ? "Normaal" : "Regular"
        case .holiday: language == .dutch ? "Feesttrekking" : "Holiday draw"
        }
    }
}

enum StatisticsPeriod: Int, Codable, CaseIterable, Identifiable {
    case twelve = 12
    case thirtySix = 36
    case sixty = 60

    var id: Int { rawValue }
    var title: String { "Laatste \(rawValue) maanden" }

    func title(language: AppLanguage) -> String {
        language == .dutch ? "Laatste \(rawValue) maanden" : "Last \(rawValue) months"
    }
}

enum BonusRarity: String, Codable {
    case common
    case rare
    case limited
    case ultraRare

    var title: String {
        title(language: .dutch)
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .common: language == .dutch ? "Gewoon" : "Common"
        case .rare: language == .dutch ? "Zeldzaam" : "Rare"
        case .limited: language == .dutch ? "Beperkt" : "Limited"
        case .ultraRare: language == .dutch ? "Ultra zeldzaam" : "Ultra rare"
        }
    }
}

struct UserProfile: Codable, Equatable {
    var name: String
    var initials: String
    var isGuest: Bool

    static let guest = UserProfile(name: "Guest", initials: "G", isGuest: true)
}

struct AppSettings: Codable, Equatable {
    var drawReminderEnabled: Bool
    var responsiblePlayLimit: Double
    var language: AppLanguage

    static let `default` = AppSettings(drawReminderEnabled: false, responsiblePlayLimit: 60, language: .dutch)

    enum CodingKeys: String, CodingKey {
        case drawReminderEnabled
        case responsiblePlayLimit
        case language
    }

    init(drawReminderEnabled: Bool, responsiblePlayLimit: Double, language: AppLanguage) {
        self.drawReminderEnabled = drawReminderEnabled
        self.responsiblePlayLimit = responsiblePlayLimit
        self.language = language
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        drawReminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .drawReminderEnabled) ?? Self.default.drawReminderEnabled
        responsiblePlayLimit = try container.decodeIfPresent(Double.self, forKey: .responsiblePlayLimit) ?? Self.default.responsiblePlayLimit
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? Self.default.language
    }
}

struct LotteryTicket: Identifiable, Codable, Equatable {
    var id: UUID
    var number: String
    var series: String
    var drawDate: Date
    var status: TicketStatus
    var prizeAmount: Double?
    var note: String

    var formattedDrawDate: String {
        drawDate.formatted(date: .abbreviated, time: .omitted)
    }

    static let sample = LotteryTicket(
        id: UUID(),
        number: "123456",
        series: "452",
        drawDate: Calendar.current.date(byAdding: .day, value: 9, to: .now) ?? .now,
        status: .active,
        prizeAmount: nil,
        note: "Gastlot voor de volgende trekking"
    )
}

struct CalculationInput: Codable, Hashable {
    var ticketNumber: String
    var series: String
    var drawType: DrawType
    var period: StatisticsPeriod
}

struct CalculationResult: Identifiable, Codable, Equatable {
    var id: UUID
    var input: CalculationInput
    var winChance: Double
    var noPrizeChance: Double
    var jackpotChance: Double
    var expectedValue: Double
    var prizeRanges: [PrizeRange]
    var createdAt: Date

    static func == (lhs: CalculationResult, rhs: CalculationResult) -> Bool {
        lhs.id == rhs.id
    }
}

struct PrizeRange: Identifiable, Codable, Equatable {
    var id: UUID
    var label: String
    var chance: Double
}

struct Bonus: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var subtitle: String
    var icon: String
    var rarity: BonusRarity
    var expiryText: String
    var tintName: String

    static let samples: [Bonus] = [
        Bonus(id: "free_ticket", title: "Gratis Lot", subtitle: "Een gratis deelname voor de volgende trekking", icon: "🎫", rarity: .common, expiryText: "48u over", tintName: "green"),
        Bonus(id: "rijksmuseum_pass", title: "Rijksmuseum Pas", subtitle: "Gratis toegang voor 1 persoon", icon: "🎨", rarity: .rare, expiryText: "7d over", tintName: "blue"),
        Bonus(id: "premium_statistics", title: "Premium Statistieken", subtitle: "Geavanceerde analyses voor 30 dagen", icon: "📊", rarity: .limited, expiryText: "14d over", tintName: "blue"),
        Bonus(id: "cafe_voucher", title: "Café Voucher", subtitle: "€5 korting bij deelnemende cafés", icon: "☕", rarity: .common, expiryText: "30d over", tintName: "green"),
        Bonus(id: "budget_boost", title: "Budget Boost", subtitle: "20% extra limiet voor één maand", icon: "💰", rarity: .limited, expiryText: "5d over", tintName: "orange"),
        Bonus(id: "golden_ticket_raffle", title: "Gouden Lot Loterij", subtitle: "Deelname aan exclusieve kwartaalraffle", icon: "🏆", rarity: .ultraRare, expiryText: "2d over", tintName: "red")
    ]
}

struct JackpotEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var amount: Double
}

struct AppData: Codable {
    var profile: UserProfile
    var settings: AppSettings
    var tickets: [LotteryTicket]
    var results: [CalculationResult]
    var jackpotEntries: [JackpotEntry]
    var activatedBonusIDs: Set<String>

    static let initial = AppData(
        profile: .guest,
        settings: .default,
        tickets: [.sample],
        results: [],
        jackpotEntries: [],
        activatedBonusIDs: []
    )

    enum CodingKeys: String, CodingKey {
        case profile
        case settings
        case tickets
        case results
        case jackpotEntries
        case activatedBonusIDs
    }

    init(profile: UserProfile, settings: AppSettings, tickets: [LotteryTicket], results: [CalculationResult], jackpotEntries: [JackpotEntry], activatedBonusIDs: Set<String>) {
        self.profile = profile
        self.settings = settings
        self.tickets = tickets
        self.results = results
        self.jackpotEntries = jackpotEntries
        self.activatedBonusIDs = activatedBonusIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profile = try container.decodeIfPresent(UserProfile.self, forKey: .profile) ?? Self.initial.profile
        settings = try container.decodeIfPresent(AppSettings.self, forKey: .settings) ?? Self.initial.settings
        tickets = try container.decodeIfPresent([LotteryTicket].self, forKey: .tickets) ?? Self.initial.tickets
        results = try container.decodeIfPresent([CalculationResult].self, forKey: .results) ?? Self.initial.results
        jackpotEntries = try container.decodeIfPresent([JackpotEntry].self, forKey: .jackpotEntries) ?? Self.initial.jackpotEntries
        activatedBonusIDs = try container.decodeIfPresent(Set<String>.self, forKey: .activatedBonusIDs) ?? Self.initial.activatedBonusIDs
    }
}
