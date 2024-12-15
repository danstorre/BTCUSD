import XCTest

struct ExchangeRate: Equatable {
    // TODO: Make private stored properties.
    let symbol: String
    let price: Double
}

class RemoteExchangeRateLoader {
    typealias Result = Swift.Result<ExchangeRate, Error>
    private let client: HTTPClientSpy
    private let url: URL
    
    enum Error: Swift.Error {
        case noConnectivity
        case invalidData
    }
    
    init(client: HTTPClientSpy, url: URL) {
        self.client = client
        self.url = url
    }
    
    func load(completion: @escaping (Result) -> Void) {
        client.getData(from: url) { result in
            switch result {
            case let .success((response, data)): 
                completion(Self.map(response: response, data: data))
            case let .failure(error):
                completion(.failure(.noConnectivity))
            }
        }
    }
    
    // TODO: move mapping into another type.
    struct RemoteExchangeRate: Decodable {
        let symbol: String
        let price: Double
        
        var item: ExchangeRate {
            ExchangeRate(
                symbol: symbol,
                price: price
            )
        }
    }
    
    private static func map(response: HTTPURLResponse, data: Data) -> Result {
        // TODO: check statusCode in a helper method.
        guard response.statusCode == 200, let exchangeRate = try? JSONDecoder().decode(RemoteExchangeRate.self, from: data) else {
            return .failure(.invalidData)
        }
        
        return .success(exchangeRate.item)
    }
}

// TODO: Move this result into HTTPClientSpy.
enum HTTPClientResult {
    case success((HTTPURLResponse, Data))
    case failure(Error)
}

class HTTPClientSpy {
    typealias HTTPClientCompletion = (HTTPClientResult) -> Void
    var loadMessageCallCount: Int {
        requestedURLs.count
    }
    private(set) var requestedURLs = [URL]()
    private var completions = [HTTPClientCompletion]()
    
    func getData(from url: URL, completion: @escaping HTTPClientCompletion) {
        requestedURLs.append(url)
        completions.append(completion)
    }
    
    func failsWith(error: Error, at index: Int = 0) {
        completions[index](HTTPClientResult.failure(error))
    }
    
    func completes(statusCode: Int, data: Data = Data(), at index: Int = 0) {
        let url = requestedURLs[index]
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        completions[index](HTTPClientResult.success((response, data)))
    }
}

final class RemoteExchangeRateLoaderTests: XCTestCase {
    
    func test_init_doesNotMessageHTTPClient() {
        let (_, spy) = makeSUT()
        XCTAssertEqual(spy.loadMessageCallCount, 0)
    }
    
    func test_load_twice_messagesHTTPClientWithCorrectURLTwice() {
        let (sut, spy) = makeSUT()
        let url = URL(string: "http://anyURL.com")!
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(spy.requestedURLs, [url, url])
    }
    
    func test_load_onHTTPClientError_deliversConnectivityError() {
        let (sut, spy) = makeSUT()
        let anyError = NSError(domain: "", code: 1)
        
        expect(sut: sut, toFailWith: .noConnectivity, when: {
            spy.failsWith(error: anyError)
        })
    }
    
    func test_load_onNon2xxHTTPResponse_deliversInvalidDataError() {
        let (sut, spy) = makeSUT()
        
        let samples = [199, 300, 400, 404, 500]
        
        samples.enumerated().forEach { (index, statusCode) in
            expect(sut: sut, toFailWith: .invalidData, when: {
                spy.completes(statusCode: statusCode, at: index)
            })
        }
    }
    
    func test_load_on200HTTPResponseWithInvalidData_deliversInvalidDataError() {
        let (sut, spy) = makeSUT()
        
        expect(sut: sut, toFailWith: .invalidData, when: {
            spy.completes(statusCode: 200, data: Data("InvalidData".utf8))
        })
    }
    
    func test_load_on200HTTPResponseWithEmptyData_deliversInvalidDataError() {
        let (sut, spy) = makeSUT()
        
        expect(sut: sut, toFailWith: .invalidData, when: {
            spy.completes(statusCode: 200, data: Data("".utf8))
        })
    }
    
    func test_load_on200HTTPResponseWithItemData_deliversExchangeRate() throws {
        let (sut, spy) = makeSUT()
        
        // TODO: create helper methods to create a tuple for remote/model object.
        let remoteModel: [String: Any] = [
            "symbol": "BTCUSDT",
            "price": 103312.60000000
        ]
        
        let model = ExchangeRate(
            symbol: "BTCUSDT",
            price: 103312.60000000
        )
        
        // TODO: create helper method to encode the remote JSON object.
        let data = try JSONSerialization.data(withJSONObject: remoteModel)
        
        expect(sut: sut, toSucceedWith: model, when: {
            spy.completes(statusCode: 200, data: data)
        })
    }
    
    // MARK: - Helpers
    // TODO: create a helper method to reduce duplication from expect functions.
    private func expect(
        sut: RemoteExchangeRateLoader,
        toSucceedWith expectedResult: ExchangeRate,
        when action: @escaping () -> Void, file: StaticString = #filePath,
                   line: UInt = #line) {
        var receivedResult: ExchangeRate?
        
        sut.load { result in
            if case .success(let result) = result {
                receivedResult = result
            }
        }
        
        action()
        
        XCTAssertEqual(receivedResult, expectedResult, "Expected \(expectedResult), got \(String(describing: receivedResult)) instead", file: file, line: line)
    }
    
    private func expect(
        sut: RemoteExchangeRateLoader,
        toFailWith expectedError: RemoteExchangeRateLoader.Error,
        when action: @escaping () -> Void, file: StaticString = #filePath,
                   line: UInt = #line) {
        var receivedResult: RemoteExchangeRateLoader.Error?
        
        sut.load { result in
            if case .failure(let result) = result {
                receivedResult = result
            }
        }
        
        action()
        
        XCTAssertEqual(receivedResult, expectedError, "Expected \(expectedError) error, got \(String(describing: receivedResult)) instead", file: file, line: line)
    }
    
    private func makeSUT(url: URL = URL(string: "http://anyURL.com")!) -> (sut: RemoteExchangeRateLoader, spy: HTTPClientSpy) {
        let spy = HTTPClientSpy()
        let sut = RemoteExchangeRateLoader(client: spy, url: url)
        return (sut, spy)
    }
}
