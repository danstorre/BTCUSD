import Foundation

public struct ExchangeRate: Equatable {
    public let symbol: String
    public let price: Double
    
    public init(symbol: String, price: Double) {
        self.symbol = symbol
        self.price = price
    }
}

