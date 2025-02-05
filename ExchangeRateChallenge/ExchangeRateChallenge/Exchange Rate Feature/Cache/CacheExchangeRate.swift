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
    private let currentDate: () -> Date
    
    public init(store: LocalExchangeRateStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension CacheExchangeRate {
    public enum LoadError: Swift.Error {
        case loadError(Swift.Error)
    }
    
    public func loadCache() throws -> ExchangeRate? {
        do {
            guard let local = try store.retrieve() else {
                return .none
            }
            return ExchangeRate(symbol: local.symbol, price: local.price)
        } catch {
            try? store.delete()
            throw LoadError.loadError(error)
        }
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
            try store.insert(exchangeRate: exchangeRate.local, timestamp: currentDate())
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
