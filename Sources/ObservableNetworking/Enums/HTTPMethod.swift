//
//  HTTPMethod.swift
//  
//
//  Created by Steve Galbraith on 9/24/19.
//

import Foundation

/// HTTP methods as defined at  https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods
public enum HTTPMethod: String {
    case get = "GET"
    case head = "HEAD"
    case put = "PUT"
    case post = "POST"
    case delete = "DELETE"
    case connect = "CONNECT"
    case options = "OPTIONS"
    case trace = "TRACE"
    case patch = "PATCH"
}
