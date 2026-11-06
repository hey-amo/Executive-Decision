import Testing
@testable import EDEngine

@Suite("Production allocator")
struct EDProductionAllocatorTests {
    @Test("Allocates exact recipe certificates")
    func allocatesExactRecipe() throws {
        let inventory = try EDInventory(
            certificatesByGrade: [.xfine: 2, .fine: 1]
        )

        let allocation = EDProductionAllocator.allocate(
            inventory: inventory,
            goodsUnits: [.a: 1]
        )

        #expect(allocation?.certificatesUsedByGood[.a] == [
            .xfine: 2,
            .fine: 1,
            .standard: 0
        ])
        #expect(allocation?.certificatesUsedByGrade == [
            .xfine: 2,
            .fine: 1,
            .standard: 0
        ])
        #expect(inventory.certificatesByGrade == [
            .xfine: 2,
            .fine: 1,
            .standard: 0
        ])
    }

    @Test("Uses only the substitutions allowed by the manufacturing rules")
    func allocatesLegalSubstitutions() throws {
        let inventory = try EDInventory(
            certificatesByGrade: [.xfine: 1, .fine: 2]
        )

        let allocation = EDProductionAllocator.allocate(
            inventory: inventory,
            goodsUnits: [.b: 1]
        )

        #expect(allocation?.certificatesUsedByGood[.b] == [
            .xfine: 1,
            .fine: 2,
            .standard: 0
        ])
    }

    @Test("Finds a joint assignment across several goods")
    func allocatesMultipleGoodsTogether() throws {
        let inventory = try EDInventory(
            certificatesByGrade: [.xfine: 1, .fine: 4, .standard: 2]
        )

        let allocation = EDProductionAllocator.allocate(
            inventory: inventory,
            goodsUnits: [.b: 1, .c: 1]
        )

        #expect(allocation?.certificatesUsedByGood[.b] == [
            .xfine: 0,
            .fine: 2,
            .standard: 1
        ])
        #expect(allocation?.certificatesUsedByGood[.c] == [
            .xfine: 0,
            .fine: 2,
            .standard: 1
        ])
        #expect(allocation?.certificatesUsedByGrade == [
            .xfine: 0,
            .fine: 4,
            .standard: 2
        ])
    }

    @Test("Does not over-allocate a shared certificate to competing recipes")
    func rejectsJointShortage() throws {
        let inventory = try EDInventory(
            certificatesByGrade: [.fine: 3, .standard: 2]
        )

        #expect(
            EDProductionAllocator.allocate(
                inventory: inventory,
                goodsUnits: [.b: 1, .c: 1]
            ) == nil
        )
    }

    @Test("Uses lower-grade substitutions before more expensive alternatives")
    func prefersCheaperSubstitution() throws {
        let inventory = try EDInventory(
            certificatesByGrade: [.xfine: 1, .fine: 2]
        )

        let allocation = EDProductionAllocator.allocate(
            inventory: inventory,
            goodsUnits: [.b: 1]
        )

        #expect(allocation?.certificatesUsedByGrade[.xfine] == 1)
        #expect(allocation?.certificatesUsedByGrade[.fine] == 2)
    }

    @Test("An empty production request succeeds without using certificates")
    func allocatesNoGoods() throws {
        let inventory = try EDInventory(certificatesByGrade: [.xfine: 5])

        let allocation = EDProductionAllocator.allocate(
            inventory: inventory,
            goodsUnits: [:]
        )

        #expect(allocation?.certificatesUsedByGrade == [
            .xfine: 0,
            .fine: 0,
            .standard: 0
        ])
    }

    @Test("Rejects negative and overflowing requests")
    func rejectsInvalidRequests() throws {
        let inventory = try EDInventory(
            certificatesByGrade: [.xfine: Int.max, .fine: Int.max, .standard: Int.max]
        )

        #expect(
            EDProductionAllocator.allocate(
                inventory: inventory,
                goodsUnits: [.a: -1]
            ) == nil
        )
        #expect(
            EDProductionAllocator.allocate(
                inventory: inventory,
                goodsUnits: [.a: Int.max]
            ) == nil
        )
    }
}
