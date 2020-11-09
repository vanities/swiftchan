//
//  CacheService.swift
//  swiftchan
//
//  Created by vanities on 11/7/20.
//

import Foundation

public enum Result<T> {
    case success(T)
    case failure(NSError)
}

class CacheManager {

    static let shared = CacheManager()
    private let fileManager = FileManager.default
    private var checked = Set<String>()
    private lazy var mainDirectoryUrl: URL = {
        let documentsUrl = self.fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return documentsUrl
    }()

    func getFileWith(stringUrl: String, completionHandler: @escaping (Result<URL>) -> Void ) {

        guard checked.contains(stringUrl) == false else {
            print("\(stringUrl) caching already" )
            return
        }
        checked.insert(stringUrl)

        let file = directoryFor(stringUrl: stringUrl)

        //return file path if already exists in cache directory
        guard !fileManager.fileExists(atPath: file.path)  else {
            print("file exists in cache \(file.path)" )
            completionHandler(Result.success(file))
            return
        }

        DispatchQueue.global().async {

            if let videoData = NSData(contentsOf: URL(string: stringUrl)!) {
                print("writing file to cache \(file.path)" )
                videoData.write(to: file, atomically: true)
                DispatchQueue.main.async {
                    completionHandler(Result.success(file))
                    print("completed writing file to cache \(file.path)" )
                }
            } else {
                DispatchQueue.main.async {
                    print("failed writing file to cache \(file.path)" )
                    let error = NSError(domain: "SomeErrorDomain", code: -2001 /* some error code */, userInfo: ["description": "Can't download video"])

                    completionHandler(Result.failure(error))
                }
            }
        }
    }

    private func deleteAll() {
        let enumerator = self.fileManager.enumerator(atPath: self.mainDirectoryUrl.absoluteString)
        if let enumerator = enumerator {
            for url in enumerator.allObjects {
                print("removing \((url as! NSURL).path!) from cache")
                try! fileManager.removeItem(at: self.mainDirectoryUrl)
                print("removed \((url as! NSURL).path!) from cache")
            }
        } else {
            print("not enumerator for deleteAll cache")
        }
    }

    private func directoryFor(stringUrl: String) -> URL {

        let fileURL = URL(string: stringUrl)!.lastPathComponent
        let file = self.mainDirectoryUrl.appendingPathComponent(fileURL)
        return file
    }

}
