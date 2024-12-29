import Foundation

public enum HTTPClientResult {
    case success((HTTPURLResponse, Data))
    case failure(Error)
}
