//
//  CacheService.swift
//  swiftchan
//
//  Created by vanities on 11/7/20.
//

import Foundation

class CacheManager {

    static let shared = CacheManager()
    private let fileManager = FileManager.default
    private var checked = Set<String>()
    private lazy var mainDirectoryUrl: URL = {
        let documentsUrl = self.fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return documentsUrl
    }()

    func getFileWith(stringUrl: String, completionHandler: @escaping (Result<URL, Error>) -> Void ) {
        guard self.checked.contains(stringUrl) == false else {
            print("\(stringUrl) caching already" )
            return
        }
        self.checked.insert(stringUrl)

        let file = directoryFor(stringUrl: stringUrl)

        //return file path if already exists in cache directory
        guard !fileManager.fileExists(atPath: file.path)  else {
            print("file exists in cache \(file.path)" )
            completionHandler(.success(file))
            self.checked.remove(stringUrl)
            return
        }

        URLSession.shared.downloadTask(with: URL(string: stringUrl)!) {
            urlOrNil, _, errorOrNil in
            guard let fileURL = urlOrNil else { return }
            do {
                try self.fileManager.moveItem(at: fileURL, to: file)
                print("completed writing file to cache \(file.path)" )
                completionHandler(.success(file))
                self.checked.remove(stringUrl)
            } catch {
                guard let error = errorOrNil else { return }
                print("failed writing file to cache \(file.path)" )
                completionHandler(.failure(error))
                self.checked.remove(stringUrl)
            }
        }.resume()
    }

    private func deleteAll() {
        let enumerator = self.fileManager.enumerator(atPath: self.mainDirectoryUrl.absoluteString)
        if let enumerator = enumerator {
            for url in enumerator.allObjects {
                print("removing \(url) from cache")
                try! fileManager.removeItem(at: self.mainDirectoryUrl)
                print("removed \(url) from cache")
            }
        } else {
            print("not enumerator for deleteAll cache")
        }
    }

    func directoryFor(stringUrl: String) -> URL {
        let fileURL = URL(string: stringUrl)!.lastPathComponent
        let file = self.mainDirectoryUrl.appendingPathComponent(fileURL)
        return file
    }

}
