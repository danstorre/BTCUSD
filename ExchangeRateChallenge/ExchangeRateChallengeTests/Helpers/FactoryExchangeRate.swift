import ExchangeRateChallenge

func createAnyExchangeRate() -> (model: ExchangeRate,
                          local: LocalExchangeRateStore.LocalExchangeRate) {
    let exchangeRate = ExchangeRate(symbol: "any", price: 1)
    let local = LocalExchangeRateStore.LocalExchangeRate(symbol: "any", price: 1)
    return (exchangeRate, local)
}

func createNSError() -> NSError {
    return NSError(domain: "any", code: 1)
}

func createAnyData() -> Data {
    return Data("any data".utf8)
}

func createAnyURL() -> URL {
   return URL(string: "http://example.com")!
}
