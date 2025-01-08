import Foundation

public protocol ExchangeRateStore {
    func delete() throws
    func insert(exchangeRate: CacheExchangeRate.LocalExchangeRate) throws
}
