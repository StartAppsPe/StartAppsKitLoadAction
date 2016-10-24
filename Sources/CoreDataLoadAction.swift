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

open class CoreDataLoadActionSingle<U: NSManagedObject>: LoadAction<U?> {
    
    open var predicate:       NSPredicate?
    
    fileprivate func loadInner(completion: LoadResultClosure) {
        print(owner: "LoadAction[CoreData]", items: "Load single began", level: .info)
        let loadedValue = NSManagedObject.fetchSingle(U.self, predicate: predicate)
        print(owner: "LoadAction[CoreData]", items: "Load single success", level: .verbose)
        completion(.success(loadedValue))
    }
    
    public init(
        predicate:       NSPredicate? = nil,
        dummy:           (() -> ())? = nil)
    {
        self.predicate = predicate
        super.init(
            load:      { _ in }
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
        print(owner: "LoadAction[CoreData]", items: "Load Began", level: .info)
        let loadedValue = NSManagedObject.fetch(U.self, predicate: predicate, sortDescriptors: sortDescriptors)
        print(owner: "LoadAction[CoreData]", items: "Load Success", level: .info)
        completion(.success(loadedValue))
    }
    
    public init(
        predicate:       NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        dummy:           (() -> ())? = nil)
    {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        super.init(
            load:      { _ in }
        )
        loadClosure = { (completion) -> Void in
            self.loadInner(completion: completion)
        }
    }
    
}

#endif
