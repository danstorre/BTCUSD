import Foundation

public class RemoteExchangeRateLoader {
    public typealias Result = Swift.Result<ExchangeRate, Error>
    private let client: HTTPClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case noConnectivity
        case invalidData
    }
    
    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.getData(from: url) { result in
            switch result {
            case let .success((response, data)):
                completion(RemoteExchangeRateMapper.map(response: response, data: data))
            case .failure:
                completion(.failure(.noConnectivity))
            }
        }
    }
}
