import Foundation

@frozen
public enum HTTPClientResult {
    case success((HTTPURLResponse, Data))
    case failure(Error)
}
