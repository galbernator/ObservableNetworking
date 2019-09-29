//
//  Session.swift
//  
//
//  Created by Steve Galbraith on 9/25/19.
//

import Foundation

/// Protocol that allows dependecy injection for the express purpose of mocking `URLSession` during testing. This should not be used elsewhere
public protocol Session {
    typealias DataTaskResult = (Data?, URLResponse?, Error?) -> Void
    func dataTask(with request: NSURLRequest, completionHandler: @escaping DataTaskResult) -> DataTask
}

// Make URLSession connform to Session protocol
extension URLSession: Session {
    public func dataTask(with request: NSURLRequest, completionHandler: @escaping DataTaskResult) -> DataTask {
        return dataTask(with: request, completionHandler: completionHandler) as DataTask
    }
}

/// Protocol that allows dependecy injection for the express purpose of mocking `URLSession` during testing. This should not be used elsewhere
public protocol DataTask {
    func resume()
}

// Make URLSessionDataTask conform to DataTask protocol
extension URLSessionDataTask: DataTask {}
