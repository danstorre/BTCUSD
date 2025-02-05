import Foundation

public typealias CachedExchangeRate = (exchangeRate: LocalExchangeRateStore.LocalExchangeRate, timestamp: Date)

public protocol ExchangeRateStoreCache {
    func delete() throws
    func insert(exchangeRate: LocalExchangeRateStore.LocalExchangeRate, timestamp: Date) throws
    func retrieve() throws -> CachedExchangeRate?
}
