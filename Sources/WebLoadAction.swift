//
//  WebLoadAction.swift
//  Pods
//
//  Created by Gabriel Lanata on 2/10/16.
//
//

import Foundation
import StartAppsKitLogger

public enum WebLoadError: Error, LocalizedError {
    case noInternet, emptyResponse
    public var errorDescription: String? {
        switch self {
        case .noInternet:
            return NSLocalizedString("No internet connection.", comment: "")
        case .emptyResponse:
            return NSLocalizedString("Empty response.", comment: "")
        }
    }
}

open class WebLoadAction: LoadAction<Data> {
    
    open var urlRequest: URLRequest
    
    open var session: URLSession {
        return URLSession.shared
    }
    
    fileprivate func loadInner(completion: @escaping LoadResultClosure) {
        print(owner: "LoadAction[Web]", items: "Load Began (Url: \(urlRequest.url?.absoluteString ?? "-"))", level: .verbose)
        session.dataTask(with: urlRequest, completionHandler: { (loadedData, urlResponse, error) -> Void in
            if let error = error {
                switch (error as NSError).code {
                case -1001, -1003, -1009:
                    let newError = WebLoadError.noInternet
                    print(owner: "LoadAction[Web]", items: "Load failure, \(newError) (Url: \(self.urlRequest.url?.absoluteString ?? "-"))", level: .error)
                    completion(.failure(newError))
                    return
                default:
                    print(owner: "LoadAction[Web]", items: "Load failure, \(error) (Url: \(self.urlRequest.url?.absoluteString ?? "-"))", level: .error)
                    completion(.failure(error))
                    return
                }
            }
            guard let loadedData = loadedData else {
                print(owner: "LoadAction[Web]", items: "Load failure, empty response (Url: \(self.urlRequest.url?.absoluteString ?? "-"))", level: .error)
                let error = WebLoadError.emptyResponse
                completion(.failure(error))
                return
            }
            print(owner: "LoadAction[Web]", items: "Load success (Url: \(self.urlRequest.url?.absoluteString ?? "-"))", level: .verbose)
            completion(.success(loadedData))
        }).resume()
    }
    
    public init(urlRequest: URLRequest) {
        self.urlRequest  = urlRequest
        super.init(
            load: { _ in }
        )
        loadClosure = { (result) -> Void in
            self.loadInner(completion: result)
        }
    }
    
    public convenience init(url: URL) {
        self.init(urlRequest: URLRequest(url: url))
    }
    
}






