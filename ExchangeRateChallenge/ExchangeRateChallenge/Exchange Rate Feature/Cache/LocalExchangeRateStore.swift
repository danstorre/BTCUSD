import Foundation

public typealias ExchangeRateTimestamped = (exchangeRate: ExchangeRate, timestamp: Date)

public class LocalExchangeRateStore {
    public struct LocalExchangeRate: Equatable {
        let symbol: String
        let price: Double
        
        public init(symbol: String, price: Double) {
            self.symbol = symbol
            self.price = price
        }
    }
    
    private let store: ExchangeRateStoreCache
    private let currentDate: () -> Date
    
    public init(store: ExchangeRateStoreCache, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalExchangeRateStore {
    public enum LoadError: Swift.Error {
        case loadError(Swift.Error)
    }
    
    public func loadCache() throws -> ExchangeRateTimestamped? {
        do {
            guard let local = try store.retrieve() else {
                return .none
            }
            let exchangeRate = ExchangeRate(symbol: local.exchangeRate.symbol, price: local.exchangeRate.price)
            let timestamp = local.timestamp
            return (exchangeRate, timestamp)
        } catch {
            try? store.delete()
            throw LoadError.loadError(error)
        }
    }
}

extension LocalExchangeRateStore {
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
    var local: LocalExchangeRateStore.LocalExchangeRate {
        LocalExchangeRateStore.LocalExchangeRate(symbol: symbol,
                                            price: price)
    }
}
