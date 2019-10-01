//
//  Session.swift
//  
//
//  Created by Steve Galbraith on 9/25/19.
//

import Foundation
import Combine

/// Protocol that allows dependecy injection for the express purpose of mocking `URLSession` during testing. This should not be used elsewhere
public protocol Session {
    typealias DataTaskResult = (Data?, URLResponse?, Error?) -> Void
    func dataTask(with request: NSURLRequest, completionHandler: @escaping DataTaskResult) -> DataTask

    @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *)
    func dataTaskPublisher(for request: NSURLRequest) -> AnyPublisher<Data, NetworkError>
}

// Make URLSession connform to Session protocol
extension URLSession: Session {
    public func dataTask(with request: NSURLRequest, completionHandler: @escaping DataTaskResult) -> DataTask {
        dataTask(with: request as URLRequest, completionHandler: completionHandler) as DataTask
    }

    @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *)
    public func dataTaskPublisher(for request: NSURLRequest) -> AnyPublisher<Data, NetworkError> {
        dataTaskPublisher(for: request as URLRequest)
            .mapError({ urlError -> NetworkError in
                NetworkError.failure(message: urlError.localizedDescription)
            })
            .flatMap(maxPublishers: .max(1)) { Just($0.data).setFailureType(to: NetworkError.self) }
            .eraseToAnyPublisher()
    }
}

/// Protocol that allows dependecy injection for the express purpose of mocking `URLSession` during testing. This should not be used elsewhere
public protocol DataTask {
    func resume()
}

// Make URLSessionDataTask conform to DataTask protocol
extension URLSessionDataTask: DataTask {}
