//
//  MockPlayer.swift
//  Executive Decision
//

struct MockPlayer: Identifiable, Hashable {
    let id: String
    let name: String
    let avatarResource: String
    let coins: Int
    let cardCount: Int

    static let rex = MockPlayer(
        id: "rex",
        name: "Rex",
        avatarResource: "avt-1",
        coins: 1_250,
        cardCount: 3
    )
    static let saxon = MockPlayer(
        id: "saxon",
        name: "Saxon",
        avatarResource: "avt-2",
        coins: 900,
        cardCount: 2
    )
    static let gordon = MockPlayer(
        id: "gordon",
        name: "Gordon",
        avatarResource: "avt-3",
        coins: -150,
        cardCount: 4
    )
    static let dean = MockPlayer(
        id: "dean",
        name: "Dean",
        avatarResource: "avt-4",
        coins: 325,
        cardCount: 1
    )
    static let morgan = MockPlayer(
        id: "morgan",
        name: "Morgan",
        avatarResource: "avt-5",
        coins: -700,
        cardCount: 5
    )
    static let alex = MockPlayer(
        id: "alex",
        name: "Alex",
        avatarResource: "avt-6",
        coins: 2_100,
        cardCount: 2
    )

    static let roster = [rex, saxon, gordon, dean, morgan, alex]
}
