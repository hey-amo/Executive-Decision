// EDRawMaterialGrade.swift — XFine, Fine, Standard.~~

// AGENT: Do not change raw material certificate enum's.

// The game has 3 types of raw material grades: Extra Fine, Fine, and Standard. 
// These grades are used to determine the quality of raw materials in the game.
public enum EDRawMaterialGrade: Int, CaseIterable, Codable, Hashable, Sendable {
    case fine, xfine, standard
}
