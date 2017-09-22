//
//  CoreDataLoadAction.swift
//  ULima
//
//  Created by Gabriel Lanata on 1/7/16.
//  Copyright © 2016 Universidad de Lima. All rights reserved.
//

#if os(iOS) || os(macOS)
    
    import Foundation
    import CoreData
    import StartAppsKitLogger
    
    open class CoreDataLoadActionSingle<U: NSManagedObject>: LoadAction<U> {
        
        open var predicate: NSPredicate?
        
        fileprivate func loadInner(completion: LoadResultClosure) {
            Log.info("Load single began")
            do {
                if let loadedValue = try NSManagedObject.fetchSingle(U.self, predicate: predicate) {
                    Log.verbose("Load single success")
                    completion(.success(loadedValue))
                } else {
                    let error = CoreDataError.fetchFailure("Item not found")
                    Log.error("Load single failed", error)
                    completion(.failure(error))
                }
            } catch {
                Log.error("Load single failed", error)
                completion(.failure(error))
            }
        }
        
        public init(
            predicate: NSPredicate? = nil
            )
        {
            self.predicate = predicate
            super.init(
                load: { _ in }
            )
            loadClosure = { (completion) -> Void in
                self.loadInner(completion: completion)
            }
        }
        
    }
    
    open class CoreDataLoadActionSingleOptional<U: NSManagedObject>: LoadAction<U?> {
        
        open var predicate: NSPredicate?
        
        fileprivate func loadInner(completion: LoadResultClosure) {
            Log.info("Load single optional began")
            do {
                let loadedValue = try NSManagedObject.fetchSingle(U.self, predicate: predicate)
                Log.verbose("Load single optional success")
                completion(.success(loadedValue))
            } catch {
                Log.error("Load single optional failed", error)
                completion(.failure(error))
            }
        }
        
        public init(
            predicate: NSPredicate? = nil
            )
        {
            self.predicate = predicate
            super.init(
                load: { _ in }
            )
            loadClosure = { (completion) -> Void in
                self.loadInner(completion: completion)
            }
        }
        
    }
    
    open class CoreDataLoadAction<U: NSManagedObject>: LoadAction<[U]> {
        
        open var predicate:       NSPredicate?
        open var sortDescriptors: [NSSortDescriptor]?
        
        fileprivate func loadInner(completion: LoadResultClosure) {
            Log.info("Load began")
            do {
                let loadedValue = try NSManagedObject.fetch(U.self, predicate: predicate, sortDescriptors: sortDescriptors)
                Log.verbose("Load success")
                completion(.success(loadedValue))
            } catch {
                Log.error("Load failure", error)
                completion(.failure(error))
            }
        }
        
        public init(
            predicate:       NSPredicate? = nil,
            sortDescriptors: [NSSortDescriptor]? = nil,
            dummy:           (() -> ())? = nil)
        {
            self.predicate = predicate
            self.sortDescriptors = sortDescriptors
            super.init(
                load: { _ in }
            )
            loadClosure = { (completion) -> Void in
                self.loadInner(completion: completion)
            }
        }
        
    }
    
#endif
