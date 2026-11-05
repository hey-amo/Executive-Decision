//
//  GameBoardPriceTable.swift
//  Executive Decision
//

import SwiftUI

struct GameBoardPriceTable: View {
    let mockData: GameBoardMockData

    private let productColumnWidth: CGFloat = 88
    private let openingColumnWidth: CGFloat = 76
    private let monthColumnWidth: CGFloat = 106
    private let headerHeight: CGFloat = 52
    private let rowHeight: CGFloat = 48

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("PRICE HISTORY")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(PlayerSetupStyle.mutedInk)

                Spacer()

                Label("SWIPE MONTHS", systemImage: "arrow.left.and.right")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(PlayerSetupStyle.mutedInk)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)

            HStack(alignment: .top, spacing: 0) {
                productAndOpeningColumns

                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(GameBoardMockData.monthNames.indices, id: \.self) { monthIndex in
                            monthColumn(at: monthIndex)
                        }
                    }
                }
                .scrollIndicators(.visible)
                .accessibilityLabel("Monthly prices. Scroll horizontally to see every month.")
            }
        }
        .background(PlayerSetupStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(PlayerSetupStyle.ink, lineWidth: 2)
        }
        .help("The game board is for reference only and cannot be edited.")
    }

    private var productAndOpeningColumns: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                headerCell("PRODUCT", width: productColumnWidth, alignment: .leading)
                headerCell("OPENING", width: openingColumnWidth, alignment: .trailing)
            }
            .padding(.horizontal, 9)
            .frame(height: headerHeight)

            ForEach(Array(mockData.rows.enumerated()), id: \.element.id) { index, row in
                HStack(spacing: 0) {
                    Text(row.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(PlayerSetupStyle.ink)
                        .frame(width: productColumnWidth, alignment: .leading)

                    Text("$\(row.openingPrice)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(PlayerSetupStyle.ink)
                        .frame(width: openingColumnWidth, alignment: .trailing)
                }
                .padding(.horizontal, 9)
                .frame(height: rowHeight)
                .overlay(alignment: .bottom) {
                    rowDivider(after: index)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(row.name), opening price $\(row.openingPrice)")
            }
        }
        .background(PlayerSetupStyle.card)
        .overlay(alignment: .trailing) {
            PlayerSetupStyle.ink.opacity(0.28)
                .frame(width: 1)
        }
    }

    private func monthColumn(at monthIndex: Int) -> some View {
        let isCurrentMonth = monthIndex == mockData.currentMonthIndex

        return VStack(spacing: 0) {
            Text(GameBoardMockData.monthNames[monthIndex].uppercased())
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(0.4)
                .foregroundStyle(isCurrentMonth ? PlayerSetupStyle.tomato : PlayerSetupStyle.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: monthColumnWidth, height: headerHeight)
                .background(isCurrentMonth ? PlayerSetupStyle.gold.opacity(0.32) : PlayerSetupStyle.card)
                .overlay(alignment: .bottom) {
                    PlayerSetupStyle.ink.opacity(0.25)
                        .frame(height: 1)
                }

            ForEach(Array(mockData.rows.enumerated()), id: \.element.id) { index, row in
                Text(row.price(for: monthIndex).map { "$\($0)" } ?? "—")
                    .font(.system(size: 14, weight: isCurrentMonth ? .bold : .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(row.price(for: monthIndex) == nil ? PlayerSetupStyle.mutedInk : PlayerSetupStyle.ink)
                    .frame(width: monthColumnWidth, height: rowHeight)
                    .background(isCurrentMonth ? PlayerSetupStyle.gold.opacity(0.16) : PlayerSetupStyle.card)
                    .overlay(alignment: .bottom) {
                        rowDivider(after: index)
                    }
                    .overlay(alignment: .trailing) {
                        PlayerSetupStyle.ink.opacity(0.1)
                            .frame(width: 1)
                    }
                    .accessibilityLabel("\(GameBoardMockData.monthNames[monthIndex]), \(row.name), \(row.price(for: monthIndex).map { "price $\($0)" } ?? "no price posted")")
            }
        }
        .overlay {
            Rectangle()
                .stroke(
                    isCurrentMonth ? PlayerSetupStyle.tomato : PlayerSetupStyle.ink.opacity(0.12),
                    lineWidth: isCurrentMonth ? 2 : 1
                )
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(GameBoardMockData.monthNames[monthIndex])
        .accessibilityValue(isCurrentMonth ? "Current month" : "")
    }

    private func headerCell(
        _ title: String,
        width: CGFloat,
        alignment: Alignment
    ) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .tracking(0.4)
            .foregroundStyle(PlayerSetupStyle.mutedInk)
            .frame(width: width, height: headerHeight, alignment: alignment)
            .background(PlayerSetupStyle.card)
            .overlay(alignment: .bottom) {
                PlayerSetupStyle.ink.opacity(0.25)
                    .frame(height: 1)
            }
    }

    @ViewBuilder
    private func rowDivider(after index: Int) -> some View {
        PlayerSetupStyle.ink.opacity(index == 2 ? 0.3 : 0.1)
            .frame(height: index == 2 ? 2 : 1)
    }
}
