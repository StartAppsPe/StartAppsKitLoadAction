//
//  CoreData.swift
//  ULima
//
//  Created by Gabriel Lanata on 2/2/15.
//  Copyright (c) 2015 is.oto.pe. All rights reserved.
//

import CoreData
import StartAppsKitLogger

public enum CoreDataError: Error {
    case noEntityDescription, fetchFailure(String)
}

open class CoreData {
    
    // TODO: Verify this works on macOS
    private static var _applicationDocumentsDirectory: URL?
    private static func applicationDocumentsDirectory() -> URL {
        if _applicationDocumentsDirectory == nil {
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            _applicationDocumentsDirectory = urls[urls.count-1]
        }
        return _applicationDocumentsDirectory!
    }
    
    private static var _managedObjectModel: NSManagedObjectModel?
    private static func managedObjectModel() -> NSManagedObjectModel {
        if _managedObjectModel == nil {
            let modelURL = Bundle.main.url(forResource: "CoreData", withExtension: "momd")!
            _managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
        }
        return _managedObjectModel!
    }
    
    private static var _persistentStoreCoordinator: NSPersistentStoreCoordinator?
    private static func persistentStoreCoordinator() throws -> NSPersistentStoreCoordinator {
        if _persistentStoreCoordinator == nil {
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel())
            let url = applicationDocumentsDirectory().appendingPathComponent("CoreData.sqlite")
            let mOptions = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: mOptions)
            _persistentStoreCoordinator = coordinator
        }
        return _persistentStoreCoordinator!
    }
    
    private static var _managedObjectContext: NSManagedObjectContext?
    private static func managedObjectContext() throws -> NSManagedObjectContext {
        if _managedObjectContext == nil {
            let managedObjectContext = NSManagedObjectContext()
            managedObjectContext.persistentStoreCoordinator = try persistentStoreCoordinator()
            _managedObjectContext = managedObjectContext
        }
        return _managedObjectContext!
    }
    
    public class func create(entityName: String) throws -> NSManagedObject {
        print(owner: "CoreData", items: "Create began", level: .verbose)
        let managedContext = try managedObjectContext()
        if let entity =  NSEntityDescription.entity(forEntityName: entityName, in: managedContext) {
            print(owner: "CoreData", items: "Create success (\(entityName))", level: .info)
            return NSManagedObject(entity: entity, insertInto: managedContext)
        } else {
            throw CoreDataError.noEntityDescription
        }
    }
    
    public class func save() throws {
        print(owner: "CoreData", items: "Save began", level: .verbose)
        let managedContext = try managedObjectContext()
        guard managedContext.hasChanges else {
            print(owner: "CoreData", items: "Save skipped because no changes", level: .warning)
            return
        }
        try managedContext.save()
        print(owner: "CoreData", items: "Save success", level: .verbose)
    }
    
    open class func delete(object: NSManagedObject) throws {
        print(owner: "CoreData", items: "Delete began", level: .verbose)
        let managedContext = try managedObjectContext()
        managedContext.delete(object)
        print(owner: "CoreData", items: "Delete success", level: .warning)
    }
    
    open class func fetch<T : NSFetchRequestResult>(_ entity: T.Type, entityName: String, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) throws -> [T] {
        let managedContext = try managedObjectContext()
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.predicate = predicate
        return try managedContext.fetch(fetchRequest)
    }
    
}

public extension NSManagedObject { // Quitar en Swift 2.0
    
    public class func create<T:NSManagedObject>(_ entity: T.Type) throws -> T where T:ClassNameable {
        return try CoreData.create(entityName: T.className) as! T
    }
    
    public class func create<T:NSManagedObject>(_ entity: T.Type, uid: String) throws -> T where T:UniquedObject {
        var obj = try create(entity)
        obj.uid = uid
        return obj
    }
    
    public class func fetch<T:NSManagedObject>(_ entity: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) throws -> [T] where T:ClassNameable {
        return try CoreData.fetch(entity, entityName: T.className, predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    public class func fetchSingle<T:NSManagedObject>(_ entity: T.Type, predicate: NSPredicate? = nil) throws -> T? {
        return try fetch(entity, predicate: predicate).first
    }
    
    public class func fetchSingle<T:NSManagedObject>(_ entity: T.Type, uid: String) throws -> T? where T:UniquedObject {
        return try fetchSingle(entity, predicate: NSPredicate(format: "uid == %@", uid))
    }
    
    public class func fetchSingleOrCreate<T:NSManagedObject>(_ entity: T.Type, uid: String) throws -> T where T:UniquedObject {
        return try fetchSingle(entity, uid: uid) ?? create(entity, uid: uid)
    }
    
    public func delete() throws {
        try CoreData.delete(object: self)
    }
    
    public func save() throws {
        try CoreData.save()
    }
    
}



public protocol UniquedObject {
    var uid: String { get set }
}


extension NSManagedObject: ClassNameable { }

public protocol ClassNameable: class {
    
    static var className: String { get }
    
    var className: String { get }
    
}

public extension ClassNameable {
    
    public static var className: String {
        return NSStringFromClass(self).components(separatedBy: ".").last!
    }
    
    public var className: String {
        return type(of: self).className
    }
    
}
