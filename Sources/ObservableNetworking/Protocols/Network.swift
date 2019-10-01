//
//  Network.swift
//  
//
//  Created by Steve Galbraith on 9/24/19.
//

import Foundation
import RxSwift
import Combine

public protocol Network {
    // RxSwift
    func request(method: HTTPMethod, endpoint: String, parameters: [String : Any]?, headers: [String : String]?) -> Observable<Result<Data, NetworkError>>
    func authenticatedRequest(method: HTTPMethod, endpoint: String, parameters: [String : Any]?, headers: [String : String]?) -> Observable<Result<Data, NetworkError>>

    // Combine
    @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *)
    func request(method: HTTPMethod, endpoint: String, parameters: [String : Any]?, headers: [String : String]?) -> AnyPublisher<Data, NetworkError>
    @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *)
    func authenticatedRequest(method: HTTPMethod, endpoint: String, parameters: [String : Any]?, headers: [String : String]?) -> AnyPublisher<Data, NetworkError>
}

