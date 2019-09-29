//
//  NetworkEnvironment.swift
//  
//
//  Created by Steve Galbraith on 9/24/19.
//

import Foundation

public protocol NetworkEnvironment {
    var scheme: String { get }
    var host: String { get }
    var path: String { get }
    var url: String { get }
}

public extension NetworkEnvironment {
    var url: String {
        "\(scheme)://\(host)/\(path)"
    }
}
