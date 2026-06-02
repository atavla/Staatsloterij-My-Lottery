import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    welcomeBanner
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        NavigationLink(value: HomeRoute.tickets) {
                            DashboardTile(title: store.t("my_tickets"), emoji: "🎫", tint: .orange)
                        }
                        NavigationLink(value: HomeRoute.calculator) {
                            DashboardTile(title: store.t("win_chances"), emoji: "🎯", tint: .green)
                        }
                        NavigationLink(value: HomeRoute.calendar) {
                            DashboardTile(title: store.t("calendar"), emoji: "📅", tint: .blue)
                        }
                        NavigationLink(value: HomeRoute.bonuses) {
                            DashboardTile(title: store.t("bonuses"), emoji: "🎁", tint: .purple)
                        }
                    }
                    responsiblePlayNotice
                }
                .padding()
            }
            .navigationTitle(store.t("overview"))
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .tickets: TicketsView()
                case .calculator: CalculatorView()
                case .calendar: DrawCalendarView()
                case .bonuses: BonusHubView()
                }
            }
        }
    }

    private var welcomeBanner: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.orange.gradient)
                    .frame(width: 62, height: 62)
                    .shadow(color: .orange.opacity(0.35), radius: 8, y: 4)
                Text(store.data.profile.initials)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(store.t("hi")) \(store.data.profile.name)! 👋")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(store.t("welcome_today"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))
            }
            Spacer()
        }
        .padding(18)
        .background {
            LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var responsiblePlayNotice: some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 8) {
                Label(store.t("responsible_play"), systemImage: "shield.lefthalf.filled")
                    .font(.headline)
                Text(store.t("responsible_notice"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

enum HomeRoute: Hashable {
    case tickets
    case calculator
    case calendar
    case bonuses
}

struct DashboardTile: View {
    let title: String
    let emoji: String
    let tint: Color

    var body: some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 18) {
                Text(emoji)
                    .font(.system(size: 28))
                    .frame(width: 54, height: 54)
                    .background(tint.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(minHeight: 112, alignment: .leading)
        }
    }
}
