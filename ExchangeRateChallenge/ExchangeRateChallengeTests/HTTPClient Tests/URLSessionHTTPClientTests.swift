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
        URLProtocolStub.stubs[url] = URLProtocolStub.Stub(data: nil, response: nil, error: error)
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
        static var stubs = [URL: Stub]()
        struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static override func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else { return false }
            return stubs[url] != nil
        }
        
        static override func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let url = request.url, let stub = Self.stubs[url] else { return }
            
            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = stub.error {
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
            Self.stubs = [:]
        }
    }
}
