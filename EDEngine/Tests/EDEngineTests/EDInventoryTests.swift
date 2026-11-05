import Foundation
import Testing
@testable import EDEngine

@Suite("Raw-material inventory")
struct EDInventoryTests {
    @Test("Tracks certificate counts independently by grade")
    func tracksCertificateCountsByGrade() throws {
        let inventory = try EDInventory(
            certificatesByGrade: [.xfine: 2, .fine: 3]
        )

        #expect(inventory.count(of: .xfine) == 2)
        #expect(inventory.count(of: .fine) == 3)
        #expect(inventory.count(of: .standard) == 0)
        #expect(inventory.certificatesByGrade == [
            .xfine: 2,
            .fine: 3,
            .standard: 0
        ])
    }

    @Test("Rejects negative initial certificate counts")
    func rejectsNegativeInitialCounts() {
        do {
            _ = try EDInventory(certificatesByGrade: [.fine: -1])
            Issue.record("Expected a negative certificate count to be rejected.")
        } catch {
            #expect(error == .negativeCertificateCount(grade: .fine, count: -1))
        }
    }

    @Test("Adds and removes certificates by grade")
    func addsAndRemovesCertificates() throws {
        var inventory = try EDInventory(certificatesByGrade: [.xfine: 2])

        try inventory.add(3, of: .fine)
        try inventory.remove(1, of: .xfine)
        try inventory.add(0, of: .standard)
        try inventory.remove(0, of: .fine)

        #expect(inventory.certificatesByGrade == [
            .xfine: 1,
            .fine: 3,
            .standard: 0
        ])
    }

    @Test("Rejects invalid operations without changing inventory")
    func invalidOperationsAreAtomic() throws {
        var inventory = try EDInventory(certificatesByGrade: [.fine: 2])

        do {
            try inventory.add(-1, of: .fine)
            Issue.record("Expected a negative addition to be rejected.")
        } catch {
            #expect(error == .negativeUnitCount(-1))
        }

        do {
            try inventory.remove(3, of: .fine)
            Issue.record("Expected removing unavailable certificates to fail.")
        } catch {
            #expect(error == .insufficientCertificates(
                grade: .fine,
                requested: 3,
                available: 2
            ))
        }

        #expect(inventory.count(of: .fine) == 2)
    }

    @Test("Rejects certificate-count overflow")
    func rejectsCertificateCountOverflow() throws {
        var inventory = try EDInventory(certificatesByGrade: [.standard: Int.max])

        do {
            try inventory.add(1, of: .standard)
            Issue.record("Expected certificate-count overflow to fail.")
        } catch {
            #expect(error == .certificateCountOverflow(grade: .standard))
        }

        #expect(inventory.count(of: .standard) == Int.max)
    }

    @Test("Matches the recipes and legal downward substitutions")
    func checksProductionMaterials() throws {
        let exactA = try EDInventory(certificatesByGrade: [.xfine: 2, .fine: 1])
        let substitutedB = try EDInventory(certificatesByGrade: [.xfine: 1, .fine: 2])
        let wrongDirection = try EDInventory(certificatesByGrade: [.standard: 3])

        #expect(exactA.canProduce(.a))
        #expect(substitutedB.canProduce(.b))
        #expect(!wrongDirection.canProduce(.b))
        #expect(!exactA.canProduce(.c))
        #expect(exactA.canProduce(.a, units: 0))
        #expect(!exactA.canProduce(.a, units: -1))
    }

    @Test("Consumes recipe certificates and applies substitutions")
    func consumesSoldGoodsCertificates() throws {
        var inventory = try EDInventory(
            certificatesByGrade: [.xfine: 1, .fine: 1, .standard: 1]
        )

        try inventory.consume(.b)

        #expect(inventory.certificatesByGrade == [
            .xfine: 0,
            .fine: 0,
            .standard: 0
        ])
    }

    @Test("Failed production consumption leaves the inventory unchanged")
    func failedConsumptionIsAtomic() throws {
        var inventory = try EDInventory(certificatesByGrade: [.xfine: 1, .fine: 1])

        do {
            try inventory.consume(.a)
            Issue.record("Expected insufficient materials to fail.")
        } catch {
            #expect(error == .insufficientMaterials(recipe: .a, units: 1))
        }

        #expect(inventory.certificatesByGrade == [
            .xfine: 1,
            .fine: 1,
            .standard: 0
        ])
    }

    @Test("Codable round-trips inventory and rejects negative persisted counts")
    func codableValidation() throws {
        let inventory = try EDInventory(certificatesByGrade: [.xfine: 4, .standard: 2])
        let data = try JSONEncoder().encode(inventory)
        #expect(try JSONDecoder().decode(EDInventory.self, from: data) == inventory)

        do {
            _ = try JSONDecoder().decode(
                EDInventory.self,
                from: Data(#"{"extraFineCertificates":-1}"#.utf8)
            )
            Issue.record("Expected a negative persisted certificate count to fail.")
        } catch is DecodingError {
        } catch {
            Issue.record("Unexpected decoding error: \(error)")
        }
    }
}
