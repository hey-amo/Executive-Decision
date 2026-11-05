//
//  ProductionChartView.swift
//  Executive Decision
//

import SwiftUI

struct ProductionChartView: View {
    private let recipes = [
        ProductionRecipe(name: "A", extraFine: 2, fine: 1, standard: 0),
        ProductionRecipe(name: "B", extraFine: 0, fine: 2, standard: 1),
        ProductionRecipe(name: "C", extraFine: 0, fine: 1, standard: 2)
    ]

    var body: some View {
        GameBoardReferenceSection(
            title: "PRODUCTION CHART",
            helpText: "Each finished good requires three raw material units. Higher grades may substitute for lower grades."
        ) {
            VStack(alignment: .leading, spacing: 25) {
                HStack(spacing: 0) {
                    Text("GOODS")
                        .frame(width: 62, alignment: .leading)
                    Text("X-FINE")
                        .frame(maxWidth: .infinity)
                    Text("FINE")
                        .frame(maxWidth: .infinity)
                    Text("STANDARD")
                        .frame(maxWidth: .infinity)
                }
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(PlayerSetupStyle.mutedInk)
                .padding(.bottom, 5)

                ForEach(recipes) { recipe in
                    HStack(spacing: 0) {
                        Text(recipe.name)
                            .font(.custom("Georgia-Bold", size: 18))
                            .frame(width: 62, alignment: .leading)
                        ingredientCount(recipe.extraFine)
                        ingredientCount(recipe.fine)
                        ingredientCount(recipe.standard)
                    }
                    .foregroundStyle(PlayerSetupStyle.ink)
                    .padding(.vertical, 7)
                    .overlay(alignment: .bottom) {
                        PlayerSetupStyle.ink.opacity(0.12)
                            .frame(height: 1)
                    }
                }
            }
        }
    }

    private func ingredientCount(_ count: Int) -> some View {
        Text("\(count)")
            .font(.system(size: 15, weight: .semibold, design: .rounded).monospacedDigit())
            .frame(maxWidth: .infinity)
    }
}

private struct ProductionRecipe: Identifiable {
    let name: String
    let extraFine: Int
    let fine: Int
    let standard: Int

    var id: String { name }
}
