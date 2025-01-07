import XCTest

class CacheExchangeRate {
    private let store: StoreSpy
    
    enum Error: Swift.Error {
        case deletionError(Swift.Error)
    }
    
    init(store: StoreSpy) {
        self.store = store
    }
    
    func cache() throws {
        do {
            try store.delete()
        } catch {
            throw Error.deletionError(error)
        }
    }
}

class StoreSpy {
    private(set) var messages: [AnyMessage] = []
    private(set) var cacheCallCount: Int = 0
    
    enum AnyMessage {
        case deletion
        case insertion
    }
    
    var stubbedResult: Error?
    
    func delete() throws {
        messages.append(.deletion)
        
        if let stubbedResult {
            throw stubbedResult
        }
    }
    
    func failsWithError() {
        
    }
}

final class CacheExchangeRateTests: XCTestCase {
    
    func test_init_doesNotMessageStore() {
        let (_, spy) = makeSUT()
        XCTAssertEqual(spy.cacheCallCount, 0)
    }
    
    func test_onCache_deletesStore() {
        let (sut, spy) = makeSUT()
        
        try? sut.cache()
        
        XCTAssertEqual(spy.messages, [.deletion])
    }
    
    func test_onCache_onDeletionError_deliversDeletionError() {
        let (sut, spy) = makeSUT()
        let anyError = createAnyError()
        spy.stubbedResult = createAnyError()
        
        XCTAssertThrowsError(try sut.cache()) { error in
            if case CacheExchangeRate.Error.deletionError(let error) = error {
                XCTAssertEqual((error as NSError).domain, (anyError).domain)
                XCTAssertEqual((error as NSError).code, (anyError).code)
            } else {
                XCTFail()
            }
        }
    }
    
    // MARK: - Helpers
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
}
