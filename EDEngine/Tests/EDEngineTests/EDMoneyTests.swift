import Foundation
import Testing
@testable import EDEngine

@Suite("Money")
struct EDMoneyTests {
    @Test("Creates balances at or above the minimum, including negative balances")
    func acceptsValidBalances() throws {
        #expect(try EDMoney().balance == 0)
        #expect(try EDMoney(balance: -125).balance == -125)
        #expect(try EDMoney(balance: EDMoney.minimumBalance).balance == -5_000)
        #expect(try EDMoney(balance: Int.max).balance == Int.max)
    }

    @Test("Rejects a balance below the minimum")
    func rejectsBalanceBelowMinimum() {
        do {
            _ = try EDMoney(balance: -5_001)
            Issue.record("Expected a balance below the minimum to be rejected.")
        } catch {
            #expect(error == .balanceBelowMinimum(-5_001))
        }
    }

    @Test("Adds positive amounts to positive and negative balances")
    func addsPositiveAmounts() throws {
        #expect(try EDMoney(balance: 100).adding(25).balance == 125)
        #expect(try EDMoney(balance: -100).adding(25).balance == -75)
    }

    @Test("Rejects zero and negative additions without changing the value")
    func rejectsNonpositiveAdditions() throws {
        let money = try EDMoney(balance: -10)

        for amount in [0, -1, Int.min] {
            do {
                _ = try money.adding(amount)
                Issue.record("Expected addition of \(amount) to be rejected.")
            } catch {
                #expect(error == .additionMustBePositive(amount))
            }
        }

        #expect(money.balance == -10)
    }

    @Test("Subtracts into negative balances down to the minimum")
    func subtractsIntoNegativeBalances() throws {
        #expect(try EDMoney(balance: 10).subtracting(15).balance == -5)
        #expect(try EDMoney(balance: -4_999).subtracting(1).balance == -5_000)
        #expect(try EDMoney(balance: 10).subtracting(0).balance == 10)
    }

    @Test("Rejects subtraction below the minimum and negative subtraction amounts")
    func rejectsInvalidSubtractions() throws {
        let money = try EDMoney(balance: -4_999)

        do {
            _ = try money.subtracting(2)
            Issue.record("Expected subtraction below the minimum to be rejected.")
        } catch {
            #expect(error == .balanceBelowMinimum(-5_001))
        }

        for amount in [-1, Int.min] {
            do {
                _ = try money.subtracting(amount)
                Issue.record("Expected subtraction of \(amount) to be rejected.")
            } catch {
                #expect(error == .subtractionMustBeNonnegative(amount))
            }
        }

        #expect(money.balance == -4_999)
    }

    @Test("Rejects arithmetic overflow")
    func rejectsArithmeticOverflow() throws {
        let maximum = try EDMoney(balance: Int.max)
        do {
            _ = try maximum.adding(1)
            Issue.record("Expected addition overflow to be rejected.")
        } catch {
            #expect(error == .balanceOverflow)
        }

        let minimum = try EDMoney(balance: EDMoney.minimumBalance)
        do {
            _ = try minimum.subtracting(Int.max)
            Issue.record("Expected subtraction overflow to be rejected.")
        } catch {
            #expect(error == .balanceOverflow)
        }
    }

    @Test("Codable round-trips negative balances")
    func codableRoundTrip() throws {
        let money = try EDMoney(balance: -725)
        let data = try JSONEncoder().encode(money)
        let decoded = try JSONDecoder().decode(EDMoney.self, from: data)

        #expect(decoded == money)
    }

    @Test("Decoding rejects balances below the minimum")
    func decodingRejectsBalanceBelowMinimum() {
        do {
            _ = try JSONDecoder().decode(EDMoney.self, from: Data("-5001".utf8))
            Issue.record("Expected an invalid persisted balance to fail decoding.")
        } catch is DecodingError {
        } catch {
            Issue.record("Unexpected decoding error: \(error)")
        }
    }

    @Test("Money validation errors provide localized descriptions")
    func moneyErrorsHaveLocalizedDescriptions() {
        #expect(EDMoneyError.additionMustBePositive(0).errorDescription != nil)
        #expect(EDMoneyError.subtractionMustBeNonnegative(-1).errorDescription != nil)
    }
}
