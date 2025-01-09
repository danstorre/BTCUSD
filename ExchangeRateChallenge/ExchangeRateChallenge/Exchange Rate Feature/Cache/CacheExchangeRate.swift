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
    
    public init(store: LocalExchangeRateStore) {
        self.store = store
    }
}

extension CacheExchangeRate {
    public enum SaveError: Swift.Error {
        case deletionError(Swift.Error)
        case insertionError(Swift.Error)
    }
    
    public func cache(exchangeRate: ExchangeRate) throws {
        do {
            try store.delete()
        } catch {
            throw SaveError.deletionError(error)
        }
        
        do {
            try store.insert(exchangeRate: exchangeRate.local)
        } catch {
            throw SaveError.insertionError(error)
        }
    }
}

private extension ExchangeRate {
    var local: CacheExchangeRate.LocalExchangeRate {
        CacheExchangeRate.LocalExchangeRate(symbol: symbol,
                                            price: price)
    }
}
