//
//  NetworkManagerTests.swift
//  
//
//  Created by Steve Galbraith on 9/25/19.
//

import XCTest
import RxSwift
@testable import ObservableNetworking

final class NetworkManagerTests: XCTestCase {
    let disposeBag = DisposeBag()

    enum MockEnvironment: NetworkEnvironment, CaseIterable {
        case production
        case dev

        var scheme: String {
            switch self {
            case .production:
                return "https"
            case .dev:
                return "http"
            }
        }

        var host: String {
            switch self {
            case .production:
                return "mycoolwebsite.com"
            case .dev:
                return "dev.mycoolwebsite.com"
            }
        }

        var path: String {
            switch self {
            case .production:
                return "mockAPI/v1/"
            case .dev:
                return "mockAPI/v2/"
            }
        }
    }

    override class func setUp() {
        if let yessterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
            HTTPCookieStorage.shared.removeCookies(since: yessterday)
        }
    }

    // MARK: - RxSwift Tests

    func testRXPostRequestInEnvironments() {
        MockEnvironment.allCases.forEach { environment in
            let endpoint = "something"
            let session = MockURLSession()
            let networkManager = NetworkManager(environment: environment, session: session)

            networkManager.request(method: .post, endpoint: endpoint)
                .subscribe(onNext: { _ in
                    return
                })
                .disposed(by: disposeBag)

            guard let url = URL(string: "\(environment.scheme)://\(environment.host)/\(environment.path)\(endpoint)") else {
                XCTFail("Invalid URL")
                return
            }

            XCTAssert(session.lastURL == url)
        }
    }

    func testGetRequestInEnvironments() {
        MockEnvironment.allCases.forEach { environment in
            let params = [ "userID": "1234567"]
            let endpoint = "something"
            let session = MockURLSession()
            let networkManager = NetworkManager(environment: environment, session: session)

            networkManager.request(method: .get, endpoint: endpoint, parameters: params)
                .subscribe(onNext: { _ in
                    return
                })
                .disposed(by: disposeBag)

            guard let url = URL(string: "\(environment.scheme)://\(environment.host)/\(environment.path)\(endpoint)?\(queryString(from: params))") else {
                XCTFail("Invalid URL")
                return
            }

            XCTAssert(session.lastURL == url)
        }
    }

    func testRxPostResumeCalled() {
        MockEnvironment.allCases.forEach { environment in
            let endpoint = "contacts"
            let session = MockURLSession()
            let networkManager = NetworkManager(environment: environment, session: session)
            let dataTask = MockURLSessionDataTask()
            session.dataTask = dataTask

            networkManager.request(method: .post, endpoint: endpoint)
                .subscribe(onNext: { _ in
                    return
                })
                .disposed(by: disposeBag)
            XCTAssert(dataTask.resumeWasCalled)
        }
    }

    func testRxAuthenticatedPostFaileWithNoCookie() {
        MockEnvironment.allCases.forEach { environment in
            let endpoint = "crashtastic"
            let session = MockURLSession()
            session.requiresAuthentication = true
            let networkManager = NetworkManager(environment: environment, session: session)

            networkManager.authenticatedRequest(method: .post, endpoint: endpoint)
                .subscribe(onNext: { result in
                    switch result {
                    case .failure(let error):
                        XCTAssertEqual(error.localizedDescription, NetworkError.unauthorized.localizedDescription)
                    case .success:
                        XCTFail("Test should have returned an error")
                    }
                })
            .disposed(by: disposeBag)
        }
    }

    func testRxAuthenticatedPostRequestInEnvironments() {
        MockEnvironment.allCases.forEach { environment in
            let endpoint = "something"
            let session = MockURLSession()
            let networkManager = NetworkManager(environment: environment, session: session, sessionCookieName: "Value")

            session.requiresAuthentication = false
            // Send an initial request to make sett the cookie
            networkManager.request(method: .post, endpoint: "login")
                .subscribe(onNext: { _ in
                    return
                })
                .disposed(by: disposeBag)

            session.requiresAuthentication = true

            networkManager.authenticatedRequest(method: .post, endpoint: endpoint)
                .subscribe(onNext: { result in
                    switch result {
                    case .failure(let error):
                        XCTFail("Error: \(error.localizedDescription)")
                    case .success(let data):
                        XCTAssertNotNil(data)
                    }
                })
                .disposed(by: disposeBag)

            guard let url = URL(string: "\(environment.scheme)://\(environment.host)/\(environment.path)\(endpoint)") else {
                XCTFail("Invalid URL")
                return
            }

            XCTAssert(session.lastURL == url)
        }
    }

    func testRxAuthenticatedGetRequestInEnvironments() {
        MockEnvironment.allCases.forEach { environment in
            let params = [ "userID": "1234567"]
            let endpoint = "something"
            let session = MockURLSession()
            let networkManager = NetworkManager(environment: environment, session: session, sessionCookieName: "Value")

            session.requiresAuthentication = false
            // Send an initial request to make sett the cookie
            networkManager.request(method: .post, endpoint: "login")
                .subscribe(onNext: { _ in
                    return
                })
                .disposed(by: disposeBag)

            session.requiresAuthentication = true

            networkManager.authenticatedRequest(method: .get, endpoint: endpoint, parameters: params)
                .subscribe(onNext: { result in
                    switch result {
                    case .failure(let error):
                        XCTFail("Error - \(error.localizedDescription)")
                    case .success(let data):
                        XCTAssertNotNil(data)
                    }
                })
                .disposed(by: disposeBag)

            guard let url = URL(string: "\(environment.scheme)://\(environment.host)/\(environment.path)\(endpoint)?\(queryString(from: params))") else {
                XCTFail("Invalid URL")
                return
            }

            XCTAssert(session.lastURL == url)
        }
    }

    // MARK: - Combine Tests

    @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *)
    func testCombinePostRequetInEnvironments() {
        MockEnvironment.allCases.forEach { environment in
            let endpoint = "combine"
            let session = MockURLSession()
            let networkManager = NetworkManager(environment: environment, session: session, sessionCookieName: "Value")

            let _ = networkManager.request(method: .post, endpoint: endpoint)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        XCTFail("Error: \(error.localizedDescription)")
                    case .finished:
                        return
                    }
                }, receiveValue: { _ in
                    return
                })

            guard let url = URL(string: "\(environment.scheme)://\(environment.host)/\(environment.path)\(endpoint)") else {
                XCTFail("Invalid URL")
                return
            }

            XCTAssert(session.lastURL == url)
        }
    }

    @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *)
    func testCombineGetRequestInEnvironments() {
        MockEnvironment.allCases.forEach { environment in
            let params = [ "userID": "1234567"]
            let endpoint = "something"
            let session = MockURLSession()
            let networkManager = NetworkManager(environment: environment, session: session)

            let _ = networkManager.request(method: .get, endpoint: endpoint, parameters: params)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        XCTFail("Error: \(error.localizedDescription)")
                    case .finished:
                        return
                    }
                }, receiveValue: { _ in
                    return
                })

            guard let url = URL(string: "\(environment.scheme)://\(environment.host)/\(environment.path)\(endpoint)?\(queryString(from: params))") else {
                XCTFail("Invalid URL")
                return
            }

            XCTAssert(session.lastURL == url)
        }
    }

    @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *)
    func testCombineAuthenticatedPostFaileWithNoCookie() {
        MockEnvironment.allCases.forEach { environment in
            let endpoint = "crashtastic"
            let session = MockURLSession()
            session.requiresAuthentication = true
            let networkManager = NetworkManager(environment: environment, session: session)

            let _ = networkManager.request(method: .post, endpoint: endpoint)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                         XCTAssertEqual(error.localizedDescription, NetworkError.unauthorized.localizedDescription)
                    case .finished:
                        XCTFail("Test should have returned an error")
                    }
                }, receiveValue: { _ in
                    return
                })
        }
    }

    @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *)
    func testCombineAuthenticatedPostRequestInEnvironments() {
        MockEnvironment.allCases.forEach { environment in
            let endpoint = "something"
            let session = MockURLSession()
            let networkManager = NetworkManager(environment: environment, session: session, sessionCookieName: "Value")

            session.requiresAuthentication = false
            // Send an initial request to make sett the cookie
            let _ = networkManager.request(method: .post, endpoint: "login")
                .sink(receiveCompletion: { _ in
                    return
                }) { _ in
                    return
                }

            session.requiresAuthentication = true

            let _ = networkManager.authenticatedRequest(method: .post, endpoint: endpoint)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        XCTFail("Error: \(error.localizedDescription)")
                    case .finished:
                        return
                    }
                }, receiveValue: { data in
                    XCTAssertNotNil(data)
                })

            guard let url = URL(string: "\(environment.scheme)://\(environment.host)/\(environment.path)\(endpoint)") else {
                XCTFail("Invalid URL")
                return
            }

            XCTAssert(session.lastURL == url)
        }
    }

    @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *)
    func testCombineAuthenticatedGetRequestInEnvironments() {
        MockEnvironment.allCases.forEach { environment in
            let params = [ "userID": "1234567"]
            let endpoint = "something"
            let session = MockURLSession()
            let networkManager = NetworkManager(environment: environment, session: session, sessionCookieName: "Value")

            session.requiresAuthentication = false
            // Send an initial request to make sett the cookie
            let _ = networkManager.request(method: .post, endpoint: "login")
                .sink(receiveCompletion: { _ in
                    return
                }) { _ in
                    return
                }

            session.requiresAuthentication = true

            let _ = networkManager.authenticatedRequest(method: .get, endpoint: endpoint, parameters: params)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        XCTFail("Error: \(error.localizedDescription)")
                    case .finished:
                        return
                    }
                }, receiveValue: { data in
                    XCTAssertNotNil(data)
                })

            guard let url = URL(string: "\(environment.scheme)://\(environment.host)/\(environment.path)\(endpoint)?\(queryString(from: params))") else {
                XCTFail("Invalid URL")
                return
            }

            XCTAssert(session.lastURL == url)
        }
    }

    // MARK: - Test Helpers

    private func queryString(from parameters: [String : Any]?) -> String {
        guard let parameters = parameters as? [String : String] else { return "" }
        return parameters.map { "\($0)=\($1)" }.joined(separator: "&")
    }
}
