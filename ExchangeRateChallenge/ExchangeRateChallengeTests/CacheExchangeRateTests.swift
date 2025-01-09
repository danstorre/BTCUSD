import XCTest
import ExchangeRateChallenge

final class CacheExchangeRateTests: XCTestCase {
    
    func test_init_doesNotMessageStore() {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.insertCallCount, 0)
    }
    
    func test_onCache_onDeletionError_deliversDeletionError() {
        let (sut, spy) = makeSUT()
        let exchangeRate = createAnyModel().model
        let anyError = createAnyError()
        spy.stubbedDeletionError = createAnyError()
        
        assertCacheThrowsError(
            for: sut,
            exchangeRate: exchangeRate,
            expectedErrorCase: .deletionError(anyError)
        )
    }
    
    func test_onCache_sendsCorrectMessagesToStore() {
        let (sut, spy) = makeSUT()
        let exchangeRate = createAnyModel()
        
        try? sut.cache(exchangeRate: exchangeRate.model)
        
        XCTAssertEqual(spy.messages, [.deletion, .insertion(exchangeRate: exchangeRate.local)])
    }
    
    func test_onCache_onInsertionError_deliversInsertionError() {
        let (sut, spy) = makeSUT()
        let exchangeRate = createAnyModel().model
        let anyError = createAnyError()
        spy.stubbedInsertionError = createAnyError()
        
        assertCacheThrowsError(
            for: sut,
            exchangeRate: exchangeRate,
            expectedErrorCase: .insertionError(anyError)
        )
    }
    
    // MARK: - Helpers
    private func assertCacheThrowsError(
        for sut: CacheExchangeRate,
        exchangeRate: ExchangeRate,
        expectedErrorCase: CacheExchangeRate.SaveError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try sut.cache(exchangeRate: exchangeRate)) { error in
            switch (expectedErrorCase, error as! CacheExchangeRate.SaveError) {
            case (.insertionError(let expectedError), .insertionError(let error)):
                XCTAssertEqual((expectedError as NSError).domain, (error as NSError).domain, file: file, line: line)
                XCTAssertEqual((expectedError as NSError).code, (error as NSError).code, file: file, line: line)
                
            case (.deletionError(let expectedError), .deletionError(let error)):
                XCTAssertEqual((expectedError as NSError).domain, (error as NSError).domain, file: file, line: line)
                XCTAssertEqual((expectedError as NSError).code, (error as NSError).code, file: file, line: line)
                
            default:
                XCTFail("Expected \(expectedErrorCase), got \(error) instead")
            }
        }
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
}
