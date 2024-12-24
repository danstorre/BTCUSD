import Foundation

public protocol HTTPClient {
    typealias HTTPClientCompletion = (HTTPClientResult) -> Void
    func getData(from url: URL, completion: @escaping HTTPClientCompletion)
}
