import Foundation

enum RemoteExchangeRateMapper {
    private struct RemoteExchangeRate: Decodable {
        let symbol: String
        let price: Double
        
        var item: ExchangeRate {
            ExchangeRate(
                symbol: symbol,
                price: price
            )
        }
    }
    
    static func map(response: HTTPURLResponse, data: Data) -> RemoteExchangeRateLoader.Result {
        guard Self.isOK(httpStatusCode: response.statusCode),
              let exchangeRate = try? JSONDecoder().decode(RemoteExchangeRate.self, from: data)
        else {
            return .failure(RemoteExchangeRateLoader.Error.invalidData)
        }
        
        return .success(exchangeRate.item)
    }
    
    private static func isOK(httpStatusCode: Int) -> Bool {
        httpStatusCode == 200
    }
}
