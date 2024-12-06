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
    var loadMessageCallCount: Int {
        requestedURLs.count
    }
    private(set) var requestedURLs = [URL]()
    private var completions = [(Error) -> Void]()
    
    func getData(from url: URL, completion: @escaping (Error) -> Void) {
        requestedURLs.append(url)
        completions.append(completion)
    }
    
    func completesWith(error: Error, at index: Int = 0) {
        completions[index](error)
    }
}

final class RemoteExchangeRateLoaderTests: XCTestCase {
    
    func test_init_doesNotMessageHTTPClient() {
        let spy = HTTPClientSpy()
        let anyURL = URL(string: "http://anyURL.com")!
        let _ = RemoteExchangeRateLoader(client: spy, url: anyURL)
        
        XCTAssertEqual(spy.loadMessageCallCount, 0)
    }
    
    func test_load_twice_messagesHTTPClientWithCorrectURLTwice() {
        let spy = HTTPClientSpy()
        let anyURL = URL(string: "http://anyURL.com")!
        let sut = RemoteExchangeRateLoader(client: spy, url: anyURL)
        
        sut.load() { _ in }
        sut.load() { _ in }
        
        XCTAssertEqual(spy.requestedURLs, [anyURL, anyURL])
    }
    
    func test_load_onHTTPClientError_deliversConnectivityError() {
        let spy = HTTPClientSpy()
        let anyError = NSError(domain: "", code: 1)
        let anyURL = URL(string: "http://anyURL.com")!
        let sut = RemoteExchangeRateLoader(client: spy, url: anyURL)
        
        var receivedError: RemoteExchangeRateLoader.Error?
        sut.load() { error in
            receivedError = error
        }
        spy.completesWith(error: anyError)
        
        XCTAssertEqual(receivedError, .noConnectivity)
    }
}
