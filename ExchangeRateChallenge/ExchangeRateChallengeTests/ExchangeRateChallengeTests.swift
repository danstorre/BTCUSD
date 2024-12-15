import XCTest

class RemoteExchangeRateLoader {
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
    
    func load(completion: @escaping (Error) -> Void) {
        client.getData(from: url) { (response, error) in
            guard error != nil else {
                completion(.invalidData)
                return
            }
            completion(.noConnectivity)
        }
    }
}

class HTTPClientSpy {
    typealias HTTPClientCompletion = ((HTTPURLResponse, Data?)?, Error?) -> Void
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
        completions[index](nil, error)
    }
    
    func completes(statusCode: Int, data: Data?, at index: Int = 0) {
        let url = requestedURLs[index]
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        completions[index]((response, data), nil)
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
        
        var receivedError: RemoteExchangeRateLoader.Error?
        sut.load { error in receivedError = error }
        spy.failsWith(error: anyError)
        
        XCTAssertEqual(receivedError, .noConnectivity)
    }
    
    func test_load_onNon2xxHTTPResponse_deliversInvalidDataError() {
        let (sut, spy) = makeSUT()
        
        let samples = [199, 300, 400, 404, 500]
        
        samples.enumerated().forEach { (index, statusCode) in
            expectToFailWithInvalidData(sut: sut, when: {
                spy.completes(statusCode: statusCode, data: .none, at: index)
            })
        }
    }
    
    func test_load_on200HTTPResponseWithInvalidData_deliversInvalidDataError() {
        let (sut, spy) = makeSUT()
        
        expectToFailWithInvalidData(sut: sut, when: {
            spy.completes(statusCode: 200, data: Data("InvalidData".utf8))
        })
    }
    
    func test_load_on200HTTPResponseWithEmptyData_deliversInvalidDataError() {
        let (sut, spy) = makeSUT()
        
        expectToFailWithInvalidData(sut: sut, when: {
            spy.completes(statusCode: 200, data: Data("".utf8))
        })
    }
    
    // MARK: - Helpers
    
    private func expectToFailWithInvalidData(sut: RemoteExchangeRateLoader, when action: @escaping () -> Void, file: StaticString = #filePath,
                   line: UInt = #line) {
        var receivedError: RemoteExchangeRateLoader.Error?
        
        sut.load { error in
            receivedError = error
        }
        
        action()
        
        XCTAssertEqual(receivedError, .invalidData, "Expected invalidData error, got \(String(describing: receivedError)) instead", file: file, line: line)
    }
    private func makeSUT(url: URL = URL(string: "http://anyURL.com")!) -> (sut: RemoteExchangeRateLoader, spy: HTTPClientSpy) {
        let spy = HTTPClientSpy()
        let sut = RemoteExchangeRateLoader(client: spy, url: url)
        return (sut, spy)
    }
}
