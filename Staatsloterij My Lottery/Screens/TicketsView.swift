import SwiftUI
import UIKit

struct TicketsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showAddTicket = false
    @State private var ticketToDelete: LotteryTicket?
    @State private var scannerSource: SourceBox?
    @State private var showScanFailure = false

    var body: some View {
        List {
            if store.data.tickets.isEmpty {
                EmptyStateView(systemName: "ticket", title: store.t("no_tickets"), message: store.t("no_tickets_message"))
                    .listRowBackground(Color.clear)
            } else {
                ForEach(store.data.tickets) { ticket in
                    NavigationLink {
                        TicketDetailView(ticket: ticket)
                    } label: {
                        TicketRow(ticket: ticket)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            ticketToDelete = ticket
                        } label: {
                            Label(store.t("delete"), systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle(store.t("my_tickets"))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            scannerSource = SourceBox(sourceType: .camera)
                        } else {
                            showScanFailure = true
                        }
                    } label: {
                        Label(store.t("camera"), systemImage: "camera")
                    }
                    Button {
                        scannerSource = SourceBox(sourceType: .photoLibrary)
                    } label: {
                        Label(store.t("gallery"), systemImage: "photo")
                    }
                } label: {
                    Image(systemName: "camera.viewfinder")
                }
                .accessibilityLabel(store.t("scan_ticket"))

                Button {
                    showAddTicket = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(store.t("add_ticket"))
            }
        }
        .sheet(isPresented: $showAddTicket) {
            NavigationStack {
                TicketFormView()
            }
        }
        .sheet(item: $scannerSource) { source in
            ImagePicker(sourceType: source.sourceType) {
                scannerSource = nil
                showScanFailure = true
            }
        }
        .alert(store.t("ticket_not_recognized"), isPresented: $showScanFailure) {
            Button(store.t("manual_add")) {
                showAddTicket = true
            }
            Button(store.t("close"), role: .cancel) {}
        } message: {
            Text(store.t("ticket_not_recognized_message"))
        }
        .confirmationDialog(store.t("delete_ticket_question"), isPresented: Binding(
            get: { ticketToDelete != nil },
            set: { if !$0 { ticketToDelete = nil } }
        ), titleVisibility: .visible) {
            Button(store.t("delete_ticket"), role: .destructive) {
                if let ticketToDelete {
                    store.deleteTicket(ticketToDelete)
                }
            }
            Button(store.t("cancel"), role: .cancel) {}
        }
    }
}

struct TicketRow: View {
    @EnvironmentObject private var store: AppStore
    let ticket: LotteryTicket

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(ticket.number)
                    .font(.system(.title3, design: .monospaced, weight: .bold))
                Spacer()
                Text(ticket.status.title(language: store.language))
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(statusColor)
            }
            Text("\(store.t("series")) \(ticket.series) • \(store.t("draw")) \(ticket.formattedDrawDate)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let prize = ticket.prizeAmount, ticket.status == .won {
                Text("Prijs: €\(prize.formatted(.number.precision(.fractionLength(2))))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 6)
    }

    private var statusColor: Color {
        switch ticket.status {
        case .active: .orange
        case .checked: .blue
        case .won: .green
        case .lost: .red
        }
    }
}

struct TicketDetailView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State var ticket: LotteryTicket
    @State private var showDeleteConfirmation = false

    var body: some View {
        Form {
            Section(store.t("ticket")) {
                LabeledContent(store.t("number"), value: ticket.number)
                LabeledContent(store.t("series"), value: ticket.series)
                LabeledContent(store.t("draw"), value: ticket.formattedDrawDate)
                Picker(store.t("status"), selection: $ticket.status) {
                    ForEach(TicketStatus.allCases) { status in
                        Text(status.title(language: store.language)).tag(status)
                    }
                }
                if ticket.status == .won {
                    TextField(store.t("prize_amount"), value: $ticket.prizeAmount, format: .number)
                        .keyboardType(.decimalPad)
                }
            }
            Section(store.t("note")) {
                TextEditor(text: $ticket.note)
                    .frame(minHeight: 88)
            }
            Section {
                Button(store.t("save_changes")) {
                    store.updateTicket(ticket)
                    dismiss()
                }
                Button(store.t("delete_ticket"), role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        }
        .navigationTitle(store.t("ticket_details"))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(store.t("done")) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .confirmationDialog(store.t("delete_ticket_question"), isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button(store.t("delete_ticket"), role: .destructive) {
                store.deleteTicket(ticket)
                dismiss()
            }
        }
    }
}

struct TicketFormView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var number = ""
    @State private var series = ""
    @State private var drawDate = Calendar.current.nextDate(after: .now, matching: DateComponents(day: 10), matchingPolicy: .nextTime) ?? .now
    @State private var status: TicketStatus = .active
    @State private var note = ""
    @State private var validationMessage: String?

    var body: some View {
        Form {
            Section(store.t("new_ticket")) {
                TextField(store.t("ticket_number"), text: $number)
                    .keyboardType(.numberPad)
                TextField(store.t("series"), text: $series)
                    .keyboardType(.numberPad)
                DatePicker(store.t("draw"), selection: $drawDate, displayedComponents: .date)
                Picker(store.t("status"), selection: $status) {
                    ForEach(TicketStatus.allCases) { status in
                        Text(status.title(language: store.language)).tag(status)
                    }
                }
                TextField(store.t("note"), text: $note, axis: .vertical)
            }
            if let validationMessage {
                Section {
                    Label(validationMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(store.t("add_ticket"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(store.t("cancel")) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(store.t("save")) { save() }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(store.t("done")) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }

    private func save() {
        let cleanNumber = number.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSeries = series.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanNumber.count >= 4 else {
            validationMessage = store.t("valid_ticket_number")
            return
        }
        guard cleanSeries.count >= 2 else {
            validationMessage = store.t("valid_series")
            return
        }

        store.addTicket(LotteryTicket(id: UUID(), number: cleanNumber, series: cleanSeries, drawDate: drawDate, status: status, prizeAmount: nil, note: note))
        dismiss()
    }
}
