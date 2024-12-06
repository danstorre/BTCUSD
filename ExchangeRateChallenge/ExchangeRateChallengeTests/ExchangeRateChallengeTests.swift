import XCTest

class RemoteExchangeRateLoader {
    private let client: HTTPClientSpy
    private let url: URL
    
    init(client: HTTPClientSpy, url: URL) {
        self.client = client
        self.url = url
    }
    
    func load() {
        client.getData(from: url)
    }
}

class HTTPClientSpy {
    var loadMessageCallCount: Int {
        requestedURLs.count
    }
    private(set) var requestedURLs = [URL]()
    
    func getData(from url: URL) {
        requestedURLs.append(url)
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
        
        sut.load()
        sut.load()
        
        XCTAssertEqual(spy.requestedURLs, [anyURL, anyURL])
    }
}
