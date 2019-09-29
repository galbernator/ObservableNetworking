//
//  NetworkManager.swift
//  
//
//  Created by Steve Galbraith on 9/24/19.
//

import Foundation
import RxSwift

public final class NetworkManager: Network {
    typealias Header = [String : String]
    private let environment: NetworkEnvironment
    private let session: Session
    private let sessionCookieName: String
    private var authCookie: HTTPCookie? {
        didSet {
            if authCookie != nil {
                saveCookie()
            } else {
                guard let oldDomain = oldValue?.domain else {
                    deleteCookie(for: nil)
                    return
                }

                let url = URL(string: oldDomain)
                deleteCookie(for: url)
            }
        }
    }

    // MARK: - Initializer

    init(environment: NetworkEnvironment, session: Session, sessionCookieName: String = "") {
        self.environment = environment
        self.session = session
        self.sessionCookieName = sessionCookieName
    }

    // MARK: - Network

    public func request(method: HTTPMethod, endpoint: String, parameters: [String : Any]? = nil, headers: [String : String]? = nil) -> Observable<Result<Data, NetworkError>> {
        dataRequest(method: method, endpoint: endpoint, parameters: parameters, headers: defaultHeaders(headers))
    }
       
    public func authenticatedRequest(method: HTTPMethod, endpoint: String, parameters: [String : Any]? = nil, headers: [String : String]? = nil) -> Observable<Result<Data, NetworkError>> {
        dataRequest(method: method, endpoint: endpoint, parameters: parameters, headers: authenticatedHeaders(headers), requiresAuthentication: true)
    }

    // MARK: - Helpers

    private func dataRequest(method: HTTPMethod, endpoint: String, parameters: [String : Any]?, headers: Header?, requiresAuthentication: Bool = false) -> Observable<Result<Data, NetworkError>> {
        guard let request = generateRequest(method: method, endpoint: endpoint, parameters: parameters, headers: headers)  else {
                return Observable.error(NetworkError.unexpected)
            }
        let result = ReplaySubject<Result<Data, NetworkError>>.create(bufferSize: 1)
        let dataTask = session.dataTask(with: request as NSURLRequest) { [weak self] data, response, error in
            guard error == nil else {
                let message = error!.localizedDescription
                let apiError = NetworkError.failure(message: message)
                result.onNext(.failure(apiError))
                return
            }

            guard let data = data else {
                let apiError: NetworkError = .failure(message: "Error: No data returned from network request")
                result.onNext(.failure(apiError))
                return
            }

            if let httpURLResponse = response as? HTTPURLResponse {
                self?.setCookies(for: httpURLResponse.allHeaderFields)
            }

            result.onNext(.success(data))
        }

        dataTask.resume()
        return result
    }

    private func generateRequest(method: HTTPMethod, endpoint: String, parameters: [String: Any]?, headers: [String: String]?) -> URLRequest? {
        guard let baseURL = URL(string: environment.url) else { return nil }

        var urlString = endpoint
        var httpBody: Data? = nil

        switch method {
        case .get:
            urlString += "?\(queryString(for: parameters))"
        case .post:
            httpBody = generateHTTPBody(from: parameters)
        default:
            break
        }
        guard let url = URL(string: urlString, relativeTo: baseURL) else { return nil }
        var request = URLRequest(url: url)
        request.httpBody = httpBody

        headers?.forEach({ (key, value) in
            request.setValue(value, forHTTPHeaderField: key)
        })

        return request
    }

    private func queryString(for params: [String: Any]?) -> String {
        guard let parameters = params as? [String: String] else { return "" }

        var paramList = [String]()

        for (key, value) in parameters {
            guard let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
                print("Failed to convert key \(key)")
                continue
            }

            guard let escapedValue = (value as AnyObject).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
                print("Failed to convert value \(value)")
                continue
            }

            paramList.append("\(escapedKey)=\(escapedValue)")
        }

        return paramList.joined(separator: "&")
    }

    private func generateHTTPBody(from params: [String: Any]?) -> Data? {
        guard let parameters = params else { return nil }
        return try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
    }

    private func merge(_ optional: [String: Any]?, with base: [String: Any]) -> [String: Any] {
        guard let additions = optional else {
            return base
        }
        // If there's a conflict, take the new override
        return base.merging(additions) { (_, new) in new }
    }

    private func defaultHeaders(_ headers: [String: Any]?) -> Header {
        let defaultHeaders = [
            "Accept" : "application/json"
        ]
        guard let merged = merge(headers, with: defaultHeaders) as? Header
            else { return defaultHeaders }

        return merged
    }

    private func authenticatedHeaders(_ headers: [String: String]?) -> Header {
        guard let cookie = authCookie else { return Header() }

        let headerDefaults = defaultHeaders(headers)
        let authHeader = HTTPCookie.requestHeaderFields(with: [cookie])
        guard let merged = merge(headerDefaults, with: authHeader) as? Header
        else {
            return authHeader
        }

        return merged
    }

    private func setCookies(for headers: [AnyHashable : Any]) {
        guard
            let headerStrings = headers as? [String : String],
            let url = URL(string: environment.host)
            else { return }

        let allCookies = HTTPCookie.cookies(withResponseHeaderFields: headerStrings, for: url)

        guard let sessionCookie = allCookies.first(where: { $0.name == sessionCookieName }) else { return }
        authCookie = sessionCookie
    }

    private func saveCookie() {
        guard
            let cookie = authCookie,
            let url = URL(string: environment.host)
            else { return }

        let headerFields = HTTPCookie.requestHeaderFields(with: [cookie])
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
        HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: url)
    }

    private func deleteCookie(with name: String? = nil, for url: URL?) {
        guard let cookieURL = url else {
            let components = DateComponents(month: -1)
            if let oneMonthAgo = Calendar.current.date(byAdding: components, to: Date()) {
                HTTPCookieStorage.shared.removeCookies(since: oneMonthAgo)
            }
            return
        }

        guard let cookies = HTTPCookieStorage.shared.cookies(for: cookieURL) else { return }

        guard let cookieName = name else {
            cookies.forEach { cookie in
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
            return
        }

        cookies.forEach {  cookie in
            if cookie.name == cookieName {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
    }
}
