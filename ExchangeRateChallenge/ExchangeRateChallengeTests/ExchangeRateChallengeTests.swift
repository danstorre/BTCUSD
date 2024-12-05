import XCTest

class RemoteExchangeRateLoader {
    private let client: HTTPClientSpy
    
    init(client: HTTPClientSpy) {
        self.client = client
    }
    
}

class HTTPClientSpy {
    private(set) var loadMessageCallCount = 0
}

final class RemoteExchangeRateLoaderTests: XCTestCase {
    
    func test_init_doesNotMessageHTTPClient() {
        let spy = HTTPClientSpy()
        let _ = RemoteExchangeRateLoader(client: spy)
        
        XCTAssertEqual(spy.loadMessageCallCount, 0)
    }
}
