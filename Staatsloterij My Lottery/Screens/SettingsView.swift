import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showLogin = false

    var body: some View {
        NavigationStack {
            Form {
                Section(store.t("profile")) {
                    AssetSlotView(name: AppAsset.brandLogoHorizontal.rawValue, mode: .contain)
                        .frame(height: 72)
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(.orange.gradient)
                                .frame(width: 58, height: 58)
                            Text(store.data.profile.initials)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.data.profile.name)
                                .font(.headline)
                            Text(store.data.profile.isGuest ? store.t("guest_account") : store.t("signed_in"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button(store.t("sign_in")) {
                        showLogin = true
                    }
                }

                Section(store.t("language")) {
                    Picker(store.t("language"), selection: Binding(
                        get: { store.data.settings.language },
                        set: {
                            var settings = store.data.settings
                            settings.language = $0
                            store.updateSettings(settings)
                        }
                    )) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.title).tag(language)
                        }
                    }
                }

                Section(store.t("notifications")) {
                    Toggle(store.t("draw_reminder"), isOn: Binding(
                        get: { store.data.settings.drawReminderEnabled },
                        set: {
                            var settings = store.data.settings
                            settings.drawReminderEnabled = $0
                            store.updateSettings(settings)
                        }
                    ))
                }

                Section(store.t("responsible_section")) {
                    Slider(value: Binding(
                        get: { store.data.settings.responsiblePlayLimit },
                        set: {
                            var settings = store.data.settings
                            settings.responsiblePlayLimit = $0
                            store.updateSettings(settings)
                        }
                    ), in: 10...250, step: 5)
                    LabeledContent(store.t("monthly_limit"), value: "€\(store.data.settings.responsiblePlayLimit.formatted(.number.precision(.fractionLength(0))))")
//                    if let helpURL = URL(string: "https://loketkansspel.nl") {
//                        Link(store.t("help_advice"), destination: helpURL)
//                    }
                }

                Section(store.t("security")) {
                    NavigationLink(store.t("change_password")) {
                        PasswordChangeView()
                    }
                }
            }
            .navigationTitle(store.t("settings"))
            .sheet(isPresented: $showLogin) {
                NavigationStack {
                    LoginView()
                }
            }
        }
    }
}

struct LoginView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section(store.t("sign_in")) {
                TextField(store.t("username"), text: $username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                SecureField(store.t("password"), text: $password)
                    .textContentType(.password)
            }
            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "xmark.octagon")
                        .foregroundStyle(.red)
                }
            }
            Section {
                LoadingButton(title: store.t("sign_in"), systemName: "person.crop.circle.badge.checkmark", isLoading: isLoading) {
                    Task { await signIn() }
                }
            }
        }
        .navigationTitle("Account")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(store.t("close")) { dismiss() }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(store.t("done")) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }

    private func signIn() async {
        errorMessage = nil
        isLoading = true
        try? await Task.sleep(for: .seconds(1))
        isLoading = false
        errorMessage = store.t("invalid_login")
    }
}

struct PasswordChangeView: View {
    @EnvironmentObject private var store: AppStore
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var message: String?

    var body: some View {
        Form {
            SecureField(store.t("current_password"), text: $currentPassword)
            SecureField(store.t("new_password"), text: $newPassword)
            if let message {
                Label(message, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
            Button(store.t("change_password_action")) {
                message = store.t("password_unavailable")
            }
        }
        .navigationTitle(store.t("change_password"))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(store.t("done")) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}
