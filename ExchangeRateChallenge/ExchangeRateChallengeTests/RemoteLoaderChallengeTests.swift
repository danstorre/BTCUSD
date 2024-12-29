import XCTest
import ExchangeRateChallenge

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
        
        expect(sut: sut, toCompleteWith: failure(.noConnectivity), when: {
            spy.failsWith(error: anyError)
        })
    }
    
    func test_load_on200HTTPResponseWithItemData_deliversExchangeRate() throws {
        let anyString: String = "anyString"
        let (sut, spy) = makeSUT { _ in .success(anyString) }
        let data = anyString.data(using: .utf8)!
        
        expect(sut: sut, toCompleteWith: success(with: anyString), when: {
            spy.completes(statusCode: 200, data: data)
        })
    }
    
    func test_onDeallocation_shouldNotDeliverResult() {
        let spy = HTTPClientSpy()
        let url = URL(string: "https://www.anyURL.com")!
        var sut: RemoteLoader<String>? = RemoteLoader<String>(client: spy, url: url, mapper: { _ in .success("") })
        var receivedResult: RemoteLoader<String>.Result?
        
        sut?.load { result in
            receivedResult = result
        }
        sut = nil
        
        spy.completes(statusCode: 200)
        
        XCTAssertNil(receivedResult, "Exchange rate should not be delivered when deallocated")
    }
    
    // MARK: - Helpers
    private func encode(_ json: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: json)
    }
    
    private func failure(_ error: RemoteLoader<String>.Error) -> RemoteLoader<String>.Result {
        .failure(error)
    }
    
    private func success(with result: String) -> RemoteLoader<String>.Result {
        .success(result)
    }
    
    private func expect(
        sut: RemoteLoader<String>,
        toCompleteWith expectedResult: RemoteLoader<String>.Result,
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
    
    private func makeSUT(
        url: URL = URL(string: "http://anyURL.com")!,
        mapper: @escaping ((response: HTTPURLResponse, data: Data)) -> Result<String, RemoteLoader<String>.Error> = { _ in .success("")},
        file: StaticString = #filePath,
        line: UInt = #line) -> (sut: RemoteLoader<String>, spy: HTTPClientSpy) {
            let spy = HTTPClientSpy()
            let sut = RemoteLoader<String>(client: spy, url: url, mapper: mapper)
            
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
