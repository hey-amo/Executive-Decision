//
//  TallySheetModels.swift
//  Executive Decision
//

import Foundation

enum TallySheetPhase: String, CaseIterable, Identifiable {
    case purchasing
    case manufacturing
    case selling

    var id: String { rawValue }
    var shortTitle: String { rawValue.uppercased() }
}

struct TallySheetMonth: Identifiable {
    let id: Int
    let name: String
    var rawMaterialBids: [TallySheetRawMaterialBid]
    var productionEntries: [TallySheetProductionEntry]
    var finishedGoodsOffers: [TallySheetFinishedGoodsOffer]
}

struct TallySheetRawMaterialBid: Identifiable {
    let id: String
    let material: String
    var bidUnits: Int
    var bidPrice: Int
    var amountPaid: Int
}

struct TallySheetProductionEntry: Identifiable {
    let id: String
    let product: String
    let recipe: String
    var unitsMade: Int
}

struct TallySheetFinishedGoodsOffer: Identifiable {
    let id: String
    let product: String
    var offerUnits: Int
    var askingPrice: Int
    var amountReceived: Int
}

enum TallySheetMockData {
    static let months: [TallySheetMonth] = monthNames.enumerated().map { index, name in
        let isJanuary = index == 0

        return TallySheetMonth(
            id: index,
            name: name,
            rawMaterialBids: [
                TallySheetRawMaterialBid(
                    id: "x-fine",
                    material: "X-Fine",
                    bidUnits: isJanuary ? 3 : 0,
                    bidPrice: isJanuary ? 42 : 0,
                    amountPaid: isJanuary ? 126 : 0
                ),
                TallySheetRawMaterialBid(
                    id: "fine",
                    material: "Fine",
                    bidUnits: isJanuary ? 2 : 0,
                    bidPrice: isJanuary ? 31 : 0,
                    amountPaid: isJanuary ? 62 : 0
                ),
                TallySheetRawMaterialBid(
                    id: "standard",
                    material: "Standard",
                    bidUnits: isJanuary ? 1 : 0,
                    bidPrice: isJanuary ? 19 : 0,
                    amountPaid: 0
                )
            ],
            productionEntries: [
                TallySheetProductionEntry(
                    id: "a",
                    product: "A",
                    recipe: "2 X-Fine + 1 Fine",
                    unitsMade: isJanuary ? 1 : 0
                ),
                TallySheetProductionEntry(
                    id: "b",
                    product: "B",
                    recipe: "2 Fine + 1 Standard",
                    unitsMade: isJanuary ? 1 : 0
                ),
                TallySheetProductionEntry(
                    id: "c",
                    product: "C",
                    recipe: "1 Fine + 2 Standard",
                    unitsMade: 0
                )
            ],
            finishedGoodsOffers: [
                TallySheetFinishedGoodsOffer(
                    id: "a",
                    product: "A",
                    offerUnits: isJanuary ? 1 : 0,
                    askingPrice: isJanuary ? 145 : 0,
                    amountReceived: isJanuary ? 145 : 0
                ),
                TallySheetFinishedGoodsOffer(
                    id: "b",
                    product: "B",
                    offerUnits: isJanuary ? 1 : 0,
                    askingPrice: isJanuary ? 120 : 0,
                    amountReceived: 0
                ),
                TallySheetFinishedGoodsOffer(
                    id: "c",
                    product: "C",
                    offerUnits: 0,
                    askingPrice: 0,
                    amountReceived: 0
                )
            ]
        )
    }

    private static let monthNames = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
}
