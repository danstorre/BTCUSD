import XCTest
import ExchangeRateChallenge

class URLSessionHTTPClient {
    let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    struct UnexpectedValuesRepresentation: Error {}
    
    func getData(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
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
        let url = makeAnyURL()
        let expectation = expectation(description: "wait for url request.")
        
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            expectation.fulfill()
        }
        
        makeSUT().getData(from: url) { _ in }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_getData_onError_DeliversError() {
        let error = NSError(domain: "", code: 1)
        URLProtocolStub.stub(data: nil, response: nil, error: error)
        let expectation = expectation(description: "waiting for response")
        
        makeSUT().getData(from: makeAnyURL()) { result in
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
    
    func test_getData_failsOnNilValues() {
        URLProtocolStub.stub(data: nil, response: nil, error: nil)
        let expectation = expectation(description: "waiting for response")
        
        makeSUT().getData(from: makeAnyURL()) { result in
            switch result {
            case .failure:
                break
            default:
                XCTFail("expected failure with error")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Helpers
    private func makeAnyURL() -> URL {
        URL(string: "http://example.com")!
    }
    
    private func makeSUT(file: StaticString = #filePath,
                         line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
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
        
        static func stub(data: Data?, response: HTTPURLResponse?, error: Error?) {
            URLProtocolStub.stub = URLProtocolStub.Stub(data: nil, response: nil, error: error)
        }
    }
}
