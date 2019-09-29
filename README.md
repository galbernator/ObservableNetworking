# ObservableNetworking

A simple, yet flexible, networking library that allows the use of RxSwift to return observable from network requests.


### How to use

To get started, you will need to let the framework know a little about your different enviroments by defining an `enum` that conforms to `NetworkEnvironment`. This will allow the framework to build the desired network requests and URLs it needs.

```SWift
enum Environment {
    case production
    case staging
    case dev
}

extension Enviroment: NetworkEnvironment {
    var scheme: String {
        switch self {
        case .production:
            return "https"
        default:
            return "http"
        }
    }

    var host: String {
        switch self {
        case .production:
            return "mycoolsite.com"
        case .staging:
            return "staging.mycoolsite.com"
        case .dev:
            return "dev.mycoolsite.com"
        }
    }

    var path: String {
        return "api/v1/"
    }
}
```

Once the environment has been defined it is time to initialize the framework by passing in your selected environment. This framework conforms to the `ObservableNetwork` protocol so that it is easily mocked for testing. All that is then needed is to grab the `network` from the instantiation.

```Swift
let networkingFramework = ObservableNetworking(environment: .dev)
let network = networkingFramework.network
```
