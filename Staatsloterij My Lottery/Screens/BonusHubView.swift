import SwiftUI

struct BonusHubView: View {
    @EnvironmentObject private var store: AppStore
    @State private var activatedBonus: Bonus?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 16) {
                    QRCodeView(text: "staatsloterij://bonus/guest-\(store.data.profile.initials)")
                        .frame(width: 190, height: 190)
                    Text("Show this QR at any licensed retailer or scan online to claim your bonus.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "qrcode")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.black.opacity(0.16), in: Circle())
                        .padding(14)
                        .accessibilityHidden(true)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                HStack {
                    Text(store.t("available_bonuses"))
                        .font(.title3.weight(.bold))
                    Spacer()
                    Label(store.t("active_count"), systemImage: "clock")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.background, in: Capsule())
                }

                ForEach(Bonus.samples) { bonus in
                    BonusRow(
                        bonus: bonus,
                        language: store.language,
                        activateTitle: store.t("activate"),
                        activatedTitle: store.t("activated"),
                        isActivated: store.isBonusActivated(bonus)
                    ) {
                        store.activateBonus(bonus)
                        activatedBonus = bonus
                    }
                }
            }
            .padding()
        }
        .navigationTitle(store.t("bonuses"))
        .alert(store.t("bonus_activated"), isPresented: Binding(
            get: { activatedBonus != nil },
            set: { if !$0 { activatedBonus = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(activatedBonus?.title ?? store.t("bonus")) \(store.t("bonus_linked"))")
        }
    }
}

struct BonusRow: View {
    let bonus: Bonus
    let language: AppLanguage
    let activateTitle: String
    let activatedTitle: String
    let isActivated: Bool
    let action: () -> Void

    var body: some View {
        BrandCard {
            HStack(spacing: 14) {
                Text(bonus.icon)
                    .font(.system(size: 28))
                    .frame(width: 58, height: 58)
                    .background(.orange.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(localizedTitle)
                            .font(.headline)
                            .lineLimit(2)
                        Spacer()
                        Text(bonus.rarity.title(language: language))
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(rarityColor.opacity(0.15), in: Capsule())
                            .foregroundStyle(rarityColor)
                    }
                    Text(localizedSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    HStack {
                        Label(bonus.expiryText, systemImage: "clock")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(isActivated ? activatedTitle : activateTitle) {
                            if !isActivated {
                                action()
                            }
                        }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .tint(isActivated ? .green : .blue)
                            .accessibilityLabel("\(isActivated ? activatedTitle : activateTitle) \(localizedTitle)")
                    }
                }
            }
        }
        .opacity(isActivated ? 0.82 : 1)
    }

    private var rarityColor: Color {
        switch bonus.rarity {
        case .common: .green
        case .rare: .blue
        case .limited: .orange
        case .ultraRare: .red
        }
    }

    private var localizedTitle: String {
        guard language == .english else { return bonus.title }
        switch bonus.title {
        case "Gratis Lot": return "Free Ticket"
        case "Rijksmuseum Pas": return "Rijksmuseum Pass"
        case "Premium Statistieken": return "Premium Statistics"
        case "Café Voucher": return "Cafe Voucher"
        case "Budget Boost": return "Budget Boost"
        case "Gouden Lot Loterij": return "Golden Ticket Raffle"
        default: return bonus.title
        }
    }

    private var localizedSubtitle: String {
        guard language == .english else { return bonus.subtitle }
        switch bonus.title {
        case "Gratis Lot": return "One free entry for the next draw"
        case "Rijksmuseum Pas": return "Free admission for 1 person"
        case "Premium Statistieken": return "Advanced analyses for 30 days"
        case "Café Voucher": return "€5 discount at participating cafes"
        case "Budget Boost": return "20% extra limit for one month"
        case "Gouden Lot Loterij": return "Entry into an exclusive quarterly raffle"
        default: return bonus.subtitle
        }
    }
}
