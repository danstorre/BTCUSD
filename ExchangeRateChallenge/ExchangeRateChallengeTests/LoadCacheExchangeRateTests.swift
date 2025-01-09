import XCTest
import ExchangeRateChallenge

final class LoadCacheExchangeRateTests: XCTestCase {
    
    func test_init_doesNotMessageStore() {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.loadCacheCallCount, 0)
    }
    
    func test_onLoadCache_onRetrievalError_deliversLoadError() {
        let (sut, spy) = makeSUT()
        let exchangeRate = createAnyModel().model
        let anyError = createAnyError()
        spy.stubbedRetrievalError = createAnyError()
        
        assertLoadCacheThrowsError(
            for: sut,
            exchangeRate: exchangeRate,
            expectedErrorCase: .loadError(anyError)
        )
    }

    func test_onLoadCache_sendsCorrectMessagesToStore() {
        let (sut, spy) = makeSUT()
        
        _ = try? sut.loadCache()
        
        XCTAssertEqual(spy.messages, [.retrieve])
    }

    func test_onLoadCache_onEmptyStore_deliversNoItems() throws {
        let (sut, spy) = makeSUT()
        spy.stubbedRetrievalItems = .none
        
        let result = try sut.loadCache()
        
        XCTAssertEqual(result, nil)
    }
    
    // MARK: - Helpers
    private func assertLoadCacheThrowsError(
        for sut: CacheExchangeRate,
        exchangeRate: ExchangeRate,
        expectedErrorCase: CacheExchangeRate.LoadError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try sut.loadCache(), file: file, line: line) { error in
            switch (expectedErrorCase, error as! CacheExchangeRate.LoadError) {
            case (.loadError(let expectedError), .loadError(let error)):
                XCTAssertEqual((expectedError as NSError).domain, (error as NSError).domain, file: file, line: line)
                XCTAssertEqual((expectedError as NSError).code, (error as NSError).code, file: file, line: line)
                
            default:
                XCTFail("Expected \(expectedErrorCase), got \(error) instead")
            }
        }
    }
    
    private func createAnyModel() -> (model: ExchangeRate,
                                      local: CacheExchangeRate.LocalExchangeRate) {
        let exchangeRate = ExchangeRate(symbol: "any", price: 1)
        let local = CacheExchangeRate.LocalExchangeRate(symbol: "any", price: 1)
        return (exchangeRate, local)
    }
    
    private func createAnyError() -> NSError {
        return NSError(domain: "any", code: 1)
    }
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: CacheExchangeRate, spy: StoreSpy) {
        let spy = StoreSpy()
        let sut = CacheExchangeRate(store: spy)
        
        trackForMemoryLeaks(spy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, spy)
    }
    
    private class StoreSpy: LocalExchangeRateStore {
        private(set) var messages: [AnyMessage] = []
        private(set) var loadCacheCallCount: Int = 0
        
        enum AnyMessage: Equatable {
            case deletion
            case insertion(exchangeRate: CacheExchangeRate.LocalExchangeRate)
            case retrieve
        }
        
        var stubbedRetrievalError: Error?
        var stubbedDeletionError: Error?
        var stubbedInsertionError: Error?
        var stubbedRetrievalItems: CacheExchangeRate.LocalExchangeRate?
        
        func delete() throws {
            messages.append(.deletion)
            
            if let stubbedDeletionError {
                throw stubbedDeletionError
            }
        }
        
        func insert(exchangeRate: CacheExchangeRate.LocalExchangeRate) throws {
            messages.append(.insertion(exchangeRate: exchangeRate))
            
            if let stubbedInsertionError {
                throw stubbedInsertionError
            }
        }
        
        func retrieve() throws -> CacheExchangeRate.LocalExchangeRate? {
            messages.append(.retrieve)
            
            if let stubbedRetrievalError {
                throw stubbedRetrievalError
            }
            
            return stubbedRetrievalItems
        }
    }
}
