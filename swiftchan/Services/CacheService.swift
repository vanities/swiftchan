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
        let documentsUrl = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return documentsUrl
    }()

    func getFileWith(stringUrl: String, completionHandler: @escaping (Result<URL, Error>) -> Void ) {
        let cacheURL = cacheURL(URL(string: stringUrl)!)

        // return file path if already exists in cache directory
        guard !cacheHit(file: cacheURL)  else {
            // print("file exists in cache \(file.path)" )
            completionHandler(.success(cacheURL))
            return
        }

        URLSession.shared.downloadTask(with: URL(string: stringUrl)!) { [weak self] urlOrNil, _, _ in
            guard let tempURL = urlOrNil else { return }
            self?.cache(tempURL: tempURL, cacheURL: cacheURL) { result in
                completionHandler(result)
            }
        }.resume()
    }

    func getCacheValue(_ url: URL) -> URL? {
        let cacheUrl = cacheURL(url)
        if cacheHit(file: cacheUrl) {
            return cacheUrl
        }
        return nil
    }

    func cacheURL(_ url: URL) -> URL {
        return directoryFor(stringUrl: url.absoluteString)
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
        let cacheHit = fileManager.fileExists(atPath: file.path)
        // debugPrint("cache \(cacheHit ? "hit" : "miss") \(file)")
        return cacheHit
    }

    func deleteAll(complete: ((Result<Void, Error>) -> Void)?) {
        ImageCache.default.clearDiskCache { [weak self] in
            print("Removed Kingfisher Cache")
            self?.deleteLocal { result in
                complete?(result)
            }
        }
    }

    func deleteLocal(complete: ((Result<Void, Error>) -> Void)) {
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: mainDirectoryUrl, includingPropertiesForKeys: nil, options: [])
            for file in directoryContents {
                do {
                    print("removing \(file) from cache")
                    try fileManager.removeItem(at: file)
                    print("removed \(file) from cache")
                } catch {
                    complete(.failure("could not delete files form cache"))
                }
            }
            complete(.success(()))
        } catch {
            complete(.failure("could not delete files form cache"))
        }
    }

    func directoryFor(stringUrl: String) -> URL {
        let fileURL = URL(string: stringUrl)!.lastPathComponent
        let file = mainDirectoryUrl.appendingPathComponent(fileURL)
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
