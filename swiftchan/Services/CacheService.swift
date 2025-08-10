//
//  CacheService.swift
//  swiftchan
//
//  Created on 11/7/20.
//

import Foundation
import Kingfisher

// @MainActor
final class CacheManager {

    static let shared = CacheManager()
    private let fileManager = FileManager.default
    private lazy var mainDirectoryUrl: URL = {
        let documentsUrl = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return documentsUrl
    }()

    func getFileWith(stringUrl: String, completionHandler: @escaping (URL?) -> Void ) {
        let cacheURL = cacheURL(URL(string: stringUrl)!)

        // return file path if already exists in cache directory
        guard !cacheHit(file: cacheURL)  else {
            // print("file exists in cache \(file.path)" )
            completionHandler(cacheURL)
            return
        }

        URLSession.shared.downloadTask(with: URL(string: stringUrl)!) { [weak self] urlOrNil, _, _ in
            guard let tempURL = urlOrNil else { return }
            completionHandler(self?.cache(tempURL, cacheURL))
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

    func cache(_ tempURL: URL, _ cacheURL: URL) -> URL? {
        do {
            try? fileManager.removeItem(at: cacheURL)
            try fileManager.moveItem(at: tempURL, to: cacheURL)
            debugPrint("completed writing file to cache \(cacheURL.path)" )
            return cacheURL
        } catch {
            debugPrint("failed writing file to cache \(cacheURL.path)" )
            return nil
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
                    complete(.failure("could not delete files from cache"))
                }
            }
            complete(.success(()))
        } catch {
            complete(.failure("could not delete files from cache"))
        }
    }

    func directoryFor(stringUrl: String) -> URL {
        let fileComponents = URL(string: stringUrl)!.lastPathComponent.components(separatedBy: ".")
        let fileURL = "\(fileComponents[0])-cached.\(fileComponents[1])"
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

    /// Basic validation to ensure cached WebM files are not corrupted.
    func isValidWebm(file: URL) -> Bool {
        return isValidVideoFile(file: file)
    }

    /// Validate video files (WebM and MP4)
    func isValidVideoFile(file: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: file) else { return false }
        defer { handle.closeFile() }

        let header = handle.readData(ofLength: 8)
        let bytes = [UInt8](header)

        guard bytes.count >= 4 else { return false }

        // Check WebM (EBML header 0x1A45DFA3)
        if bytes.count >= 4 && bytes[0] == 0x1A && bytes[1] == 0x45 && bytes[2] == 0xDF && bytes[3] == 0xA3 {
            return true
        }

        // Check MP4 (ftyp box at offset 4)
        if bytes.count >= 8 && bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70 {
            return true
        }

        // Also check for basic file size (non-empty)
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            return fileSize > 0
        } catch {
            return false
        }
    }

}
