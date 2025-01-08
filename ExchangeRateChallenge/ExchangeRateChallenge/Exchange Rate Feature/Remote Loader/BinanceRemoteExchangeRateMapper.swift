import Foundation

public enum BinanceRemoteExchangeRateMapper {
    public enum Error: Swift.Error {
        case invalidData
    }
    
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
    
    public static func map(response: HTTPURLResponse, data: Data) -> ExchangeRateLoader.Result {
        guard Self.isOK(httpStatusCode: response.statusCode),
              let exchangeRate = try? JSONDecoder().decode(RemoteExchangeRate.self, from: data)
        else {
            return .failure(BinanceRemoteExchangeRateMapper.Error.invalidData)
        }
        
        return .success(exchangeRate.item)
    }
    
    private static func isOK(httpStatusCode: Int) -> Bool {
        httpStatusCode == 200
    }
}
