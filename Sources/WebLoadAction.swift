//
//  WebLoadAction.swift
//  Pods
//
//  Created by Gabriel Lanata on 2/10/16.
//
//

import Foundation
import StartAppsKitLogger

public enum WebLoadError: LocalizedError {
    case noInternet, emptyResponse
    public var errorDescription: String? {
        switch self {
        case .noInternet:
            return "No internet connection".localized
        case .emptyResponse:
            return "Empty response".localized
        }
    }
}

open class WebLoadAction: LoadAction<Data> {
    
    open var urlRequest: URLRequest
    
    open var session: URLSession {
        return URLSession.shared
    }
    
    fileprivate func loadInner(completion: @escaping LoadResultClosure) {
        Log.debug("Load Began (Url: \(urlRequest.url?.absoluteString ?? "-"))")
        session.dataTask(with: urlRequest, completionHandler: { (loadedData, urlResponse, error) -> Void in
            if let error = error {
                switch (error as NSError).code {
                case -1001, -1003, -1009:
                    let newError = WebLoadError.noInternet
                    Log.error("Load failure, \(newError) (Url: \(self.urlRequest.url?.absoluteString ?? "-"))")
                    completion(.failure(newError))
                    return
                default:
                    Log.error("Load failure, \(error) (Url: \(self.urlRequest.url?.absoluteString ?? "-"))")
                    completion(.failure(error))
                    return
                }
            }
            guard let loadedData = loadedData else {
                Log.error("Load failure, empty response (Url: \(self.urlRequest.url?.absoluteString ?? "-"))")
                let error = WebLoadError.emptyResponse
                completion(.failure(error))
                return
            }
            Log.verbose("Load success (Url: \(self.urlRequest.url?.absoluteString ?? "-"))")
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


public func StringProcess(_ loadedValue: Data) throws -> String {
    return try String(data: loadedValue)
}

public func StringProcess(_ loadedValue: [UInt8]) throws -> String {
    return try String(bytes: loadedValue)
}
