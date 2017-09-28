//
//  LoadActionProtocol.swift
//  StartAppsKit
//
//  Created by Gabriel Lanata on 9/17/15.
//  Copyright (c) 2014 StartApps. All rights reserved.
//  Version: 1.0
//

import Foundation

public enum LoadingStatus {
    case ready, loading
}

public enum DisplayState {
    case none, loaded, loading, empty, error(Error)
}

public enum LoadActionProperties {
    case status, error, value, date
}

public protocol LoadActionDelegate: AnyObject {
    func loadActionUpdated<L: LoadActionType>(loadAction: L, updatedProperties: Set<LoadActionProperties>)
}

public protocol LoadActionLoadableType: AnyObject {
    
    var loadingStatus: LoadingStatus { get } // Same as status
    var status:   LoadingStatus { get }
    var error:    Error?        { get }
    var date:     Date?         { get }
    var valueAny: Any?          { get }
    
    var displayState: DisplayState { get }
    
    var delegates: [LoadActionDelegate] { get set }
    
    func loadNew(completion: ((_ result: Result<Any>) -> Void)?)
    func loadAny(completion: ((_ result: Result<Any>) -> Void)?)
    
    var updatedProperties: Set<LoadActionProperties> { get set }
    
    func addDelegate(_ delegate: LoadActionDelegate, updateNow: Bool)
    func addDelegate(_ delegate: LoadActionDelegate)
    func removeDelegate(_ delegate: LoadActionDelegate)
    func sendDelegateUpdates(forced: Bool, final: Bool)
    
}

public protocol LoadActionType: LoadActionLoadableType {
    
    associatedtype T
    
    associatedtype UpdatedClosure = (_ loadAction: LoadActionType, _ updatedProperties: Set<LoadActionProperties>) -> Void
    
    associatedtype LoadedResultType    = Result<T>
    associatedtype LoadedResultClosure = (_ result: LoadedResultType) -> Void
    
    associatedtype LoadClosure = (_ completion: LoadedResultClosure) -> Void
    
    var value: T? { get }
    
    var updatedHandlers: [UpdatedClosure] { get }
    var completionHandlers: [LoadedResultClosure] { get }
    
    func load(updated: UpdatedClosure?, completion: LoadedResultClosure?)
    
}

public extension LoadActionType {
    
    public var loadingStatus: LoadingStatus {
        return status
    }
    
    public var valueAny: Any? {
        return value
    }
    
    public var displayState: DisplayState {
        if let value = value, (value as? NSArray)?.count ?? 1 > 0  {
            return .loaded
        } else if status == .loading {
            return .loading
        } else if let error = error {
            return .error(error)
        } else {
            return .empty
        }
    }
    
}
