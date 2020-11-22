//
//  Buildable.swift
//  swiftchan
//
//  Created by vanities on 11/22/20.
//

import Foundation

/// Adds a helper function to mutate a properties and help implement _Builder_ pattern
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
protocol Buildable { }

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension Buildable {

    /// Mutates a property of the instance
    ///
    /// - Parameter keyPath:    `WritableKeyPath` to the instance property to be modified
    /// - Parameter value:      value to overwrite the  instance property
    func mutating<T>(keyPath: WritableKeyPath<Self, T>, value: T) -> Self {
        var newSelf = self
        newSelf[keyPath: keyPath] = value
        return newSelf
    }

}
