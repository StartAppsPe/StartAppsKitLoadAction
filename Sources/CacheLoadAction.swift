//
//  CacheLoadAction.swift
//  Pods
//
//  Created by Gabriel Lanata on 9/21/15.
//
//

import Foundation
import StartAppsKitLogger

open class CacheLoadAction<T>: LoadAction<T> {
    
    public typealias UpdateCacheResult = (_ loadAction: CacheLoadAction<T>) throws -> Bool
    public typealias SaveToCacheResult = (_ loadedValue: T, _ loadAction: CacheLoadAction<T>) throws -> Void
    
    open var cacheLoadAction:    LoadAction<T>
    open var baseLoadAction:     LoadAction<T>
    open var saveToCacheClosure: SaveToCacheResult?
    open var updateCacheClosure: UpdateCacheResult
    
    fileprivate var useForcedNext: Bool = false
    
    
    /**
     Loads value giving the option of paging or loading new.
     
     - parameter forced: If true forces main load
     - parameter completion: Closure called when operation finished
     */
    open func load(forced: Bool, updated: UpdatedClosure? = nil, completion: LoadedResultClosure? = nil) {
        useForcedNext = forced
        load(updated: updated, completion: completion)
    }

    open func loadAny(forced: Bool, updated: UpdatedClosure? = nil, completion: ((Result<Any>) -> Void)? = nil) {
        load(forced: forced, updated: updated) { (resultGeneric) -> Void in
            switch resultGeneric {
            case .success(let loadedValue):
                completion?(.success(loadedValue))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    open override func loadNew(updated: UpdatedClosure? = nil, completion: ((Result<Any>) -> Void)? = nil) {
        Log.debug("Load New")
        loadAny(forced: true, updated: updated, completion: completion)
    }
    
    fileprivate func loadInner(completion: @escaping LoadedResultClosure) {
        guard useForcedNext == false else {
            self.loadCache(completion: { (result) in
                switch result {
                case .success(let value):
                    Log.verbose("Pre updated value from cache")
                    self.value = value
                    self.sendDelegateUpdates()
                case .failure(_):
                    break
                }
                self.loadBase(completion: completion)
            })
            useForcedNext = false
            return
        }
        self.loadCache(completion: { (result) in
            switch result {
            case .success(let value):
                do {
                    if try self.updateCacheClosure(self) {
                        Log.verbose("Pre updated value from cache")
                        self.value = value
                        self.sendDelegateUpdates()
                        self.loadBase(completion: completion)
                    } else {
                        completion(result)
                    }
                } catch {
                    // Must load base when load cache fails
                    Log.error("Fallback to base 2")
                    Log.verbose("Pre updated value from cache")
                    self.value = value
                    self.sendDelegateUpdates()
                    self.loadBase(completion: completion)
                }
            case .failure(_):
                // Must load base when load cache fails
                Log.error("Fallback to base 1")
                self.loadBase(completion: completion)
            }
        })
    }
    
    /**
     Loads new data from cache and updates the action
     
     - parameter completion: Closure called when operation finished
     */
    fileprivate func loadCache(completion: @escaping LoadedResultClosure) {
        Log.debug("Cache Load Began")
        cacheLoadAction.load() { (result) in
            switch result {
            case .success(_):
                Log.verbose("Cache Load Success")
                completion(result)
            case .failure(let error):
                Log.error("Cache Load Failure. \(error)")
                completion(result)
            }
        }
    }
    
    /**
     Loads new data from base and updates the action
     
     - parameter completion: Closure called when operation finished
     */
    fileprivate func loadBase(completion: @escaping LoadedResultClosure) {
        Log.debug("Base Load Began")
        baseLoadAction.load() { (result) in
            switch result {
            case .success(let value):
                if let saveToCacheClosure = self.saveToCacheClosure {
                    Log.verbose("Save to Cache Began")
                    do {
                        try saveToCacheClosure(value, self)
                        Log.verbose("Save to Cache Success")
                        Log.verbose("Base Load Success")
                        completion(result)
                    } catch(let error) {
                        Log.verbose("Save to Cache Failure. \(error)")
                        Log.verbose("Base Load Failure. \(error)")
                        completion(.failure(error))
                    }
                } else {
                    Log.verbose("Base Load Success")
                    completion(result)
                }
            case .failure(let error):
                Log.error("Base Load Failure. \(error)")
                completion(result)
            }
        }
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
        baseLoadAction:  LoadAction<T>,
        cacheLoadAction: LoadAction<T>,
        saveToCache:     SaveToCacheResult?,
        updateCache:     @escaping UpdateCacheResult
        )
    {
        self.baseLoadAction     = baseLoadAction
        self.cacheLoadAction    = cacheLoadAction
        self.saveToCacheClosure = saveToCache
        self.updateCacheClosure = updateCache
        super.init(
            load: { _ in }
        )
        loadClosure = { (completion) -> Void in
            self.loadInner(completion: completion)
        }
    }
    
}

