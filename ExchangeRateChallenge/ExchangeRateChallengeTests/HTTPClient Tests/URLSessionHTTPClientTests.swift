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
    func test_getData_onError_DeliversError() {
        URLProtocolStub.startInterceptingNetworkCalls()
        
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
        URLProtocolStub.stopInterceptingNetworkCalls()
    }
    
    class URLProtocolStub: URLProtocol {
        static var stub: Stub?
        struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static override func canInit(with request: URLRequest) -> Bool {
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
