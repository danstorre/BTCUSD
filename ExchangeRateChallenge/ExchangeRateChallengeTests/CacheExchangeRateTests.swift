import XCTest

class CacheExchangeRate {
    private let store: StoreSpy
    
    init(store: StoreSpy) {
        self.store = store
    }
    
    func cache() {
        store.delete()
    }
}

class StoreSpy {
    private(set) var messages: [AnyMessage] = []
    private(set) var cacheCallCount: Int = 0
    
    enum AnyMessage {
        case deletion
        case insertion
    }
    
    func delete() {
        messages.append(.deletion)
    }
}

final class CacheExchangeRateTests: XCTestCase {
    
    func test_init_doesNotMessageStore() {
        let (_, spy) = makeSUT()
        XCTAssertEqual(spy.cacheCallCount, 0)
    }
    
    func test_onCache_deletesStore() {
        let (sut, spy) = makeSUT()
        
        sut.cache()
        
        XCTAssertEqual(spy.messages, [.deletion])
    }
    
    // MARK: - Helpers
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
