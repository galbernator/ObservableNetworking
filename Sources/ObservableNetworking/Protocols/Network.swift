//
//  Network.swift
//  
//
//  Created by Steve Galbraith on 9/24/19.
//

import Foundation
import RxSwift

public protocol Network {
    // RxSwift
    func request(method: HTTPMethod, endpoint: String, parameters: [String : Any]?, headers: [String : String]?) -> Observable<Result<Data, NetworkError>>
    func authenticatedRequest(method: HTTPMethod, endpoint: String, parameters: [String : Any]?, headers: [String : String]?) -> Observable<Result<Data, NetworkError>>
}

