//
//  MarketCalculatorView.swift
//  Executive Decision
//

import SwiftUI

struct MarketCalculatorView: View {
    private let rawMaterialEntries = (0...24).map {
        MarketCalculatorEntry(units: $0, movement: $0 - 10)
    }
    private let finishedGoodsEntries = (0...16).map {
        MarketCalculatorEntry(units: $0, movement: 11 - (2 * $0))
    }

    var body: some View {
        GameBoardReferenceSection(
            title: "MARKET CALCULATOR",
            helpText: "Use the number of units ordered or offered to find the price movement."
        ) {
            VStack(alignment: .leading, spacing: 15) {
                MarketCalculatorGrid(title: "RAW MATERIALS", entries: rawMaterialEntries)
                MarketCalculatorGrid(title: "FINISHED GOODS", entries: finishedGoodsEntries)
            }
        }
    }
}

private struct MarketCalculatorEntry: Identifiable {
    let units: Int
    let movement: Int

    var id: Int { units }
}

private struct MarketCalculatorGrid: View {
    let title: String
    let entries: [MarketCalculatorEntry]

    private let labelWidth: CGFloat = 66
    private let cellWidth: CGFloat = 38

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(PlayerSetupStyle.mutedInk)

            ScrollView(.horizontal) {
                VStack(spacing: 0) {
                    entryRow(label: "UNITS") { entry in
                        "\(entry.units)"
                    }
                    entryRow(label: "MOVEMENT") { entry in
                        entry.movement > 0 ? "+\(entry.movement)" : "\(entry.movement)"
                    }
                }
            }
            .scrollIndicators(.visible)
        }
    }

    private func entryRow(
        label: String,
        value: @escaping (MarketCalculatorEntry) -> String
    ) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(PlayerSetupStyle.mutedInk)
                .frame(width: labelWidth, height: 28, alignment: .leading)
                .padding(.leading, 7)
                .background(PlayerSetupStyle.gold.opacity(0.13))

            ForEach(entries) { entry in
                Text(value(entry))
                    .font(.system(size: 10, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(PlayerSetupStyle.ink)
                    .frame(width: cellWidth, height: 28)
                    .overlay {
                        Rectangle()
                            .stroke(PlayerSetupStyle.ink.opacity(0.1), lineWidth: 0.5)
                    }
            }
        }
        .overlay(alignment: .bottom) {
            PlayerSetupStyle.ink.opacity(0.15)
                .frame(height: 1)
        }
    }
}
