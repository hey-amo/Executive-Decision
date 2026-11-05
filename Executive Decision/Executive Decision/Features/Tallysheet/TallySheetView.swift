//
//  TallySheetView.swift
//  Executive Decision
//

import SwiftUI

struct TallySheetView: View {
    @State private var months = TallySheetMockData.months
    @State private var selectedMonth = 0
    @State private var selectedPhase: TallySheetPhase = .purchasing
    @State private var saveMessage: String?

    private var month: Binding<TallySheetMonth> {
        $months[selectedMonth]
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    monthPicker
                    phasePicker
                    phaseContent
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            saveBar
        }
        .background(PlayerSetupStyle.paper.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("OFFLINE PLAY")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(PlayerSetupStyle.mutedInk)

            Text("Tally sheet")
                .font(.custom("Georgia-Bold", size: 34))
                .foregroundStyle(PlayerSetupStyle.ink)

            Text("Record your bids, production, and sales each month.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(PlayerSetupStyle.mutedInk)
        }
    }

    private var monthPicker: some View {
        HStack(spacing: 12) {
            Button {
                stepMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 40, height: 40)
                    .background(PlayerSetupStyle.paper)
                    .clipShape(Circle())
            }
            .disabled(selectedMonth == 0)
            .accessibilityLabel("Previous month")

            VStack(spacing: 3) {
                Text(month.wrappedValue.name.uppercased())
                    .font(.custom("Georgia-Bold", size: 25))
                    .foregroundStyle(PlayerSetupStyle.ink)
                    .contentTransition(.numericText())

                Text("MONTH \(selectedMonth + 1) OF 12")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(PlayerSetupStyle.mutedInk)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)

            Button {
                stepMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 40, height: 40)
                    .background(PlayerSetupStyle.paper)
                    .clipShape(Circle())
            }
            .disabled(selectedMonth == months.count - 1)
            .accessibilityLabel("Next month")
        }
        .font(.system(size: 15, weight: .bold, design: .rounded))
        .foregroundStyle(PlayerSetupStyle.ink)
        .padding(12)
        .background(PlayerSetupStyle.gold.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(PlayerSetupStyle.ink.opacity(0.55), lineWidth: 2)
        }
    }

    private var phasePicker: some View {
        HStack(spacing: 8) {
            ForEach(TallySheetPhase.allCases) { phase in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedPhase = phase
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(phase.shortTitle)
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Capsule()
                            .fill(selectedPhase == phase ? PlayerSetupStyle.tomato : .clear)
                            .frame(height: 3)
                    }
                    .foregroundStyle(
                        selectedPhase == phase
                            ? PlayerSetupStyle.ink
                            : PlayerSetupStyle.mutedInk
                    )
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedPhase == phase ? .isSelected : [])
            }
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch selectedPhase {
        case .purchasing:
            TallySheetPurchasingSection(month: month)
        case .manufacturing:
            TallySheetManufacturingSection(month: month)
        case .selling:
            TallySheetSellingSection(month: month)
        }
    }

    private var saveBar: some View {
        VStack(spacing: 8) {
            if let saveMessage {
                Text(saveMessage)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(PlayerSetupStyle.mutedInk)
                    .accessibilityAddTraits(.updatesFrequently)
            }

            Button {
                saveMessage = "\(month.wrappedValue.name) tally sheet saved"
                print("Saved \(month.wrappedValue.name) tally sheet preview")
            } label: {
                Text("Save \(month.wrappedValue.name) tally sheet")
                    .font(.custom("Georgia-Bold", size: 20))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(PlayerSetupStyle.tomato)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(PlayerSetupStyle.ink, lineWidth: 3)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(PlayerSetupStyle.paper)
    }

    private func stepMonth(by amount: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedMonth = min(max(selectedMonth + amount, 0), months.count - 1)
            saveMessage = nil
        }
    }
}

#Preview {
    TallySheetView()
}
