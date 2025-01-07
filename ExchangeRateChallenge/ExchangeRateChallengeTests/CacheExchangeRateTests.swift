import XCTest
import ExchangeRateChallenge

class CacheExchangeRate {
    struct LocalExchangeRate: Equatable {
        let symbol: String
        let price: Double
        
        init(symbol: String, price: Double) {
            self.symbol = symbol
            self.price = price
        }
    }
    
    private let store: StoreSpy
    
    enum Error: Swift.Error {
        case deletionError(Swift.Error)
        case insertionError(Swift.Error)
    }
    
    init(store: StoreSpy) {
        self.store = store
    }
    
    func cache(exchangeRate: ExchangeRate) throws {
        do {
            try store.delete()
        } catch {
            throw Error.deletionError(error)
        }
        
        do {
            try store.insert(exchangeRate: exchangeRate.local)
        } catch {
            throw Error.insertionError(error)
        }
    }
}

private extension ExchangeRate {
    var local: CacheExchangeRate.LocalExchangeRate {
        CacheExchangeRate.LocalExchangeRate(symbol: symbol,
                                            price: price)
    }
}

class StoreSpy {
    private(set) var messages: [AnyMessage] = []
    private(set) var cacheCallCount: Int = 0
    
    enum AnyMessage: Equatable {
        case deletion
        case insertion(exchangeRate: CacheExchangeRate.LocalExchangeRate)
    }
    
    var stubbedDeletionError: Error?
    var stubbedInsertionError: Error?
    
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
}

final class CacheExchangeRateTests: XCTestCase {
    
    func test_init_doesNotMessageStore() {
        let (_, spy) = makeSUT()
        
        XCTAssertEqual(spy.cacheCallCount, 0)
    }
    
    func test_onCache_onDeletionError_deliversDeletionError() {
        let (sut, spy) = makeSUT()
        let exchangeRate = createAnyModel().model
        let anyError = createAnyError()
        spy.stubbedDeletionError = createAnyError()
        
        XCTAssertThrowsError(try sut.cache(exchangeRate: exchangeRate)) { error in
            if case CacheExchangeRate.Error.deletionError(let error) = error {
                XCTAssertEqual((error as NSError).domain, (anyError).domain)
                XCTAssertEqual((error as NSError).code, (anyError).code)
            } else {
                XCTFail()
            }
        }
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
        
        XCTAssertThrowsError(try sut.cache(exchangeRate: exchangeRate)) { error in
            if case CacheExchangeRate.Error.insertionError(let error) = error {
                XCTAssertEqual((error as NSError).domain, (anyError).domain)
                XCTAssertEqual((error as NSError).code, (anyError).code)
            } else {
                XCTFail()
            }
        }
    }
    
    // MARK: - Helpers
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
}
