//
//  File.swift
//  
//
//  Created by Steve Galbraith on 9/24/19.
//

import Foundation


public enum NetworkError: Error {
    case failure(message: String)
    case unauthorized
    case unexpected
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .failure(let message):
            return message
        case .unauthorized:
            return "Unauthorized action"
        case .unexpected:
            return "An unexpected error occured. Please try again later."
        }
    }
}
