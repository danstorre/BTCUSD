import Foundation

enum CryptoExchangeRateRemoteExchangeRateMapper {
    private struct Root: Decodable {
        let raw: RemoteExchangeRate
        
        enum CodingKeys: String, CodingKey {
            case raw = "RAW"
        }
        
        var item: ExchangeRate {
            ExchangeRate(
                symbol: "\(raw.fromSympol)\(raw.toSymbol)",
                price: raw.price
            )
        }
    }
    
    private struct RemoteExchangeRate: Decodable {
        let fromSympol: String
        let toSymbol: String
        let price: Double
        
        enum CodingKeys: String, CodingKey {
            case fromSymbol = "FROMSYMBOL"
            case toSymbol = "TOSYMBOL"
            case price = "PRICE"
        }
        
        init(from decoder: any Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            fromSympol = try values.decode(String.self, forKey: .fromSymbol)
            toSymbol = try values.decode(String.self, forKey: .toSymbol)
            price = try values.decode(Double.self, forKey: .price)
        }
    }
    
    static func map(response: HTTPURLResponse, data: Data) -> CryptoExchangeRateRemoteExchangeRateLoader.Result {
        guard Self.isOK(httpStatusCode: response.statusCode),
              let exchangeRate = try? JSONDecoder().decode(Root.self, from: data)
        else {
            return .failure(CryptoExchangeRateRemoteExchangeRateLoader.Error.invalidData)
        }
        
        return .success(exchangeRate.item)
    }
    
    private static func isOK(httpStatusCode: Int) -> Bool {
        httpStatusCode == 200
    }
}
