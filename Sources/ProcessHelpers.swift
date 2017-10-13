//
//  ProcessHelpers.swift
//  StartAppsKitLoadActionPackageDescription
//
//  Created by Gabriel Lanata on 12/10/17.
//

import Foundation

public enum ProcessLoadError: Error {
    case automaticProcessFailure
}

public extension ProcessLoadAction {
    public class func automaticProcess(loadedValue: A) throws -> T {
        guard let loadedValue = loadedValue as? T else {
            throw ProcessLoadError.automaticProcessFailure
        }
        return loadedValue
    }
}


public func AutomaticProcess<A, T>(_ loadedValue: A) throws -> T {
    guard let loadedValue = loadedValue as? T else {
        throw ProcessLoadError.automaticProcessFailure
    }
    return loadedValue
}

public func UnwrapProcess<T>(_ loadedValue: T?) throws -> T {
    return try loadedValue.tryUnwrap()
}

public func MakeOptionalProcess<T>(_ loadedValue: T) throws -> T? {
    return loadedValue
}

public func SortProcess<T>(_ loadedValue: [T]) throws -> [T] where T : Comparable {
    return loadedValue.sorted()
}

public func ShuffleProcess<T>(_ loadedValue: [T]) throws -> [T] {
    return loadedValue.shuffled()
}

public func ReverseProcess<T>(_ loadedValue: [T]) throws -> [T] {
    return loadedValue.reversed()
}

public func FirstProcess<T>(_ loadedValue: [T]) throws -> T? {
    return loadedValue.first
}

public func LastProcess<T>(_ loadedValue: [T]) throws -> T? {
    return loadedValue.last
}

public func FilterNilsProcess<T>(_ loadedValue: [T?]) throws -> [T] {
    return loadedValue.flatMap({ $0 })
}
