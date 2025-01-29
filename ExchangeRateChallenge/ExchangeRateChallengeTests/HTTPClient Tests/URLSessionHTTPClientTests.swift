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
        let url = createAnyURL()
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
        let requestError = createNSError()
        let receivedError = resultErrorFor(data: nil, response: nil, error: requestError)
    
        XCTAssertEqual((receivedError as? NSError)?.code, requestError.code)
        XCTAssertEqual((receivedError as? NSError)?.domain, requestError.domain)
    }
    
    func test_getData_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: createAnyNonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: createAnyHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: createAnyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: createAnyData(), response: nil, error: createNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: createAnyNonHTTPURLResponse(), error: createNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: createAnyHTTPURLResponse(), error: createNSError()))
        XCTAssertNotNil(resultErrorFor(data: createAnyData(), response: createAnyNonHTTPURLResponse(), error: createNSError()))
        XCTAssertNotNil(resultErrorFor(data: createAnyData(), response: createAnyHTTPURLResponse(), error: createNSError()))
        XCTAssertNotNil(resultErrorFor(data: createAnyData(), response: createAnyNonHTTPURLResponse(), error: nil))
    }
    
    // MARK: - Helpers
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath,
                                line: UInt = #line) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        let expectation = expectation(description: "waiting for response")
        
        var receivedError: Error?
        sut.getData(from: createAnyURL()) { result in
            switch result {
            case .failure(let error):
                receivedError = error
                break
            default:
                XCTFail("expected failure with error", file: file, line: line)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        return receivedError
    }
    
    private func createAnyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: createAnyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func createAnyNonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: createAnyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
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
            Self.requestObserver = nil
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            URLProtocolStub.stub = URLProtocolStub.Stub(data: data, response: response, error: error)
        }
    }
}
