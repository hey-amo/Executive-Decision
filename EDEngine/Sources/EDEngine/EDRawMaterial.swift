import Foundation

public enum RawMaterial: Int, CaseIterable {
    case xfine, fine, standard
    
    public var openingPrice: Int {
        switch self {
        case .xfine: return 40
        case .fine: return 30
        case .standard: return 20
        }
    }
}

extension RawMaterial: CustomStringConvertible {
    public var description: String {
        switch self {
        case .xfine: return "X-Fine"
        case .fine: return "Fine"
        case .standard: return "Standard"
        }
    }
}