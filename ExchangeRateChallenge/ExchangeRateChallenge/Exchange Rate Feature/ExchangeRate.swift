import Foundation

public struct ExchangeRate: Equatable {
    private let symbol: String
    private let price: Double
    
    public init(symbol: String, price: Double) {
        self.symbol = symbol
        self.price = price
    }
}

