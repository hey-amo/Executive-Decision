import EDEngine
import SwiftUI

struct PlayerTallySheet: View {
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
