//
//  FileLoadAction.swift
//  Pods
//
//  Created by Gabriel Lanata on 10/8/16.
//
//

import Foundation
import StartAppsKitLogger

open class ProcessFileLoadAction<T>: ProcessLoadAction<Data, T> {
    
    public init(
        filePath: String,
        process:  @escaping ProcessResult,
        dummy:    (() -> ())? = nil)
    {
        super.init(
            baseLoadAction: FileLoadAction(filePath: filePath),
            process: process
        )
    }
    
}


open class FileLoadAction: LoadAction<Data> {
    
    open var filePath: String
    
    fileprivate func loadInner(completion: LoadResultClosure) {
        do {
            completion(.success(try FileLoadAction.loadFromFile(filePath: filePath)))
        } catch (let error) {
            completion(.failure(error))
        }
    }
    
    public init(filePath: String) {
        self.filePath  = filePath
        super.init(
            load: { _ in }
        )
        loadClosure = { (result) -> Void in
            self.loadInner(completion: result)
        }
    }
    
}

public extension FileLoadAction {
    
    public class func filePath(string rawFilePath: String) -> URL {
        // TODO: Make this generic
        let rawFullFilePath = "\(NSHomeDirectory())/Documents/\(rawFilePath)"
        return URL(fileURLWithPath: rawFullFilePath)
    }
    
    public class func loadFromFile(filePath rawFilePath: String) throws -> Data {
        let filePath = self.filePath(string: rawFilePath)
        print(owner: "LoadAction[File]", items: "Load Began (\(filePath))", level: .debug)
        do {
            let loadedData = try Data(contentsOf: filePath)
            print(owner: "LoadAction[File]", items: "Load Success", level: .debug)
            return loadedData
        } catch (let error) {
            print(owner: "LoadAction[File]", items: "Load Failure. \(error)", level: .error)
            throw error
        }
    }
    
    public class func saveToFile(filePath rawFilePath: String, value: Data) throws {
        let filePath = self.filePath(string: rawFilePath)
        print(owner: "LoadAction[File]", items: "Save Began (\(filePath))", level: .debug)
        do {
            try value.write(to: filePath, options: [.atomic])
            print(owner: "LoadAction[File]", items: "Save Success", level: .debug)
        } catch (let error) {
            print(owner: "LoadAction[File]", items: "Save Failure. \(error)", level: .error)
            throw error
        }
    }
    
}
