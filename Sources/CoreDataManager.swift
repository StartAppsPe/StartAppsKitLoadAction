//
//  CoreData.swift
//  ULima
//
//  Created by Gabriel Lanata on 2/2/15.
//  Copyright (c) 2015 is.oto.pe. All rights reserved.
//

#if os(iOS) || os(macOS)

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
    private static func persistentStoreCoordinator() -> NSPersistentStoreCoordinator {
        if _persistentStoreCoordinator == nil {
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel())
            let url = applicationDocumentsDirectory().appendingPathComponent("CoreData.sqlite")
            let mOptions = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
            try! coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: mOptions)
            _persistentStoreCoordinator = coordinator
        }
        return _persistentStoreCoordinator!
    }
    
    private static var _managedObjectContext: NSManagedObjectContext?
    private static func managedObjectContext() -> NSManagedObjectContext {
        if _managedObjectContext == nil {
            let managedObjectContext = NSManagedObjectContext.init(concurrencyType: .mainQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator()
            _managedObjectContext = managedObjectContext
        }
        return _managedObjectContext!
    }
    
    public class func create(entityName: String) -> NSManagedObject {
        let managedContext = managedObjectContext()
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: managedContext)!
        let newEntity = NSManagedObject(entity: entity, insertInto: managedContext)
        Log.info("Created (\(entityName))")
        return newEntity
    }
    
    public class func save() throws {
        Log.verbose("Save began")
        let managedContext = managedObjectContext()
        guard managedContext.hasChanges else {
            Log.info("Save skipped because no changes")
            return
        }
        try managedContext.save()
        Log.info("Save success")
    }
    
    open class func delete(object: NSManagedObject) {
        let managedContext = managedObjectContext()
        managedContext.delete(object)
        Log.info("Deleted 1 object")
    }
    
    open class func fetch<T : NSFetchRequestResult>(_ entity: T.Type, entityName: String, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) throws -> [T] {
        Log.verbose("Fetch began (\(entityName))")
        let managedContext = managedObjectContext()
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.predicate = predicate
        let objects = try managedContext.fetch(fetchRequest)
        Log.verbose("Fetch succes (\(entityName))")
        return objects
    }
    
}

public extension NSManagedObject { // Quitar en Swift 2.0
    
    public class func create<T:NSManagedObject>(_ entity: T.Type) -> T {
        return CoreData.create(entityName: T.className) as! T
    }
    
    public class func create<T:NSManagedObject>(_ entity: T.Type, uid: String) -> T where T:UniquedObject {
        var obj = create(entity)
        obj.uid = uid
        return obj
    }
    
    public class func fetch<T:NSManagedObject>(_ entity: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) throws -> [T] {
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
    
    public func delete() {
        CoreData.delete(object: self)
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

#endif
