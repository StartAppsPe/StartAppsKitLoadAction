//
//  ProcessLoadAction.swift
//  Pods
//
//  Created by Gabriel Lanata on 24/8/16.
//
//

import Foundation

public enum ProcessLoadError: Error {
    case automaticProcessFailure
}

open class ProcessLoadAction<A, T>: LoadAction<T> {
    
    public typealias ProcessResult = (_ loadedValue: A) throws -> T
    
    open var processClosure: ProcessResult
    
    open var baseLoadAction: LoadAction<A>
    
    fileprivate func loadInner(completion: @escaping LoadedResultClosure) {
        baseLoadAction.load() { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let loadedValue):
                do {
                    let processedValue = try self.processClosure(loadedValue)
                    completion(.success(processedValue))
                } catch(let error) {
                    completion(.failure(error))
                }
            }
        }
    }
    
    public init(
        baseLoadAction: LoadAction<A>,
        process:        @escaping ProcessResult
        )
    {
        self.baseLoadAction = baseLoadAction
        self.processClosure = process
        super.init(
            load: { _ in }
        )
        let loadClosure = { (completion) -> Void in
            self.loadInner(completion: completion)
        }
        self.loadClosure = loadClosure
    }
    
}

public extension ProcessLoadAction {
    
    public class func automaticProcess(loadedValue: A) throws -> T {
        guard let loadedValue = loadedValue as? T else {
            throw ProcessLoadError.automaticProcessFailure
        }
        return loadedValue
    }
    
}

public extension LoadAction {
    
    public func then<B>(_ processClosure: @escaping ProcessLoadAction<T, B>.ProcessResult) -> LoadAction<B> {
        return ProcessLoadAction<T, B>(
            baseLoadAction: self,
            process: processClosure
        )
    }
    
}
