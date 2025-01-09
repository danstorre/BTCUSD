import ExchangeRateChallenge

func createAnyModel() -> (model: ExchangeRate,
                          local: CacheExchangeRate.LocalExchangeRate) {
    let exchangeRate = ExchangeRate(symbol: "any", price: 1)
    let local = CacheExchangeRate.LocalExchangeRate(symbol: "any", price: 1)
    return (exchangeRate, local)
}

func createAnyError() -> NSError {
    return NSError(domain: "any", code: 1)
}
