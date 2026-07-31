import Foundation

public enum ProductType: Int, CaseIterable {
    case a,b,c
    
    public var openingPrice: Int {
        switch self {
        case .a: return 140
        case .b: return 115
        case .c: return 90
        }
    }
}