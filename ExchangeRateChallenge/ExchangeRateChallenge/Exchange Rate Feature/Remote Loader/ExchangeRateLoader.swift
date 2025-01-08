import Foundation

public protocol ExchangeRateLoader {
    typealias Result = Swift.Result<ExchangeRate, Error>
    func load(completion: @escaping (Result) -> Void)
}
