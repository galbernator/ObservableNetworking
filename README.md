# ObservableNetworking

A simple and flexible networking library that allows the use of RxSwift and Combine to return observable data from network requests.


## How to use

### Add the Swift Package

1. Open your project and select "Swift Packages" -> "Add Package Dependency..." from the "File" menu
2. Enter `https://github.com/galbernator/ObservableNetworking.git` in the search field and click "Next"
3. Select the appropriate rule for your app and click "Next"
4. Update targets if necessary, then click "Finish"
5. Do a happy dance because your networking is about to get all sorts of simple!

### Set up the Environment

To get started, the framework needs to know a little about the possible environments which can be accomplished by defining an `enum` that conforms to `NetworkEnvironment`. This will allow the framework to build the desired network requests and URLs it needs.

```SWift
import ObservableNetworking

enum Environment {
    case production
    case staging
    case dev
}

extension Environment: NetworkEnvironment {
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

### Initializing `ObservableNetworking`

Once the environment has been defined it is time to initialize the framework by passing in the selected environment. This framework conforms to the `ObservableNetwork` protocol so that it is easily mocked for testing. All that is then needed is to grab the `network` from the instantiation.

```Swift
let networkingFramework = ObservableNetworking(environment: .dev)
let network = networkingFramework.network
```

### Types of Requests

* **Authenticated Requests**
```Swift
// Authenticate request signature
network.authenticatedRequest(method:endpoint:parameters:headers:)`
```
* **Unauthenticated Requests**
```Swift
// Unauthenticated request signature
network.request(method:endpoint:parameters:headers:)
```

### Request building blocks

No matter which reactive framework is chosen, each type of network request has the same basic components which will need to be configured for the request.

#### Method - `HTTPMethod`

The `method` is the HTTP verb that indicates what kind of request is to be made. Some of the most common methods are `.get` ("GET") and .post ("POST"). There are a number more that are supported, all of which can be found [here](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods).

#### Endpoint - `String`

The `endpoint` is the last portion of the URL and will specify to the API what information you wish to send or receive as a result of the request.

#### Parameters - `[String : Any]?`

The `parameters` comprise the information that the API needs to properly process the request. For `.get` requests the parameters are added on to the end of the URL. For `.post`, `.patch` or `.put` requests the parameters are serialized and added as the request's `httpBody`.

#### Headers - `[String : String]?`

The `headers` allow additional information to be passed along in a request or response. The framework automatically adds the `Accept: json` header in each request, but if needed, it will be overridden if another value is passed in with the `Accept` name.

For authenticated requests, an authorization cookie is automatically added (the cookie will automatically be stored when it comes back from the API) to be authenticated by the API. Authenticated requests also automatically get the `Accept: json` header as well.

### Choose the reactive framework

Now that the networking is instantiated and has an environment to build requests, it is time to decide which reactive framework to use for observing requests. `ObservableNetworking` supports both [RxSwift](https://github.com/ReactiveX/RxSwift) and [Combine](https://developer.apple.com/documentation/combine) out of the box.

**Important Note**:

Apple's Combine framework is only supported on:
* iOS 13.0 and later
* OSX 10.15 and later
* Mac Catalyst 13.0 and later
* tvOS 13.0 and later
* watchOS 6.0 and later

If you need to support previous versions, then you will need to use RxSwift

## RxSwift Implementation Example
```Swift

let disposeBag = DisposeBag()

// Construct the parameters for the request
let params = [
    "q": "Bert"
]

// Specify the request's endpoint
let endpoint = "characters"

    api.request(method: .get, endpoint: endpoint, parameters: params, headers: nil)
        .subscribe(onNext: { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            case .success(let json):
                let decoder = JSONDecoder()

                do {
                    let character = decoder.decode(SesameStreetCharacter.self, from: json)
                    DispatchQueue.main.async {
                        self?.characterInfoLabel.text = character.bio
                    }
                } catch {
                    print("Error: decoding SesameStreetCharacter failed")
                }
            }
        })
        .disposed(by: disposeBag)
```

## Combine Implementation Example
```Swift
// Custom error to handle decoding mishaps
enum SampleError: Error {
    case decoding(description: String)
}

// Construct the parameters for the request
let params = [
    "q": "Bert"
]

// Specify the request's endpoint
let endpoint = "characters"

let _ = api.request(method: .get, endpoint: endpoint, parameters: params, headers: nil)
    .mapError { SampleError.decoding(description: $0.localizedDescription) }
    .flatMap(maxPublishers: .max(1), { json -AnyPublisher<SesameStreetCharacter, SampleError> in
        let decoder = JSONDecoder()

        return Just(json)
            .decode(type: SesameStreetCharacter.self, decoder: decoder)
            .mapError { SampleError.decoding(description: $0.localizedDescription) }
            .eraseToAnyPublisher()
    })
    .assertNoFailure()
    .receive(on: RunLoop.main)
    .map { $0.bio }
    .assign(to: \.text, on: characterInfoLabel)
```
