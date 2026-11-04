// EDPlayer (swift)

import Foundation
import GameKit

public typealias Player = EDPlayer

public typealias Avatar = EDAvatarToResourceName

public enum EDAvatarToResourceName: String, CaseIterable, Sendable {
    case avt1 = "avt-1"
    case avt2 = "avt-2"
    case avt3 = "avt-3"
    case avt4 = "avt-4"
    case avt5 = "avt-5"
    case avt6 = "avt-6"
}

public class EDPlayer: GKPlayer, Identifiable {
    public let id: UUID = UUID()
    override public var playerID: String { return self.id.uuidString }
    public var name: String
    public var avatarResource: Avatar?
    public var tallySheet: EDTallySheet = EDTallySheet()
    @MainActor public private(set) var rawMaterialHand: [EDRawMaterialCard] = []
    @MainActor public private(set) lazy var handManager = EDHandManager(delegate: self)
    public private(set) var rawMaterialInventory: [RawMaterial: Int] = [:]
    /// Month-scoped production and sale records; finished goods are not carried forward.
    public var monthlyGoods = EDMonthlyGoodsState()
    private var _coins: Int
    public var coins: Int { get { return self._coins} }
    public var isBankrupt: Bool = false
    public var loans: [EDLoanEntry] = []
    public var isAI: Bool = false

    public init(name: String,
                avatar: Avatar? = nil,
                coins: Int = 0,
                isBankrupt: Bool = false,
                loans: [EDLoanEntry]  = [],
                isAI: Bool = false) {
        self.name = name
        self.avatarResource = avatar
        self._coins = coins
        self.isBankrupt = isBankrupt
        self.loans = loans
        self.isAI = isAI
    }

    public static func == (lhs: EDPlayer, rhs: EDPlayer) -> Bool {
        return lhs.id == rhs.id
    }

    public func addRawMaterials(_ quantities: [RawMaterial: Int]) throws {
        var updatedInventory = rawMaterialInventory
        for (material, quantity) in quantities {
            guard quantity >= 0 else {
                throw EDPlayerInventoryError.negativeQuantity(material)
            }
            let (total, overflow) = updatedInventory[material, default: 0]
                .addingReportingOverflow(quantity)
            guard !overflow else {
                throw EDPlayerInventoryError.quantityOverflow(material)
            }
            updatedInventory[material] = total
        }
        rawMaterialInventory = updatedInventory
    }

    public func consumeRawMaterials(_ quantities: [RawMaterial: Int]) throws {
        var updatedInventory = rawMaterialInventory
        for (material, quantity) in quantities {
            guard quantity >= 0 else {
                throw EDPlayerInventoryError.negativeQuantity(material)
            }
            let available = updatedInventory[material, default: 0]
            guard quantity <= available else {
                throw EDPlayerInventoryError.insufficientMaterials(material)
            }
            let remaining = available - quantity
            if remaining == 0 {
                updatedInventory.removeValue(forKey: material)
            } else {
                updatedInventory[material] = remaining
            }
        }
        rawMaterialInventory = updatedInventory
    }
}

public enum EDPlayerInventoryError: Error, Equatable {
    case negativeQuantity(RawMaterial)
    case insufficientMaterials(RawMaterial)
    case quantityOverflow(RawMaterial)
}

extension EDPlayer: UpdateWalletDelegate {
    public func walletDidUpdate(balance: Int) {
        self._coins = balance
    }

}

extension EDPlayer: EDHandManagerDelegate {
    @MainActor
    public func handManager(_ manager: EDHandManager, didUpdate cards: [EDRawMaterialCard]) {
        rawMaterialHand = cards
    }
}
