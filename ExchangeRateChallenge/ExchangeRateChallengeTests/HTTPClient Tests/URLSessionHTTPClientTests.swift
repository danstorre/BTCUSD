import XCTest
import ExchangeRateChallenge

class URLSessionHTTPClient {
    let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func getData(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingNetworkCalls()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingNetworkCalls()
    }
    
    func test_getData_performsGETRequestWithURL() {
        let url = URL(string: "http://example.com")!
        let expectation = expectation(description: "wait for url request.")
        
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            expectation.fulfill()
        }
        
        URLSessionHTTPClient().getData(from: url) { _ in }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_getData_onError_DeliversError() {
        let url = URL(string: "http://example.com")!
        let error = NSError(domain: "", code: 1)
        URLProtocolStub.stub = URLProtocolStub.Stub(data: nil, response: nil, error: error)
        let sut = URLSessionHTTPClient()
        
        let expectation = expectation(description: "waiting for response")
        
        sut.getData(from: url) { result in
            switch result {
            case .failure(let receivedError):
                XCTAssertEqual((receivedError as NSError).code, error.code)
                XCTAssertEqual((receivedError as NSError).domain, error.domain)
            default:
                XCTFail("expected failuer with error: \(error) but got: \(result)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    class URLProtocolStub: URLProtocol {
        static var stub: Stub?
        static var requestObserver: ((URLRequest) -> Void)?
        struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func observeRequest(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        static override func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }
        
        static override func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            if let data = Self.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = Self.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = Self.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {
        }
        
        static func startInterceptingNetworkCalls() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingNetworkCalls() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            Self.stub = nil
        }
    }
}
