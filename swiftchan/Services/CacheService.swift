//
//  CacheService.swift
//  swiftchan
//
//  Created on 11/7/20.
//

import Foundation
import Kingfisher

// MARK: - Cache Metadata

struct CacheMetadata: Codable {
    let url: String
    let filePath: String
    let fileSize: Int64
    var lastAccessTime: Date
    let createdTime: Date

    init(url: String, filePath: String, fileSize: Int64) {
        self.url = url
        self.filePath = filePath
        self.fileSize = fileSize
        let now = Date()
        self.lastAccessTime = now
        self.createdTime = now
    }
}

// MARK: - Cache Manager

// @MainActor
final class CacheManager: @unchecked Sendable {

    static let shared = CacheManager()
    private let fileManager = FileManager.default
    private lazy var mainDirectoryUrl: URL = {
        let documentsUrl = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return documentsUrl
    }()

    // LRU cache management
    private var metadata: [String: CacheMetadata] = [:]
    private let metadataFileName = "swiftchan-cache-metadata.json"
    private let maxCacheSize: Int64 = 1_073_741_824 // 1 GB in bytes
    private let queue = DispatchQueue(label: "com.swiftchan.cachemanager", attributes: .concurrent)

    private var metadataFileURL: URL {
        mainDirectoryUrl.appendingPathComponent(metadataFileName)
    }

    init() {
        loadMetadata()
    }

    // MARK: - LRU Cache Management

    private func loadMetadata() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            do {
                let data = try Data(contentsOf: self.metadataFileURL)
                let decoded = try JSONDecoder().decode([String: CacheMetadata].self, from: data)
                self.metadata = decoded
                debugPrint("Loaded \(decoded.count) cache metadata entries")
            } catch {
                debugPrint("No existing cache metadata or failed to load: \(error)")
                self.metadata = [:]
            }
        }
    }

    private func saveMetadata() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            do {
                let data = try JSONEncoder().encode(self.metadata)
                try data.write(to: self.metadataFileURL)
            } catch {
                debugPrint("Failed to save cache metadata: \(error)")
            }
        }
    }

    func getCurrentCacheSize() -> Int64 {
        var totalSize: Int64 = 0
        queue.sync {
            totalSize = metadata.values.reduce(0) { $0 + $1.fileSize }
        }
        return totalSize
    }

    private func evictLRUIfNeeded(targetSize: Int64) {
        evictLRUIfNeededSync(targetSize: targetSize, excludingURL: nil)
    }

    /// Synchronous version that excludes a specific URL from eviction candidates
    /// This prevents race conditions where a file being cached could be evicted
    private func evictLRUIfNeededSync(targetSize: Int64, excludingURL: String?) {
        queue.sync(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            // First, remove any stale metadata for the URL we're about to cache
            // This prevents the new file from being immediately evicted
            if let excludingURL = excludingURL {
                self.metadata.removeValue(forKey: excludingURL)
            }

            var currentSize = self.metadata.values.reduce(0) { $0 + $1.fileSize }
            let sizeAfterAdd = currentSize + targetSize

            // Only evict if we'll exceed the limit
            guard sizeAfterAdd > self.maxCacheSize else { return }

            let sizeToFree = sizeAfterAdd - self.maxCacheSize
            debugPrint("📦 Cache will exceed limit. Current: \(currentSize / 1_048_576)MB, Need to free: \(sizeToFree / 1_048_576)MB")

            // Sort by lastAccessTime (oldest first)
            let sortedEntries = self.metadata.values.sorted { $0.lastAccessTime < $1.lastAccessTime }

            var freedSize: Int64 = 0
            for entry in sortedEntries {
                guard freedSize < sizeToFree else { break }

                let fileURL = URL(fileURLWithPath: entry.filePath)
                do {
                    try self.fileManager.removeItem(at: fileURL)
                    freedSize += entry.fileSize
                    self.metadata.removeValue(forKey: entry.url)
                    debugPrint("🗑️ Evicted: \(fileURL.lastPathComponent) (\(entry.fileSize / 1_048_576)MB)")
                } catch {
                    debugPrint("Failed to evict \(fileURL.path): \(error)")
                }
            }

            debugPrint("📦 Eviction complete. Freed: \(freedSize / 1_048_576)MB, New size: \((currentSize - freedSize) / 1_048_576)MB")
            self.saveMetadataUnsafe()
        }
    }

    private func updateAccessTime(for url: String) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            if var entry = self.metadata[url] {
                entry.lastAccessTime = Date()
                self.metadata[url] = entry
                // Don't save on every access - too expensive. Save periodically or on important events
            }
        }
    }

    private func addMetadata(url: String, filePath: String, fileSize: Int64) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let entry = CacheMetadata(url: url, filePath: filePath, fileSize: fileSize)
            self.metadata[url] = entry
            debugPrint("📝 Added cache metadata for \(url)")
            self.saveMetadataUnsafe()
        }
    }

    /// Synchronous version for use during cache operations
    private func addMetadataSync(url: String, filePath: String, fileSize: Int64) {
        queue.sync(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let entry = CacheMetadata(url: url, filePath: filePath, fileSize: fileSize)
            self.metadata[url] = entry
            debugPrint("📝 Added cache metadata for \(url)")
            self.saveMetadataUnsafe()
        }
    }

    /// Save metadata without queue synchronization (call from within queue.sync/async)
    private func saveMetadataUnsafe() {
        do {
            let data = try JSONEncoder().encode(metadata)
            try data.write(to: metadataFileURL)
        } catch {
            debugPrint("Failed to save cache metadata: \(error)")
        }
    }

    // MARK: - Cache Operations

    func getFileWith(stringUrl: String, completionHandler: @escaping @Sendable (URL?) -> Void ) {
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
            updateAccessTime(for: url.absoluteString)
            return cacheUrl
        }
        return nil
    }

    func cacheURL(_ url: URL) -> URL {
        return directoryFor(stringUrl: url.absoluteString)
    }

    func cache(_ tempURL: URL, _ cacheURL: URL, originalURL: URL? = nil) -> URL? {
        do {
            // Get file size before moving
            let attributes = try fileManager.attributesOfItem(atPath: tempURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0

            let metadataKey = originalURL?.absoluteString ?? cacheURL.absoluteString

            // Run LRU eviction synchronously before moving the file,
            // excluding the URL we're about to cache to prevent race condition
            evictLRUIfNeededSync(targetSize: fileSize, excludingURL: metadataKey)

            try? fileManager.removeItem(at: cacheURL)
            try fileManager.moveItem(at: tempURL, to: cacheURL)

            // Add metadata for LRU tracking using cacheURL as key (consistent with getCacheValue)
            addMetadataSync(url: metadataKey, filePath: cacheURL.path, fileSize: fileSize)

            debugPrint("completed writing file to cache \(cacheURL.path) (\(fileSize / 1_048_576)MB)")
            return cacheURL
        } catch {
            debugPrint("failed writing file to cache \(cacheURL.path): \(error)")
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
