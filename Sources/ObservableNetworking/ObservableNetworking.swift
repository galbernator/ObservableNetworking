import Foundation

public struct ObservableNetworking: ObservableNetwork {
    public let network: Network

    public init(environment: NetworkEnvironment, session: URLSession = .shared) {
        self.network = NetworkManager(environment: environment, session: session)
    }
}
