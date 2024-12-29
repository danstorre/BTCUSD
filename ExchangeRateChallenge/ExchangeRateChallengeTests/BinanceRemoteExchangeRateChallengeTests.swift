import XCTest
import ExchangeRateChallenge

final class BinanceRemoteExchangeRateLoaderTests: XCTestCase {
    
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
        
        expect(sut: sut, toCompleteWith: failure(.noConnectivity), when: {
            spy.failsWith(error: anyError)
        })
    }
    
    func test_load_onNon2xxHTTPResponse_deliversInvalidDataError() {
        let (sut, spy) = makeSUT()
        
        let samples = [199, 300, 400, 404, 500]
        
        samples.enumerated().forEach { (index, statusCode) in
            expect(sut: sut, toCompleteWith: failure(.invalidData), when: {
                spy.completes(statusCode: statusCode, at: index)
            })
        }
    }
    
    func test_load_on200HTTPResponseWithInvalidData_deliversInvalidDataError() {
        let (sut, spy) = makeSUT()
        
        expect(sut: sut, toCompleteWith: failure(.invalidData), when: {
            spy.completes(statusCode: 200, data: Data("InvalidData".utf8))
        })
    }
    
    func test_load_on200HTTPResponseWithEmptyData_deliversInvalidDataError() {
        let (sut, spy) = makeSUT()
        
        expect(sut: sut, toCompleteWith: failure(.invalidData), when: {
            spy.completes(statusCode: 200, data: Data("".utf8))
        })
    }
    
    func test_load_on200HTTPResponseWithItemData_deliversExchangeRate() throws {
        let (sut, spy) = makeSUT()
        let exchangeRate = createExchangeRate(symbol: "BTCUSDT", price: 103312.60000000)
        let data = try encode(exchangeRate.remote)
        
        expect(sut: sut, toCompleteWith: success(with: exchangeRate.model), when: {
            spy.completes(statusCode: 200, data: data)
        })
    }
    
    func test_onDeallocation_shouldNotDeliverResult() {
        let spy = HTTPClientSpy()
        let url = URL(string: "https://www.anyURL.com")!
        var sut: BinanceRemoteExchangeRateLoader? = BinanceRemoteExchangeRateLoader(client: spy, url: url)
        var receivedResult: Result<ExchangeRate, Error>?
        
        sut?.load { result in
            receivedResult = result
        }
        sut = nil
        
        spy.completes(statusCode: 200)
        
        XCTAssertNil(receivedResult, "Exchange rate should not be delivered when deallocated")
    }
    
    // MARK: - Helpers
    private func createExchangeRate(symbol: String, price: Double) -> (model: ExchangeRate, remote: [String: Any]) {
        let remoteModel: [String: Any] = [
            "symbol": "BTCUSDT",
            "price": 103312.60000000
        ]
        
        let model = ExchangeRate(
            symbol: "BTCUSDT",
            price: 103312.60000000
        )
        
        return (model, remoteModel)
    }
    
    private func encode(_ json: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: json)
    }
    
    private func failure(_ error: BinanceRemoteExchangeRateLoader.Error) -> ExchangeRateLoader.Result {
        .failure(error)
    }
    
    private func success(with result: ExchangeRate) -> ExchangeRateLoader.Result {
        .success(result)
    }
    
    private func expect(
        sut: ExchangeRateLoader,
        toCompleteWith expectedResult: ExchangeRateLoader.Result,
        when action: @escaping () -> Void, file: StaticString = #filePath,
                   line: UInt = #line) {
                       
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedResult), .success(expectedResult)):
                XCTAssertEqual(receivedResult, expectedResult, "Expected \(expectedResult), got \(String(describing: receivedResult)) instead", file: file, line: line)
            
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError.code, expectedError.code, "Expected \(expectedError) error, got \(String(describing: receivedError)) instead", file: file, line: line)
                
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
        }
        
        action()
    }
    
    private func makeSUT(url: URL = URL(string: "http://anyURL.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: ExchangeRateLoader, spy: HTTPClientSpy) {
        let spy = HTTPClientSpy()
        let sut = BinanceRemoteExchangeRateLoader(client: spy, url: url)
        
        trackForMemoryLeaks(spy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, spy)
    }
    
    private class HTTPClientSpy: HTTPClient {
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
}
