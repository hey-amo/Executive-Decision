//
//  MockPlayer.swift
//  Executive Decision
//
import EDEngine

struct MockPlayer: Identifiable, Hashable {
    let id: String
    let name: String
    let avatarResource: String
    let coins: Int
    let cardCount: Int
    let isActive: Bool

    // Needs to be reworked so I can set active, inactive
    static let rex = MockPlayer(
        id: "rex",
        name: "Rex",
        avatarResource: "avt-1",
        coins: 1_250,
        cardCount: 3,
        isActive: true
    )
    static let saxon = MockPlayer(
        id: "saxon",
        name: "Saxon",
        avatarResource: "avt-2",
        coins: 900,
        cardCount: 2,
        isActive: false
    )
    static let gordon = MockPlayer(
        id: "gordon",
        name: "Gordon",
        avatarResource: "avt-3",
        coins: -150,
        cardCount: 4,
        isActive: false
    )
    static let dean = MockPlayer(
        id: "dean",
        name: "Dean",
        avatarResource: "avt-4",
        coins: 325,
        cardCount: 1,
        isActive: false
    )
    static let morgan = MockPlayer(
        id: "morgan",
        name: "Morgan",
        avatarResource: "avt-5",
        coins: -700,
        cardCount: 5,
        isActive: false
    )
    static let alex = MockPlayer(
        id: "alex",
        name: "Alex",
        avatarResource: "avt-6",
        coins: 2_100,
        cardCount: 2,
        isActive: false
    )

    static let roster = [rex, saxon, gordon, dean, morgan, alex]
}
