//
//  CacheService.swift
//  swiftchan
//
//  Created by vanities on 11/7/20.
//

import Foundation
import Kingfisher

class CacheManager {

    static let shared = CacheManager()
    private let fileManager = FileManager.default
    private lazy var mainDirectoryUrl: URL = {
        let documentsUrl = self.fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return documentsUrl
    }()

    func getFileWith(stringUrl: String, completionHandler: @escaping (Result<URL, Error>) -> Void ) {
        let cacheURL = self.cacheURL(stringURL: stringUrl)

        // return file path if already exists in cache directory
        guard !self.cacheHit(file: cacheURL)  else {
            // print("file exists in cache \(file.path)" )
            completionHandler(.success(cacheURL))
            return
        }

        URLSession.shared.downloadTask(with: URL(string: stringUrl)!) { urlOrNil, _, _ in
            guard let tempURL = urlOrNil else { return }
            self.cache(tempURL: tempURL, cacheURL: cacheURL) { result in
                completionHandler(result)
            }
        }.resume()
    }

    func cacheURL(stringURL: String) -> URL {
        return directoryFor(stringUrl: stringURL)
    }

    func cache(tempURL: URL, cacheURL: URL, complete: ((Result<URL, Error>) -> Void)) {
        do {
            try self.fileManager.moveItem(at: tempURL, to: cacheURL)
            debugPrint("completed writing file to cache \(cacheURL.path)" )
            complete(.success(cacheURL))
        } catch {
            debugPrint("failed writing file to cache \(cacheURL.path)" )
            complete(.failure(error))
        }
    }

    func cacheHit(file: URL) -> Bool {
        return fileManager.fileExists(atPath: file.path)
    }

    private func deleteAll() {
        let enumerator = self.fileManager.enumerator(atPath: self.mainDirectoryUrl.absoluteString)
        if let enumerator = enumerator {
            for url in enumerator.allObjects {
                do {
                    print("removing \(url) from cache")
                    try fileManager.removeItem(at: self.mainDirectoryUrl)
                    print("removed \(url) from cache")
                } catch {
                    print("could not remove \(url) from cache")
                }
            }
        } else {
            print("not enumerator for deleteAll cache")
        }

        ImageCache.default.clearDiskCache { print("Removed Kingfisher Cache") }
    }

    func directoryFor(stringUrl: String) -> URL {
        let fileURL = URL(string: stringUrl)!.lastPathComponent
        let file = self.mainDirectoryUrl.appendingPathComponent(fileURL)
        return file
    }

    func calculateTotalCache() {
        ImageCache.default.calculateDiskStorageSize { result in
            switch result {
            case .success(let size):
                print("King Fisher Disk cache size: \(Double(size) / 1024 / 1024) MB")
            case .failure(let error):
                print(error)
            }
        }
    }

}
