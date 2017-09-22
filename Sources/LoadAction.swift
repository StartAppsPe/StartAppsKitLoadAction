//
//  LoadAction.swift
//  StartAppsKit
//
//  Created by Gabriel Lanata on 9/17/15.
//  Copyright (c) 2014 StartApps. All rights reserved.
//  Version: 1.0
//

import Foundation
import StartAppsKitLogger

public let LoadActionUpdatedNotification = "LoadActionUpdatedNotification"
public var LoadActionLoadingCount: Int = 0 {
    didSet {
        NotificationCenter.default.post(name: Notification.Name(rawValue: LoadActionUpdatedNotification), object: nil)
    }
}
public var LoadActionAllStatus: LoadingStatus {
    return (LoadActionLoadingCount == 0 ? .ready : .loading)
}

open class LoadAction<T>: LoadActionType {
    
    public typealias LoadResultClosure  = (_ result: Result<T>) -> Void
    public typealias LoadResult         = (_ completion: @escaping LoadResultClosure) -> Void
    
    open var updatedProperties: Set<LoadActionProperties> = []
    open var delegates: [LoadActionDelegate] = []
    
    open var status: LoadingStatus = .ready {
        didSet { updatedProperties.insert(.status) }
    }
    open var error: Error? {
        didSet { updatedProperties.insert(.error) }
    }
    open var value: T? {
        didSet { updatedProperties.insert(.value); date = Date.now() }
    }
    open var date: Date? {
        didSet { updatedProperties.insert(.date) }
    }
    
    open var loadClosure: LoadResult!
    
    open var completionHandlers: [LoadResultClosure] = []
    
    /**
     Loads value giving the option of paging or loading new.
     
     - parameter completion: Closure called when operation finished
     */
    open func load(completion: LoadResultClosure?) {
        Log.debug("Load Began")
        
        // Add completion handler to the stack
        if let completion = completion {
            completionHandlers.append(completion)
        }
        
        // Cancel if already loading
        guard status != .loading else {
            // Completion handler will be called later
            Log.debug("Load Batched")
            self.sendDelegateUpdates()
            return
        }
        
        // Adjust loading status to loading kind
        status = .loading
        LoadActionLoadingCount += 1
        sendDelegateUpdates()
        
        // Load value
        loadClosure() { (result) -> () in
            
            switch result {
            case .failure(let error):
                Log.error("Loaded Failure (\(error))")
                self.error = error
            case .success(let loadedValue):
                Log.debug("Loaded Success")
                self.value = loadedValue
                self.error = nil
            }
            
            // Adjust loading status to loaded kind and call completion
            DispatchQueue.main.async {
                self.status = .ready
                LoadActionLoadingCount -= 1
                self.sendDelegateUpdates()
                while !self.completionHandlers.isEmpty {
                    let completion = self.completionHandlers.removeFirst()
                    completion(result)
                }
            }
        }
        
    }
    
    open func loadNew(completion: ((_ result: Result<Any>) -> Void)? = nil) {
        loadAny(completion: completion)
    }
    
    open func loadAny(completion: ((_ result: Result<Any>) -> Void)?) {
        load() { (resultGeneric) -> Void in
            switch resultGeneric {
            case .success(let loadedValue):
                completion?(.success(loadedValue))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }
    
    /**
     Quick initializer with all closures
     
     - parameter load: Closure to load from web, must call result closure when finished
     - parameter delegates: Array containing objects that react to updated value
     */
    public init(
        load:  @escaping LoadResult,
        dummy: (() -> ())? = nil)
    {
        self.loadClosure = load
    }
    
}

public func Load<B>(_ startLoadAction: (() -> LoadAction<B>)) -> LoadAction<B> {
    return startLoadAction()
}

public extension LoadAction {
    
    public func then<B>(_ thenLoadAction: ((_ loadAction: LoadAction<T>) -> LoadAction<B>)) -> LoadAction<B> {
        return thenLoadAction(self)
    }
    
}
