import ExchangeRateChallenge

class StoreSpy: LocalExchangeRateStore {
    private(set) var messages: [AnyMessage] = []
    private(set) var retrieveCallCount: Int = 0
    private(set) var insertCallCount: Int = 0
    
    enum AnyMessage: Equatable {
        case deletion
        case insertion(
            exchangeRate: CacheExchangeRate.LocalExchangeRate,
            timestamp: Date
        )
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
    
    func insert(exchangeRate: CacheExchangeRate.LocalExchangeRate, timestamp: Date) throws {
        insertCallCount += 1
        messages.append(.insertion(exchangeRate: exchangeRate, timestamp: timestamp))
        
        if let stubbedInsertionError {
            throw stubbedInsertionError
        }
    }
    
    func retrieve() throws -> CacheExchangeRate.LocalExchangeRate? {
        retrieveCallCount += 1
        messages.append(.retrieve)
        
        if let stubbedRetrievalError {
            throw stubbedRetrievalError
        }
        
        return stubbedRetrievalItems
    }
}
