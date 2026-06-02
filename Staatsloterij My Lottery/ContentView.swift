import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppStore()

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label(store.t("overview"), systemImage: "house.fill")
                }

            NavigationStack {
                TicketsView()
            }
            .tabItem {
                Label(store.t("tickets"), systemImage: "ticket.fill")
            }

            NavigationStack {
                CalculatorView()
            }
            .tabItem {
                Label(store.t("chance"), systemImage: "chart.pie.fill")
            }

            NavigationStack {
                BonusHubView()
            }
            .tabItem {
                Label(store.t("bonus"), systemImage: "gift.fill")
            }

            SettingsView()
                .tabItem {
                    Label(store.t("profile"), systemImage: "person.crop.circle")
                }
        }
        .environmentObject(store)
    }
}

#Preview {
    ContentView()
}
