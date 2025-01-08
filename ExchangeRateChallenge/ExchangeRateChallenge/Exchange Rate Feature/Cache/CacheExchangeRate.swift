import Foundation

public class CacheExchangeRate {
    public struct LocalExchangeRate: Equatable {
        let symbol: String
        let price: Double
        
        public init(symbol: String, price: Double) {
            self.symbol = symbol
            self.price = price
        }
    }
    
    private let store: LocalExchangeRateStore
    
    public enum Error: Swift.Error {
        case deletionError(Swift.Error)
        case insertionError(Swift.Error)
    }
    
    public init(store: LocalExchangeRateStore) {
        self.store = store
    }
    
    public func cache(exchangeRate: ExchangeRate) throws {
        do {
            try store.delete()
        } catch {
            throw Error.deletionError(error)
        }
        
        do {
            try store.insert(exchangeRate: exchangeRate.local)
        } catch {
            throw Error.insertionError(error)
        }
    }
}

private extension ExchangeRate {
    var local: CacheExchangeRate.LocalExchangeRate {
        CacheExchangeRate.LocalExchangeRate(symbol: symbol,
                                            price: price)
    }
}
