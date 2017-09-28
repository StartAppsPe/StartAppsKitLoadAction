//
//  GroupLoadAction.swift
//  StartAppsKit
//
//  Created by Gabriel Lanata on 9/17/15.
//  Copyright (c) 2014 StartApps. All rights reserved.
//  Version: 1.0
//

import Foundation
import StartAppsKitExtensions

public struct IgnoreValue { }

public enum GroupLoadOrder {
    case parallel, sequential, sequentialForced
}

public enum GroupLoadError: Error {
    case noValueProcessed, noErrorProcessed
}

open class GroupLoadAction<T>: LoadAction<T> {
    
    public typealias ProcessValue  = (_ actions: [LoadActionLoadableType]) -> T?
    public typealias ProcessError  = (_ actions: [LoadActionLoadableType]) -> Error?
    
    open var processValueClosure: ProcessValue
    open var processErrorClosure: ProcessError
    
    open  var order:          GroupLoadOrder
    open  var actions:       [LoadActionLoadableType]
    fileprivate var actionsToLoad: [LoadActionLoadableType] = []
    
    fileprivate var forceNew = false
    open override func loadNew(updated: UpdatedClosure? = nil, completion: ((Result<Any>) -> Void)? = nil) {
        forceNew = true
        super.loadNew(updated: updated, completion: completion)
    }
    
    /**
     Loads data giving the option of paging or loading new.
     
     - parameter forced: If true forces main load
     - parameter completion: Closure called when operation finished
     */
    fileprivate func loadInner(completion: @escaping LoadAction<T>.LoadedResultClosure) {
        
        // Copy load actions
        actionsToLoad = actions
        
        // choose loading function
        switch order {
        case .sequential, .sequentialForced:
            loadSequential(forceNew: forceNew, completion: completion)
        case .parallel:
            loadParallel(forceNew: forceNew, completion: completion)
        }
        
        // Return force new to normal
        if forceNew { forceNew = false }
    }
    
    /**
     Loads data giving the option of paging or loading new.
     
     - parameter forced: If true forces main load
     - parameter completion: Closure called when operation finished
     */
    fileprivate func loadSequential(forceNew: Bool, completion: @escaping LoadAction<T>.LoadedResultClosure) {
        if let actionToLoad = actionsToLoad.popFirst() {
            let completionHandler: ((Result<Any>) -> Void) = { (result) -> Void in
                self.updateValueAndError()
                if result.isSuccess || self.order != .sequentialForced {
                    if self.actionsToLoad.count > 0 { self.sendDelegateUpdates() }
                    self.loadSequential(forceNew: forceNew, completion: completion)
                } else {
                    self.actionsToLoad = []
                    if let error = self.error {
                        completion(.failure(error))
                    } else {
                        let error = GroupLoadError.noErrorProcessed
                        completion(.failure(error))
                    }
                }
            }
            if forceNew {
                actionToLoad.loadNew(completion: completionHandler)
            } else {
                actionToLoad.loadAny(completion: completionHandler)
            }
        } else {
            self.updateValueAndError()
            if let value = self.value {
                completion(.success(value))
            } else {
                let error = GroupLoadError.noValueProcessed
                completion(.failure(error))
            }
        }
    }
    
    /**
     Loads data giving the option of paging or loading new.
     
     - parameter forced: If true forces main load
     - parameter completion: Closure called when operation finished
     */
    fileprivate func loadParallel(forceNew: Bool, completion: @escaping LoadAction<T>.LoadedResultClosure) {
        while let actionToLoad = actionsToLoad.popFirst() {
            let completionHandler: ((Result<Any>) -> Void) = { (result) -> Void in
                self.updateValueAndError()
                if self.actions.find({ $0.status != .ready }) == nil {
                    if let error = self.error { // self.actions.find({ $0.error != nil }) == nil
                        completion(.failure(error))
                    } else if let value = self.value {
                        completion(.success(value))
                    } else {
                        let error = GroupLoadError.noValueProcessed
                        completion(.failure(error))
                    }
                } else {
                    self.sendDelegateUpdates()
                }
            }
            if forceNew {
                actionToLoad.loadNew(completion: completionHandler)
            } else {
                actionToLoad.loadAny(completion: completionHandler)
            }
        }
    }
    
    fileprivate func updateValueAndError() {
        error = processErrorClosure(actions)
        value = processValueClosure(actions)
    }
    
    /**
     Quick initializer with all closures
     
     - parameter limitOnce: Only load one time automatically (does allow reload when called specifically)
     - parameter shouldUpdateCache: Load from cache before loading from web
     - parameter loadCache: Closure to load from cache, must call result closure when finished
     - parameter load: Closure to load from web, must call result closure when finished
     - parameter delegates: Array containing objects that react to updated data
     */
    public init(
        order:             GroupLoadOrder = .parallel,
        actions:          [LoadActionLoadableType],
        processValue:      ProcessValue? = nil,
        processError:      ProcessError? = nil
        )
    {
        self.order = order
        self.actions = actions
        if let processValue = processValue {
            self.processValueClosure = processValue
        } else {
            self.processValueClosure = GroupLoadAction.defaultProcessValueIgnore()
        }
        if let processError = processError {
            self.processErrorClosure = processError
        } else {
            self.processErrorClosure = GroupLoadAction.defaultProcessErrorFirst()
        }
        super.init(
            load: { _ in }
        )
        loadClosure = { (result) -> Void in
            self.loadInner(completion: result)
        }
    }
    
    fileprivate class func defaultProcessErrorFirst() -> ProcessError {
        return { (actions: [LoadActionLoadableType]) -> Error? in
            return actions.find({ $0.error != nil })?.error
        }
    }
    
    fileprivate class func defaultProcessValueLast() -> ProcessValue {
        return { (actions: [LoadActionLoadableType]) -> T? in
            return actions.reversed().find({ $0.valueAny as? T != nil })?.valueAny as? T
        }
    }
    
    fileprivate class func defaultProcessValueIgnore() -> ProcessValue {
        return { (actions: [LoadActionLoadableType]) -> T? in
            return (IgnoreValue() as! T)
        }
    }
    
}

