import XCTest
import ExchangeRateChallenge

final class CryptoCompareRemoteExchangeRateMapperTests: XCTestCase {
    func test_load_onNon2xxHTTPResponse_deliversInvalidDataError() {
        let samples = [199, 300, 400, 404, 500]
        
        samples.enumerated().forEach { (index, statusCode) in
            expectToMap(statusCode: statusCode, withResult: failure(.invalidData))
        }
    }
    
    func test_load_on200HTTPResponseWithInvalidData_deliversInvalidDataError() {
        expectToMap(statusCode: 200, data: Data("InvalidData".utf8), withResult: failure(.invalidData))
    }
    
    func test_load_on200HTTPResponseWithEmptyData_deliversInvalidDataError() {
        expectToMap(statusCode: 200, data: Data("".utf8), withResult: failure(.invalidData))
    }
    
    func test_load_on200HTTPResponseWithItemData_deliversExchangeRate() throws {
        let exchangeRate = createExchangeRate(symbol: "BTCUSDT", price: 103312.60000000)
        let data = try encode(exchangeRate.remote)
        
        expectToMap(statusCode: 200, data: data, withResult: success(with: exchangeRate.model))
    }
    
    // MARK: - Helpers
    private func createExchangeRate(symbol: String, price: Double) -> (model: ExchangeRate, remote: [String: Any]) {
        let remoteModel: [String: Any] = [
            "RAW": [
                "FROMSYMBOL": "BTC",
                "TOSYMBOL": "USD",
                "PRICE": 1.0
            ]
        ]
        
        let model = ExchangeRate(
            symbol: "BTCUSD",
            price: 1.0
        )
        
        return (model, remoteModel)
    }
    
    private func encode(_ json: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: json)
    }
    
    private func failure(_ error: CryptoExchangeRateRemoteExchangeRateLoader.Error) -> ExchangeRateLoader.Result {
        .failure(error)
    }
    
    private func success(with result: ExchangeRate) -> ExchangeRateLoader.Result {
        .success(result)
    }
    
    private func expectToMap(
        statusCode: Int,
        data: Data = Data(),
        withResult expectedResult: ExchangeRateLoader.Result, file: StaticString = #filePath,
        line: UInt = #line) {
            let response = HTTPURLResponse(
                url: URL(string: "http://example.com")!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            
            let receivedResult = CryptoExchangeRateRemoteExchangeRateMapper.map(response: response, data: data)
            
            switch (receivedResult, expectedResult) {
            case let (.success(receivedResult), .success(expectedResult)):
                XCTAssertEqual(receivedResult, expectedResult, "Expected \(expectedResult), got \(String(describing: receivedResult)) instead", file: file, line: line)
                
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError.code, expectedError.code, "Expected \(expectedError) error, got \(String(describing: receivedError)) instead", file: file, line: line)
                
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
        }
}
