import Foundation

public protocol LocalExchangeRateStore {
    func delete() throws
    func insert(exchangeRate: CacheExchangeRate.LocalExchangeRate, timestamp: Date) throws
    func retrieve() throws -> CacheExchangeRate.LocalExchangeRate?
}
