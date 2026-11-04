//
//  Executive_DecisionTests.swift
//  Executive-DecisionTests
//
//  Created by Amarjit on 30/10/2026.
//

import XCTest
import EDEngine
@testable import Executive_Decision

final class Executive_DecisionTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPlayerRosterRequiresTwoPlayersAndKeepsFirstPlayerHuman() {
        let firstPlayer = EDPlayer(name: "Vivian", avatar: .avt5, isAI: true)
        let viewModel = PlayerRosterViewModel(firstPlayer: firstPlayer)

        XCTAssertFalse(firstPlayer.isAI)
        XCTAssertFalse(viewModel.canContinue)
        XCTAssertEqual(viewModel.players.count, 1)
        XCTAssertFalse(viewModel.availableCharacters.contains { $0.avatar == .avt5 })

        viewModel.removePlayer(id: firstPlayer.id)

        XCTAssertEqual(viewModel.players.map(\.id), [firstPlayer.id])
        XCTAssertTrue(viewModel.players.contains { !$0.isAI })
    }

    func testPlayerRosterAddsAvailablePlayersAndEnforcesMaximum() throws {
        let firstPlayer = EDPlayer(name: "Vivian", avatar: .avt5)
        let viewModel = PlayerRosterViewModel(firstPlayer: firstPlayer)
        let rex = try XCTUnwrap(viewModel.availableCharacters.first { $0.avatar == .avt1 })

        viewModel.addPlayer(rex, isAI: true)

        XCTAssertTrue(viewModel.canContinue)
        XCTAssertEqual(viewModel.players.count, 2)
        XCTAssertTrue(viewModel.players[1].isAI)

        viewModel.addPlayer(rex, isAI: false)
        XCTAssertEqual(viewModel.players.count, 2)

        for character in viewModel.availableCharacters {
            viewModel.addPlayer(character, isAI: true)
        }

        XCTAssertEqual(viewModel.players.count, kConstants.maxPlayers)
        XCTAssertTrue(viewModel.availableCharacters.isEmpty)
        XCTAssertTrue(viewModel.canContinue)

        viewModel.removePlayer(id: viewModel.players[1].id)

        XCTAssertEqual(viewModel.players.count, kConstants.maxPlayers - 1)
        XCTAssertTrue(viewModel.players.contains { !$0.isAI })
    }

    func testPlayerRosterCanEditNonFirstPlayerCharacterAndType() throws {
        let firstPlayer = EDPlayer(name: "Vivian", avatar: .avt5)
        let viewModel = PlayerRosterViewModel(firstPlayer: firstPlayer)
        let rex = try XCTUnwrap(viewModel.availableCharacters.first { $0.avatar == .avt1 })
        viewModel.addPlayer(rex, isAI: false)
        let playerID = try XCTUnwrap(viewModel.players.last?.id)
        let saxon = try XCTUnwrap(viewModel.availableCharacters.first { $0.avatar == .avt2 })

        viewModel.updatePlayer(id: playerID, to: saxon, isAI: true)

        XCTAssertEqual(viewModel.players.last?.id, playerID)
        XCTAssertEqual(viewModel.players.last?.name, saxon.name)
        XCTAssertEqual(viewModel.players.last?.avatarResource, saxon.avatar)
        XCTAssertTrue(viewModel.players.last?.isAI == true)
        XCTAssertTrue(viewModel.availableCharacters.contains { $0.avatar == rex.avatar })
        XCTAssertFalse(viewModel.availableCharacters.contains { $0.avatar == saxon.avatar })

        viewModel.updatePlayer(id: firstPlayer.id, to: rex, isAI: true)
        XCTAssertFalse(firstPlayer.isAI)
        XCTAssertEqual(firstPlayer.avatarResource, .avt5)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
