import XCTest

class RemoteExchangeRateLoader {
    private let client: HTTPClientSpy
    private let url: URL
    
    enum Error: Swift.Error {
        case noConnectivity
    }
    
    init(client: HTTPClientSpy, url: URL) {
        self.client = client
        self.url = url
    }
    
    func load(completion: @escaping (Error) -> Void) {
        client.getData(from: url) { response in
            completion(.noConnectivity)
        }
    }
}

class HTTPClientSpy {
    typealias HTTPClientCompletion = (Error) -> Void
    var loadMessageCallCount: Int {
        requestedURLs.count
    }
    private(set) var requestedURLs = [URL]()
    private var completions = [HTTPClientCompletion]()
    
    func getData(from url: URL, completion: @escaping HTTPClientCompletion) {
        requestedURLs.append(url)
        completions.append(completion)
    }
    
    func completesWith(error: Error, at index: Int = 0) {
        completions[index](error)
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
        spy.completesWith(error: anyError)
        
        XCTAssertEqual(receivedError, .noConnectivity)
    }
    
    // MARK: - Helpers
    private func makeSUT(url: URL = URL(string: "http://anyURL.com")!) -> (sut: RemoteExchangeRateLoader, spy: HTTPClientSpy) {
        let spy = HTTPClientSpy()
        let sut = RemoteExchangeRateLoader(client: spy, url: url)
        return (sut, spy)
    }
}
