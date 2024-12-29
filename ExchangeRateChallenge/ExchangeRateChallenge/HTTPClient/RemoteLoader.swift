import Foundation

public class RemoteLoader<T> {
    private let client: HTTPClient
    private let url: URL
    private let mapper: ((response: HTTPURLResponse, data: Data)) -> Result
    public typealias Result = Swift.Result<T, RemoteLoader.Error>
    
    public enum Error: Swift.Error {
        case noConnectivity
        case invalidData
    }
    
    public init(client: HTTPClient, url: URL, mapper: @escaping ((response: HTTPURLResponse, data: Data)) -> Result) {
        self.client = client
        self.url = url
        self.mapper = mapper
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.getData(from: url) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success((response, data)):
                completion(self.mapper((response, data)))
            case .failure:
                completion(.failure(Error.noConnectivity))
            }
        }
    }
}
