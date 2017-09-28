//
//  CompletionLoadAction.swift
//  ULima
//
//  Created by Gabriel Lanata on 8/9/16.
//  Copyright © 2016 Universidad de Lima. All rights reserved.
//

import StartAppsKitLogger

open class CompletionLoadAction<A, T>: LoadAction<T> {
    
    public typealias CompletionResult = (_ loadedValue: A) throws -> LoadAction<T>
    
    open var completionClosure: CompletionResult
    
    open var baseLoadAction: LoadAction<A>
    
    fileprivate func loadInner(completion: @escaping LoadedResultClosure) {
        Log.debug("Load Began")
        baseLoadAction.load() { (result) in
            switch result {
            case .failure(let error):
                Log.error("Load Failure Base")
                completion(.failure(error))
            case .success(let loadedValue):
                do {
                    try self.completionClosure(loadedValue).load(completion: { (result) in
                        switch result {
                        case .failure(let error):
                            Log.error("Load Failure")
                            completion(.failure(error))
                        case .success(let loadedValue2):
                            Log.verbose("Load Success")
                            completion(.success(loadedValue2))
                        }
                    })
                } catch(let error) {
                    Log.error("Load Failure Completion")
                    completion(.failure(error))
                }
            }
        }
    }
    
    public init(
        baseLoadAction: LoadAction<A>,
        completion:     @escaping CompletionResult,
        dummy:          (() -> ())? = nil
        )
    {
        self.baseLoadAction = baseLoadAction
        self.completionClosure = completion
        super.init(
            load: { _ in }
        )
        self.loadClosure = { (completion) -> Void in
            self.loadInner(completion: completion)
        }
    }
    
}


public extension LoadAction {
    
    public func then<B>(_ completionClosure: @escaping CompletionLoadAction<T, B>.CompletionResult) -> LoadAction<B> {
        return CompletionLoadAction<T, B>(
            baseLoadAction: self,
            completion: completionClosure
        )
    }
    
}
