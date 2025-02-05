import XCTest
import ExchangeRateChallenge

final class LoadCacheExchangeRateTests: XCTestCase {
    
    func test_init_doesNotMessageStore() {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.retrieveCallCount, 0)
    }
    
    func test_onLoadCache_onRetrievalError_deliversLoadError() {
        let (sut, spy) = makeSUT()
        let exchangeRate = createAnyExchangeRate().model
        let anyError = createNSError()
        spy.stubbedRetrievalError = createNSError()
        
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
        
        XCTAssertNil(result)
    }
    
    func test_onLoadCache_onInvalidStore_emptiesStore() throws {
        let (sut, spy) = makeSUT()
        spy.stubbedRetrievalError = createNSError()
        
        _ = try? sut.loadCache()
        
        XCTAssertEqual(spy.messages, [.retrieve, .deletion])
    }
    
    func test_onLoadCache_onValidStore_deliversTimestampedExchangeRate() throws {
        let date = Date()
        let (sut, spy) = makeSUT()
        let exchangeRate = createAnyExchangeRate()
        spy.stubbedRetrievalItems = (exchangeRate.local, date.adding(seconds: 1))
        
        let result = try sut.loadCache()
        
        XCTAssertEqual(result?.exchangeRate, exchangeRate.model)
        XCTAssertEqual(result?.timestamp, date.adding(seconds: 1))
    }
    
    // MARK: - Helpers
    private func assertLoadCacheThrowsError(
        for sut: LocalExchangeRateStore,
        exchangeRate: ExchangeRate,
        expectedErrorCase: LocalExchangeRateStore.LoadError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try sut.loadCache(), file: file, line: line) { error in
            switch (expectedErrorCase, error as! LocalExchangeRateStore.LoadError) {
            case (.loadError(let expectedError), .loadError(let error)):
                XCTAssertEqual((expectedError as NSError).domain, (error as NSError).domain, file: file, line: line)
                XCTAssertEqual((expectedError as NSError).code, (error as NSError).code, file: file, line: line)
                
            default:
                XCTFail("Expected \(expectedErrorCase), got \(error) instead")
            }
        }
    }
    
    private func makeSUT(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalExchangeRateStore, spy: StoreSpy) {
        let spy = StoreSpy()
        let sut = LocalExchangeRateStore(store: spy, currentDate: currentDate)
        
        trackForMemoryLeaks(spy, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, spy)
    }
}

private extension Date {
    func adding(seconds: Int) -> Date {
        let calendar = Calendar.init(identifier: .gregorian)
        return calendar.date(byAdding: .init(calendar: calendar, second: seconds), to: self)!
    }
}
