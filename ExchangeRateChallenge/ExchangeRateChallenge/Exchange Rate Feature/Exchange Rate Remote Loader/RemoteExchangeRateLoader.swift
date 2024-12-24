import Foundation

public class RemoteExchangeRateLoader: ExchangeRateLoader {
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
    
    public func load(completion: @escaping (ExchangeRateLoader.Result) -> Void) {
        client.getData(from: url) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case let .success((response, data)):
                completion(RemoteExchangeRateMapper.map(response: response, data: data))
            case .failure:
                completion(.failure(Error.noConnectivity))
            }
        }
    }
}
