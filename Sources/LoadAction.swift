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
    
    public typealias UpdatedClosure = (_ loadAction: LoadAction<T>, _ updatedProperties: Set<LoadActionProperties>) -> Void
    
    public typealias LoadedResultType     = Result<T>
    public typealias LoadedResultClosure  = (_ result: LoadedResultType) -> Void
    
    public typealias LoadClosure = (_ completion: @escaping LoadedResultClosure) -> Void
    
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
    
    open var loadClosure: LoadClosure
    
    open var updatedHandlers: [UpdatedClosure] = []
    open var completionHandlers: [LoadedResultClosure] = []
    
    /**
     Loads value giving the option of paging or loading new.
     
     - parameter completion: Closure called when operation finished
     */
    open func load(updated: UpdatedClosure? = nil, completion: LoadedResultClosure? = nil) {
        Log.debug("Load Began")
        
        // Add updated and completion handler to the stack
        if let updated = updated {
            updatedHandlers.append(updated)
        }
        if let completion = completion {
            completionHandlers.append(completion)
        }
        
        DispatchQueue.global().async {
            
            // Cancel if already loading
            guard self.status != .loading else {
                // Completion handler will be called later
                Log.debug("Load Batched")
                self.sendDelegateUpdates()
                return
            }
            
            // Adjust loading status to loading kind
            self.status = .loading
            LoadActionLoadingCount += 1
            self.sendDelegateUpdates()
            
            // Load value
             self.loadClosure() { (result) -> () in
                
                switch result {
                case .success(let loadedValue):
                    Log.debug("Loaded Success")
                    self.value = loadedValue
                    self.error = nil
                case .failure(let error):
                    Log.error("Loaded Failure (\(error))")
                    self.error = error
                }
                
                // Adjust loading status to loaded kind and call completion
                self.status = .ready
                LoadActionLoadingCount -= 1
                self.sendDelegateUpdates(final: true)
                DispatchQueue.main.async {
                    while !self.completionHandlers.isEmpty {
                        let completion = self.completionHandlers.removeFirst()
                        completion(result)
                    }
                }
            }
        }
    }
    
    open func loadNew(completion: ((_ result: Result<Any>) -> Void)? = nil) {
        loadAny(updated: nil, completion: completion)
    }
    
    open func loadNew(updated: UpdatedClosure?, completion: ((_ result: Result<Any>) -> Void)? = nil) {
        loadAny(updated: updated, completion: completion)
    }
    
    open func loadAny(completion: ((_ result: Result<Any>) -> Void)? = nil) {
        loadAny(updated: nil, completion: completion)
    }
    
    open func loadAny(updated: UpdatedClosure?, completion: ((_ result: Result<Any>) -> Void)? = nil) {
        load(updated: updated) { (resultGeneric) -> Void in
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
     */
    public init(
        load:  @escaping LoadClosure
        )
    {
        self.loadClosure = load
    }
    
}

extension LoadAction {
    
    public func sendDelegateUpdates(forced: Bool = false, final: Bool = false) {
        guard forced || self.updatedProperties.count > 0 else { return }
        DispatchQueue.main.async {
            Log.verbose("Sending delegate updates")
            for updatedHandler in self.updatedHandlers {
                updatedHandler(self, self.updatedProperties)
            }
            for delegate in self.delegates {
                delegate.loadActionUpdated(loadAction: self, updatedProperties: self.updatedProperties)
            }
            self.updatedProperties.removeAll()
            if final {
                self.updatedHandlers.removeAll()
            }
        }
    }
    
    public func addDelegate(_ delegate: LoadActionDelegate) {
        addDelegate(delegate, updateNow: true)
    }
    
    public func addDelegate(_ delegate: LoadActionDelegate, updateNow: Bool) {
        if !delegates.contains(where: { $0 === delegate }) {
            delegates.append(delegate)
            if updateNow {
                delegate.loadActionUpdated(loadAction: self, updatedProperties: [])
            }
        }
    }
    
    public func removeDelegate(_ delegate: LoadActionDelegate) {
        if let index = delegates.index(where: { $0 === delegate }) {
            delegates.remove(at: index)
        }
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
