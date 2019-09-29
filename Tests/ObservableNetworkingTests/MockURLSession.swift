//
//  MockURLSession.swift
//  
//
//  Created by Steve Galbraith on 9/25/19.
//

import Foundation
import ObservableNetworking

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
