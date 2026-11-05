//
//  TallySheetSections.swift
//  Executive Decision
//

import SwiftUI

struct TallySheetPurchasingSection: View {
    @Binding var month: TallySheetMonth

    private var totalPaid: Int {
        month.rawMaterialBids.reduce(0) { $0 + $1.amountPaid }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TallySheetSectionIntro(
                title: "Buy raw materials",
                instructions: "Secretly enter the units you want and the price you’ll pay per unit. After the market price is posted, clear unsuccessful bids and record what you paid."
            )

            ForEach($month.rawMaterialBids) { $bid in
                TallySheetEntryCard(title: bid.material, subtitle: "RAW MATERIAL") {
                    HStack(spacing: 8) {
                        TallySheetNumberField(title: "Bid units", value: $bid.bidUnits)
                        TallySheetNumberField(title: "Bid price", value: $bid.bidPrice, prefix: "$")
                        TallySheetNumberField(title: "Amount paid", value: $bid.amountPaid, prefix: "$")
                    }
                }
            }

            TallySheetTotalCard(title: "Total paid to broker", amount: totalPaid)
        }
    }
}

struct TallySheetManufacturingSection: View {
    @Binding var month: TallySheetMonth

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TallySheetSectionIntro(
                title: "Plan production",
                instructions: "Record how many finished goods you intend to make from the raw materials you have. Each good uses three units; only higher-grade materials may substitute for lower grades."
            )

            ForEach($month.productionEntries) { $entry in
                TallySheetEntryCard(title: "Product \(entry.product)", subtitle: entry.recipe) {
                    TallySheetNumberField(title: "Units to make", value: $entry.unitsMade)
                        .frame(maxWidth: 120)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct TallySheetSellingSection: View {
    @Binding var month: TallySheetMonth

    private var totalReceived: Int {
        month.finishedGoodsOffers.reduce(0) { $0 + $1.amountReceived }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TallySheetSectionIntro(
                title: "Sell finished goods",
                instructions: "Enter the units you’re offering and the lowest price you’ll accept. After the market price is posted, clear unsuccessful offers and record the money received."
            )

            ForEach($month.finishedGoodsOffers) { $offer in
                TallySheetEntryCard(title: "Product \(offer.product)", subtitle: "FINISHED GOODS") {
                    HStack(spacing: 8) {
                        TallySheetNumberField(title: "Offer units", value: $offer.offerUnits)
                        TallySheetNumberField(title: "Ask price", value: $offer.askingPrice, prefix: "$")
                        TallySheetNumberField(title: "Received", value: $offer.amountReceived, prefix: "$")
                    }
                }
            }

            TallySheetTotalCard(title: "Total received from broker", amount: totalReceived)
        }
    }
}

private struct TallySheetSectionIntro: View {
    let title: String
    let instructions: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.custom("Georgia-Bold", size: 23))
                .foregroundStyle(PlayerSetupStyle.ink)

            Text(instructions)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(PlayerSetupStyle.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PlayerSetupStyle.gold.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct TallySheetEntryCard<Fields: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let fields: Fields

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.custom("Georgia-Bold", size: 20))
                    .foregroundStyle(PlayerSetupStyle.ink)

                Spacer()

                Text(subtitle.uppercased())
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(PlayerSetupStyle.mutedInk)
                    .multilineTextAlignment(.trailing)
            }

            fields
        }
        .padding(12)
        .background(PlayerSetupStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(PlayerSetupStyle.ink.opacity(0.55), lineWidth: 1.5)
        }
    }
}

private struct TallySheetNumberField: View {
    let title: String
    @Binding var value: Int
    var prefix = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(PlayerSetupStyle.mutedInk)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            HStack(spacing: 2) {
                if !prefix.isEmpty {
                    Text(prefix)
                        .foregroundStyle(PlayerSetupStyle.mutedInk)
                }

                TextField("0", value: $value, format: .number)
                    .keyboardType(.numberPad)
                    .font(.system(size: 15, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(PlayerSetupStyle.ink)
                    .multilineTextAlignment(.leading)
                    .accessibilityLabel(title)
            }
            .padding(.horizontal, 8)
            .frame(height: 36)
            .background(PlayerSetupStyle.paper)
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TallySheetTotalCard: View {
    let title: String
    let amount: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(PlayerSetupStyle.ink)

            Spacer()

            Text(amount, format: .currency(code: "USD").precision(.fractionLength(0)))
                .font(.custom("Georgia-Bold", size: 20))
                .foregroundStyle(PlayerSetupStyle.ink)
        }
        .padding(14)
        .background(PlayerSetupStyle.gold.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
