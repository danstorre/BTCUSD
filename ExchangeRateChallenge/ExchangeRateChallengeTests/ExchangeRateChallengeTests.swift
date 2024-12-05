import XCTest

class RemoteExchangeRateLoader {
    private let client: HTTPClientSpy
    
    init(client: HTTPClientSpy) {
        self.client = client
    }
    
    func load() {
        client.getData()
    }
}

class HTTPClientSpy {
    private(set) var loadMessageCallCount = 0
    
    func getData() {
        loadMessageCallCount += 1
    }
}

final class RemoteExchangeRateLoaderTests: XCTestCase {
    
    func test_init_doesNotMessageHTTPClient() {
        let spy = HTTPClientSpy()
        let _ = RemoteExchangeRateLoader(client: spy)
        
        XCTAssertEqual(spy.loadMessageCallCount, 0)
    }
    
    func test_load_messagesHTTPClient() {
        let spy = HTTPClientSpy()
        let sut = RemoteExchangeRateLoader(client: spy)
        
        sut.load()
        
        XCTAssertEqual(spy.loadMessageCallCount, 1)
    }
}
