//
//  CacheService.swift
//  swiftchan
//
//  Created by vanities on 11/7/20.
//

import Foundation
import Cache

final class CacheService {
    static let shared = CacheService()
    static var storage: Storage<URL, String>?
    
    private init() {
        let diskConfig = DiskConfig(
            // The name of disk storage, this will be used as folder name within directory
            name: "swiftchan",
            // Expiry date that will be applied by default for every added object
            // if it's not overridden in the `setObject(forKey:expiry:)` method
            expiry: .date(Date().addingTimeInterval(2*3600)),
            // Maximum size of the disk cache storage (in bytes)
            maxSize: 10000,
            // Where to store the disk cache. If nil, it is placed in `cachesDirectory` directory.
            directory: try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                    appropriateFor: nil, create: true).appendingPathComponent("MyPreferences"),
            // Data protection is used to store files in an encrypted format on disk and to decrypt them on demand
            protectionType: .complete
        )
        let memoryConfig = MemoryConfig(
            // Expiry date that will be applied by default for every added object
            // if it's not overridden in the `setObject(forKey:expiry:)` method
            expiry: .date(Date().addingTimeInterval(2*60)),
            /// The maximum number of objects in memory the cache should hold
            countLimit: 50,
            /// The maximum total cost that the cache can hold before it starts evicting objects
            totalCostLimit: 0
        )
        
        do {
            print("Initializing Cache Service")
            CacheService.storage = try Storage<URL, String>(
                diskConfig: diskConfig,
                memoryConfig: memoryConfig,
                transformer: TransformerFactory.forCodable(ofType: String.self) // Storage<String, String>
            )
        } catch {
            print(error)
            CacheService.storage = nil
        }
    }
    
    func getOrSet(key: URL, complete: @escaping (URL) -> Void) {
        self.exists(key: key) { exists in
            if exists {
                self.get(key: key) { value in
                    complete(value)
                }
            }
            else {
                self.set(key: key) {
                    self.get(key: key) { value in
                        complete(value)
                    }
                }
            }
        }
    }
    
    func exists(key: URL, value: @escaping (Bool) -> Void) {
        if let storage = CacheService.storage {
            storage.async.existsObject(forKey: key) { result in
                if case .value(let exists) = result, exists {
                    print("cache service found \(key) exists")
                    value(exists)
                }
            }
        }
        else {
            print("could not get storage!!")
        }
    }
    
    func set(key: URL, value: @escaping () -> Void) {
        if let storage = CacheService.storage {
            let cacheUrl = ""
            storage.async.setObject(cacheUrl, forKey: key) { result in
                switch result {
                case .value:
                    print("successfully set \(key) to cache")
                    value()
                case .error(let error):
                    print(error)
                }
            }
        }
        else {
            print("could not get storage!!")
        }
    }
    
    func get(key: URL, value: @escaping (URL) -> Void) {
        if let storage = CacheService.storage {
            storage.async.object(forKey: key) { result in
                switch result {
                case .value(let cacheUrl):
                    print("successfully got \(cacheUrl) from cache")
                    value(URL(string: cacheUrl)!)
                case .error(let error):
                    print(error)
                }
            }
        }
        else {
            print("could not get storage!!")
        }
    }
}
