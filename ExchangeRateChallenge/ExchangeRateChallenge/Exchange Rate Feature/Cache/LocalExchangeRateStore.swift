import Foundation

public protocol LocalExchangeRateStore {
    func delete() throws
    func insert(exchangeRate: CacheExchangeRate.LocalExchangeRate) throws
}
