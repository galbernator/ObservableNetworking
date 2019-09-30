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

    @available(iOS 13.0, *)
    func dataTaskPublisher<T: TaskPublisher>(for request: URLRequest) -> T
}

// Make URLSession connform to Session protocol
extension URLSession: Session {
    public func dataTask(with request: NSURLRequest, completionHandler: @escaping DataTaskResult) -> DataTask {
        return dataTask(with: request, completionHandler: completionHandler) as DataTask
    }

    @available(iOS 13.0, *)
    public func dataTaskPublisher<T: TaskPublisher>(for request: URLRequest) -> T {
        return dataTaskPublisher(for: request) as T
    }
}

/// Protocol that allows dependecy injection for the express purpose of mocking `URLSession` during testing. This should not be used elsewhere
public protocol DataTask {
    func resume()
}

// Make URLSessionDataTask conform to DataTask protocol
extension URLSessionDataTask: DataTask {}

/// Protocol that allows dependecy injection for the express purpose of mocking `URLSession` during testing. This should not be used elsewhere
@available(iOS 13.0, *)
public protocol TaskPublisher: Publisher {
}

// Make DataTaskPublisher conform to TaskPublisher protocol
@available(iOS 13.0, *)
extension URLSession.DataTaskPublisher: TaskPublisher {}

@available(iOS 13.0, *)
extension AnyPublisher: TaskPublisher {}
