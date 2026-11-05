//
//  GameBoardMockData.swift
//  Executive Decision
//

struct GameBoardMockData {
    static let monthNames = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    let currentMonthIndex: Int
    let activePlayerName: String?
    let statusMessage: String
    let rows: [GameBoardPriceRow]

    var currentMonthName: String {
        guard Self.monthNames.indices.contains(currentMonthIndex) else {
            return Self.monthNames[0]
        }
        return Self.monthNames[currentMonthIndex]
    }

    static let openingBalances = GameBoardMockData(
        currentMonthIndex: 0,
        activePlayerName: nil,
        statusMessage: "Opening prices are set. No monthly prices have been posted yet.",
        rows: makeRows(prices: Array(repeating: nil, count: 6))
    )

    static let january = GameBoardMockData(
        currentMonthIndex: 0,
        activePlayerName: "Rex",
        statusMessage: "Purchasing raw materials",
        rows: makeRows(prices: [42, 31, 18, 151, 122, 101])
    )

    static let allMonths = GameBoardMockData(
        currentMonthIndex: 0,
        activePlayerName: "Rex",
        statusMessage: "All 12 months posted",
        rows: makeRows(prices: [
            [42, 45, 43, 47, 44, 41, 46, 48, 45, 49, 46, 44],
            [31, 30, 34, 32, 35, 33, 36, 34, 38, 35, 37, 39],
            [18, 20, 19, 21, 23, 20, 22, 24, 21, 25, 23, 26],
            [151, 148, 153, 149, 155, 152, 157, 154, 159, 156, 162, 160],
            [122, 125, 121, 127, 124, 129, 126, 131, 128, 134, 132, 136],
            [101, 98, 103, 100, 106, 104, 108, 105, 111, 109, 113, 116]
        ])
    )

    private static func makeRows(prices: [Int?]) -> [GameBoardPriceRow] {
        let rows: [(String, Int, GameBoardProductCategory)] = [
            ("X-Fine", 40, .rawMaterials),
            ("Fine", 30, .rawMaterials),
            ("Standard", 20, .rawMaterials),
            ("A", 140, .finishedGoods),
            ("B", 115, .finishedGoods),
            ("C", 90, .finishedGoods)
        ]

        return rows.enumerated().map { index, row in
            GameBoardPriceRow(
                id: row.0,
                name: row.0,
                openingPrice: row.1,
                category: row.2,
                monthlyPrices: monthNames.indices.map { monthIndex in
                    monthIndex == 0 ? prices[index] : nil
                }
            )
        }
    }

    private static func makeRows(prices: [[Int]]) -> [GameBoardPriceRow] {
        let rows: [(String, Int, GameBoardProductCategory)] = [
            ("X-Fine", 40, .rawMaterials),
            ("Fine", 30, .rawMaterials),
            ("Standard", 20, .rawMaterials),
            ("A", 140, .finishedGoods),
            ("B", 115, .finishedGoods),
            ("C", 90, .finishedGoods)
        ]

        return rows.enumerated().map { index, row in
            GameBoardPriceRow(
                id: row.0,
                name: row.0,
                openingPrice: row.1,
                category: row.2,
                monthlyPrices: prices[index].map(Optional.some)
            )
        }
    }
}

struct GameBoardPriceRow: Identifiable {
    let id: String
    let name: String
    let openingPrice: Int
    let category: GameBoardProductCategory
    let monthlyPrices: [Int?]

    func price(for monthIndex: Int) -> Int? {
        guard monthlyPrices.indices.contains(monthIndex) else { return nil }
        return monthlyPrices[monthIndex]
    }
}

enum GameBoardProductCategory {
    case rawMaterials
    case finishedGoods
}
