//
//  MockURLSession.swift
//  
//
//  Created by Steve Galbraith on 9/25/19.
//

import Foundation
import ObservableNetworking
import Combine

class MockURLSession: Session {

    enum Constants {
        static let authKey = "Cookie"
        static let authValue = "0987654321"
    }

    private(set) var lastURL: URL? {
        didSet {

        }
    }
    var dataTask = MockURLSessionDataTask()
    var requiresAuthentication = false

    func dataTask(with request: NSURLRequest, completionHandler: @escaping DataTaskResult) -> DataTask {
        var error: NetworkError?

        if requiresAuthentication, let headerFields = request.allHTTPHeaderFields {
            if !headerFields.contains(where: { $0.key == "Cookie" && $0.value.contains(Constants.authValue) }) {
                error = NetworkError.unauthorized
            }
        }

        guard let requestURL = request.url else {
            return dataTask
        }

        let headerFields = createCookieHeader(for: requestURL)

        let response = HTTPURLResponse(url: requestURL, statusCode: 200, httpVersion: nil, headerFields: headerFields)
        let data = Data()
        completionHandler(data, response, error)
        lastURL = request.url
        return dataTask
    }

    @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *)
    func dataTaskPublisher(for request: NSURLRequest) -> AnyPublisher<Data, NetworkError> {
        lastURL = request.url
        return MockDataTaskPublisher().eraseToAnyPublisher()
    }

    private func createCookieHeader(for url: URL?) -> [String : String] {
        guard let cookieURL = url else { return [:] }

        let headerFields: [String : String] = [
            HTTPCookiePropertyKey.domain.rawValue: cookieURL.absoluteString,
            HTTPCookiePropertyKey.path.rawValue: "endpoint",
            HTTPCookiePropertyKey.name.rawValue: MockURLSession.Constants.authKey,
            HTTPCookiePropertyKey.value.rawValue: MockURLSession.Constants.authValue,
            HTTPCookiePropertyKey.secure.rawValue: "TRUE"
        ]

        // Create cookie headers by making all of the header fields into one String
        let cookieHeader = ["Set-Cookie": headerFields.map { "\($0)=\($1)" }.joined(separator: ", ")]

        return cookieHeader
    }
}

class MockURLSessionDataTask: DataTask {
    private(set) var resumeWasCalled = false

    func resume() {
        resumeWasCalled = true
    }
}

class MockDataTaskPublisher: Publisher {
    typealias Output = Data
    typealias Failure = NetworkError

    @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *)
    func receive<S>(subscriber: S) where S : Subscriber, MockDataTaskPublisher.Failure == S.Failure, MockDataTaskPublisher.Output == S.Input {}
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *)
extension Data: Subscriber {
    public typealias Input = Self
    public typealias Failure = NetworkError

    public var combineIdentifier: CombineIdentifier {
        CombineIdentifier()
    }

    public func receive(subscription: Subscription) {}

    public func receive(completion: Subscribers.Completion<NetworkError>) {}

    public func receive(_ input: Data) -> Subscribers.Demand { .unlimited }
}
