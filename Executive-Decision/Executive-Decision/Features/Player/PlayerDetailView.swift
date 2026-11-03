import EDEngine
import SwiftUI

struct PlayerDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let player: EDPlayer
    let settings: EDGameSettings
    let isCurrentPlayer: Bool

    init(
        player: EDPlayer,
        settings: EDGameSettings = EDGameSettings(),
        isCurrentPlayer: Bool = false
    ) {
        self.player = player
        self.settings = settings
        self.isCurrentPlayer = isCurrentPlayer
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Player details")
                    .font(.system(size: 26, weight: .black, design: .serif))
                    .foregroundStyle(PlayerRosterStyle.ink)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(PlayerRosterStyle.ink)
                        .frame(width: 40, height: 40)
                        .background(PlayerRosterStyle.ink.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss player details")
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 18) {
                    playerSummary
                    cardsSection

                    if settings.allowLoans {
                        loansSection
                    }

                    tallySheetSection
                }
                .padding(22)
            }
        }
        .background(PlayerRosterStyle.parchment.ignoresSafeArea())
    }

    private var playerSummary: some View {
        VStack(spacing: 12) {
            PlayerAvatarView(
                avatarResource: player.avatarResource?.rawValue ?? "avt-1",
                isHighlighted: true,
                size: 128
            )

            Text(player.name)
                .font(.system(size: 30, weight: .black, design: .serif))
                .foregroundStyle(PlayerRosterStyle.ink)

            Text(player.isAI ? "Bot" : "Human")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(PlayerRosterStyle.muted)

            HStack(spacing: 8) {
                Image(systemName: "dollarsign.circle.fill")
                Text(player.coins.formatted(.currency(code: "USD").precision(.fractionLength(0))))
            }
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundStyle(player.coins < 0 ? .red : PlayerRosterStyle.ink)
            .accessibilityLabel("Coins: \(player.coins.formatted(.currency(code: "USD").precision(.fractionLength(0))))")
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 12))
    }

    private var cardsSection: some View {
        detailSection(title: "Cards") {
            VStack(spacing: 8) {
                Image(systemName: "rectangle.stack")
                    .font(.system(size: 24))
                    .foregroundStyle(PlayerRosterStyle.muted)
                Text("Card inventory isn’t tracked yet.")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(PlayerRosterStyle.muted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }

    private var loansSection: some View {
        detailSection(title: "Loans") {
            HStack {
                Label("Active loans", systemImage: "doc.text")
                    .foregroundStyle(PlayerRosterStyle.ink)
                Spacer()
                Text("\(player.loans.count)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(PlayerRosterStyle.ink)
                    .accessibilityLabel("\(player.loans.count) loans")
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
        }
    }

    @ViewBuilder
    private var tallySheetSection: some View {
        if isCurrentPlayer {
            PlayerTallySheetSection(tallySheet: player.tallySheet)
        } else {
            detailSection(title: "Tally sheet") {
                Label("Private to \(player.name)", systemImage: "lock.fill")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(PlayerRosterStyle.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func detailSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundStyle(PlayerRosterStyle.muted)

            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PlayerTallySheetSection: View {
    let tallySheet: EDTallySheet

    private var entries: [EDMonthlyTally] {
        tallySheet.monthlyTallies.values.sorted { $0.month.rawValue < $1.month.rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TALLY SHEET")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundStyle(PlayerRosterStyle.muted)

            VStack(alignment: .leading, spacing: 14) {
                if entries.isEmpty {
                    Text("No tally entries recorded yet.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(PlayerRosterStyle.muted)
                } else {
                    ForEach(entries, id: \.month.rawValue) { entry in
                        monthlyEntry(entry)
                    }

                    Divider()

                    HStack {
                        Text("Yearly net")
                            .fontWeight(.bold)
                        Spacer()
                        Text(currency(tallySheet.yearlyTotals.net))
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(PlayerRosterStyle.ink)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func monthlyEntry(_ entry: EDMonthlyTally) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(monthName(entry.month))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Spacer()
                Text("Net \(currency(entry.totals.net))")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(PlayerRosterStyle.ink)

            ForEach(entry.orders.keys.sorted { $0.rawValue < $1.rawValue }, id: \.self) { material in
                if let order = entry.orders[material] {
                    tallyLine(
                        "\(materialName(material)): \(order.unitsPurchased) bought",
                        amount: -order.amountPaid
                    )
                }
            }

            ForEach(entry.sales.keys.sorted { $0.rawValue < $1.rawValue }, id: \.self) { good in
                if let sale = entry.sales[good] {
                    tallyLine(
                        "Good \(good.rawValue.uppercased()): \(sale.unitsSold) sold",
                        amount: sale.amountReceived
                    )
                }
            }
        }
    }

    private func tallyLine(_ title: String, amount: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(currency(amount))
        }
        .font(.system(size: 14, weight: .medium, design: .rounded))
        .foregroundStyle(PlayerRosterStyle.muted)
    }

    private func currency(_ amount: Int) -> String {
        amount.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private func monthName(_ month: EDTallyMonth) -> String {
        switch month {
        case .january: "January"
        case .february: "February"
        case .march: "March"
        case .april: "April"
        case .may: "May"
        case .june: "June"
        case .july: "July"
        case .august: "August"
        case .september: "September"
        case .october: "October"
        case .november: "November"
        case .december: "December"
        }
    }

    private func materialName(_ material: RawMaterial) -> String {
        switch material {
        case .standard: "Standard"
        case .fine: "Fine"
        case .extraFine: "Extra fine"
        }
    }
}

#Preview {
    PlayerDetailView(
        player: EDPlayer(name: "Vivian", avatar: .avt5, coins: 450),
        settings: EDGameSettings(allowLoans: true),
        isCurrentPlayer: true
    )
}
