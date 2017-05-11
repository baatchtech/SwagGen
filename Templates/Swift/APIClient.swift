//
// Networking.swift
//
// Generated by SwagGen
// https://github.com/yonaskolb/SwagGen
//

import Foundation
import Alamofire
import JSONUtilities

/// Manages and sends APIRequests
public class APIClient {

    public static var `default` = APIClient(baseURL: "{% if options.baseURL %}{{ options.baseURL }}{% else %}{{ baseURL }}{% endif %}")

    /// A list of RequestBehaviours that can be used to monitor and alter all requests
    public var behaviours: [RequestBehaviour] = []

    /// The base url prepended before every request path
    public var baseURL: String

    /// The Alamofire SessionManager used for each request
    public var sessionManager: SessionManager

    /// These headers will get added to every request
    public var defaultHeaders: [String: String]

    /// Used to authorise requests
    public var authorizer: RequestAuthorizer?

    public init(baseURL: String, sessionManager: SessionManager = .default, defaultHeaders: [String: String] = [:], behaviours: [RequestBehaviour] = [], authorizer: RequestAuthorizer? = nil) {
        self.baseURL = baseURL
        self.authorizer = authorizer
        self.sessionManager = sessionManager
        self.behaviours = behaviours
        self.defaultHeaders = defaultHeaders
    }

    /// Any request behaviours will be run in addition to the client behaviours
    public func makeRequest<T>(_ request: APIRequest<T>, behaviours: [RequestBehaviour] = [], complete: @escaping (DataResponse<T>) -> Void) {
        // create composite behaviour to make it easy to call functions on array of behaviours
        let requestBehaviour = APIRequestBehaviour(request: request, behaviours: self.behaviours + behaviours)

        // create the url request from the request
        var urlRequest: URLRequest
        do {
            urlRequest = try request.createURLRequest(baseURL: baseURL)
        } catch let error {
            let dataResponse = DataResponse<T>(request: nil, response: nil, data: nil, result: .failure(error))
            requestBehaviour.onFailure(error: error)
            complete(dataResponse)
            return
        }

        // add the default headers
        if urlRequest.allHTTPHeaderFields == nil {
            urlRequest.allHTTPHeaderFields = [:]
        }
        for (key, value) in defaultHeaders {
            urlRequest.allHTTPHeaderFields?[key] = value
        }

        urlRequest = requestBehaviour.modifyRequest(urlRequest)

        if let authorizer = authorizer, let authorization = request.service.authorization {

            // authorize request
            authorizer.authorize(request: requestBehaviour.request, authorization: authorization, urlRequest: urlRequest) { result in
                switch result {
                case .success(let urlRequest):
                    self.makeNetworkRequest(urlRequest: urlRequest, decoder: request.service.decode, requestBehaviour: requestBehaviour, complete: complete)
                case .failure(let error):
                    let dataResponse = DataResponse<T>(request: urlRequest, response: nil, data: nil, result: .failure(error))
                    requestBehaviour.onFailure(error: error)
                    complete(dataResponse)
                }
            }
        } else {
            self.makeNetworkRequest(urlRequest: urlRequest, decoder: request.service.decode, requestBehaviour: requestBehaviour, complete: complete)
        }
    }

    private func makeNetworkRequest<T>(urlRequest: URLRequest, decoder: @escaping (Any) throws -> T, requestBehaviour: APIRequestBehaviour, complete: @escaping (DataResponse<T>) -> Void) {
        requestBehaviour.beforeSend()
        sessionManager.request(urlRequest)
            .validate()
            .responseJSON { response in
                let result: Result<T>

                switch response.result {
                case .success(let value):
                    do {
                        let decoded = try decoder(json: value)
                        result = .success(decoded)
                        requestBehaviour.onSuccess(result: decoded)
                    } catch let error {
                        result = .failure(error)
                        requestBehaviour.onFailure(error: error)
                    }
                case .failure(let error):
                    result = .failure(error)
                    requestBehaviour.onFailure(error: error)
                }
                let dataResponse = response.withResult(result)
                requestBehaviour.onResponse(response: dataResponse.anyResponse)
                complete(dataResponse)
        }
    }
}

/// Allows a request that has an authorization on it to be authorized asynchronously
public protocol RequestAuthorizer {

    /// complete must be called with either .success(authorizedURLRequest) or .failure(failureReason)
    func authorize(request: APIRequest<Any>, authorization: Authorization, urlRequest: URLRequest, complete: (Result<URLRequest>) -> Void)
}

public protocol RequestBehaviour {

    /// runs first and allows the requests to be modified
    func modifyRequest(request: APIRequest<Any>, urlRequest: URLRequest) -> URLRequest

    /// called before request is sent
    func beforeSend(request: APIRequest<Any>)

    /// called when request is successful
    func onSuccess(request: APIRequest<Any>, result: Any)

    /// called when request failed
    func onFailure(request: APIRequest<Any>, error: Error)

    /// called if the request recieves a network response. This is not called if request fails validation or encoding
    func onResponse(request: APIRequest<Any>, response: DataResponse<Any>)
}

struct APIRequestBehaviour {

    let service: APIService<Any>
    let request: APIRequest<Any>
    let behaviours: [RequestBehaviour]

    init<T>(request: APIRequest<T>, behaviours: [RequestBehaviour]) {
        self.service = APIService<Any>(id: request.service.id, tag: request.service.tag, method: request.service.method, path: request.service.path, hasBody: request.service.hasBody, authorization: request.service.authorization, decode: request.service.decode)
        self.request = APIRequest(service: service, parameters: request.parameters, jsonBody: request.jsonBody, headers: request.headers)
        self.behaviours = behaviours
    }

    func beforeSend() {
        behaviours.forEach {
            $0.beforeSend(request: request)
        }
    }

    func onSuccess(result: Any) {
        behaviours.forEach {
            $0.onSuccess(request: request, result: result)
        }
    }

    func onFailure(error: Error) {
        behaviours.forEach {
            $0.onFailure(request: request, error: error)
        }
    }

    func onResponse(response: DataResponse<Any>) {
        behaviours.forEach {
            $0.onResponse(request: request, response: response)
        }
    }

    func modifyRequest(_ urlRequest: URLRequest) -> URLRequest {
        var urlRequest = urlRequest
        behaviours.forEach {
            urlRequest = $0.modifyRequest(request: request, urlRequest: urlRequest)
        }
        return urlRequest
    }
}

// Provides empty defaults so that each function becomes optional
public extension RequestBehaviour {
    func beforeSend(request: APIRequest<Any>) {}
    func onSuccess(request: APIRequest<Any>, result: Any) {}
    func onFailure(request: APIRequest<Any>, error: Error) {}
    func onResponse(request: APIRequest<Any>, response: DataResponse<Any>) {}
    func modifyRequest(request: APIRequest<Any>, urlRequest: URLRequest) -> URLRequest { return urlRequest }
}

extension DataResponse {

    var anyResponse: DataResponse<Any> {
        let anyResult: Result<Any> = result.isSuccess ? .success(result.value!) : .failure(result.error!)
        return DataResponse<Any>(request: request, response: response, data: data, result: anyResult, timeline: timeline)
    }

    func withResult<T>(_ result: Result<T>) -> DataResponse<T> {
        return DataResponse<T>(request: request, response: response, data: data, result: result, timeline: timeline)
    }
}

// Helper extension for sending requests
extension APIRequest {

    /// makes a request using the default APIClient. Change your baseURL in APIClient.default.baseURL
    public func makeRequest(complete: @escaping (DataResponse<ResponseType>) -> Void) {
        APIClient.default.makeRequest(self, complete: complete)
    }
}

// Create URLRequest
extension APIRequest {

    /// pass in an optional baseURL, otherwise URLRequest.url will be relative
    public func createURLRequest(baseURL: String = "") throws -> URLRequest {
        let url = URL(string: "\(baseURL)\(path)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = service.method
        urlRequest.allHTTPHeaderFields = headers

        // filter out parameters with empty string value
        var params: [String: Any] = [:]
        for (key, value) in parameters {
            if String.init(describing: value) != "" {
                params[key] = value
            }
        }
        if !params.isEmpty {
            let encoding: ParameterEncoding = service.hasBody ? URLEncoding.httpBody : URLEncoding.queryString
            urlRequest = try encoding.encode(urlRequest, with: params)
        }
        if let jsonBody = jsonBody {
            // not using Alamofire's JSONEncoding so that we can send a json array instead of being restricted to [String: Any]
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return urlRequest
    }
}