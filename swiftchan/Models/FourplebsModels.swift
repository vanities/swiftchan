//
//  FourplebsModels.swift
//  swiftchan
//
//  Models for parsing 4plebs archive API responses.
//  API docs: https://4plebs.org/docs/foolfuuka/
//

import Foundation
import FourChan

/// Root response from 4plebs thread endpoint
/// Example: https://archive.4plebs.org/_/api/chan/thread/?board=pol&num=123456
struct FourplebsThreadResponse: Codable {
    let error: String?

    // The response structure uses the thread number as a dynamic key
    // We need custom decoding to handle this
    var thread: FourplebsThread?

    enum CodingKeys: String, CodingKey {
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        error = try container.decodeIfPresent(String.self, forKey: .error)

        // Try to decode the thread data from dynamic keys
        let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
        for key in dynamicContainer.allKeys {
            // Skip known keys
            if key.stringValue == "error" { continue }

            // Try to decode as thread
            if let threadData = try? dynamicContainer.decode(FourplebsThread.self, forKey: key) {
                thread = threadData
                break
            }
        }
    }
}

/// Dynamic coding key for parsing arbitrary JSON keys
struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

/// Thread data from 4plebs containing OP and replies
struct FourplebsThread: Codable {
    let op: FourplebsPost?
    let posts: [String: FourplebsPost]?

    /// Convert to array of Post objects sorted by post number
    func toPosts(board: String) -> [Post] {
        var result: [Post] = []

        // Add OP first
        if let op = op {
            if let post = op.toPost(board: board) {
                result.append(post)
            }
        }

        // Add replies sorted by post number
        if let posts = posts {
            let sortedPosts = posts.values
                .compactMap { $0.toPost(board: board) }
                .sorted { $0.no < $1.no }
            result.append(contentsOf: sortedPosts)
        }

        return result
    }
}

/// Individual post from 4plebs archive
struct FourplebsPost: Codable {
    let num: Int?
    let subnum: Int?
    let threadNum: Int?
    let op: Int?
    let timestamp: Int?
    let timestampExpired: Int?
    let capcode: String?
    let name: String?
    let trip: String?
    let title: String?
    let comment: String?
    let posterHash: String?
    let posterCountry: String?
    let sticky: Int?
    let locked: Int?

    let media: FourplebsMedia?

    enum CodingKeys: String, CodingKey {
        case num, subnum, op, timestamp, capcode, name, trip, title, comment, sticky, locked, media
        case threadNum = "thread_num"
        case timestampExpired = "timestamp_expired"
        case posterHash = "poster_hash"
        case posterCountry = "poster_country"
    }

    /// Convert to FourChan.Post for compatibility with existing views
    func toPost(board: String) -> Post? {
        var postDict = buildBasePostDict()
        addOptionalFields(to: &postDict)
        addMediaFields(to: &postDict)
        return decodePost(from: postDict)
    }

    private func buildBasePostDict() -> [String: Any] {
        return [
            "no": num ?? 0,
            "resto": threadNum ?? 0,
            "time": timestamp ?? 0
        ]
    }

    private func addOptionalFields(to postDict: inout [String: Any]) {
        if let name = name { postDict["name"] = name }
        if let trip = trip { postDict["trip"] = trip }
        if let title = title, !title.isEmpty { postDict["sub"] = title }
        if let comment = comment { postDict["com"] = comment }
        if let capcode = capcode, !capcode.isEmpty, capcode != "N" { postDict["capcode"] = capcode }
        if let hash = posterHash, !hash.isEmpty, hash != "null" { postDict["id"] = hash }
        if let country = posterCountry { postDict["country"] = country }
        if sticky == 1 { postDict["sticky"] = 1 }
        if locked == 1 { postDict["closed"] = 1 }
    }

    private func addMediaFields(to postDict: inout [String: Any]) {
        guard let media = media, media.mediaFilename != nil else { return }

        addMediaId(from: media, to: &postDict)
        addFilenameAndExt(from: media, to: &postDict)
        addMediaDimensions(from: media, to: &postDict)
    }

    private func addMediaId(from media: FourplebsMedia, to postDict: inout [String: Any]) {
        if let mediaId = media.mediaId {
            postDict["tim"] = mediaId
        } else if let mediaOrig = media.mediaOrig {
            let components = mediaOrig.components(separatedBy: ".")
            if let first = components.first, let tim = Int(first) {
                postDict["tim"] = tim
            }
        }
    }

    private func addFilenameAndExt(from media: FourplebsMedia, to postDict: inout [String: Any]) {
        guard let filename = media.mediaFilename else { return }
        let components = filename.components(separatedBy: ".")
        if components.count >= 2 {
            postDict["filename"] = components.dropLast().joined(separator: ".")
            postDict["ext"] = "." + (components.last ?? "jpg")
        } else {
            postDict["filename"] = filename
            postDict["ext"] = ".jpg"
        }
    }

    private func addMediaDimensions(from media: FourplebsMedia, to postDict: inout [String: Any]) {
        if let w = media.mediaW { postDict["w"] = w }
        if let h = media.mediaH { postDict["h"] = h }
        if let fsize = media.mediaSize { postDict["fsize"] = fsize }
        if let tnW = media.previewW { postDict["tn_w"] = tnW }
        if let tnH = media.previewH { postDict["tn_h"] = tnH }
        if media.spoiler == 1 { postDict["spoiler"] = 1 }
    }

    private func decodePost(from postDict: [String: Any]) -> Post? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: postDict)
            return try JSONDecoder().decode(Post.self, from: jsonData)
        } catch {
            print("Failed to convert 4plebs post to Post: \(error)")
            return nil
        }
    }
}

/// Media information from 4plebs
struct FourplebsMedia: Codable {
    let mediaId: Int?
    let spoiler: Int?
    let previewOrig: String?
    let mediaOrig: String?
    let media: String?
    let mediaFilename: String?
    let mediaW: Int?
    let mediaH: Int?
    let mediaSize: Int?
    let previewW: Int?
    let previewH: Int?
    let exif: String?
    let banned: Int?

    enum CodingKeys: String, CodingKey {
        case spoiler, media, exif, banned
        case mediaId = "media_id"
        case previewOrig = "preview_orig"
        case mediaOrig = "media_orig"
        case mediaFilename = "media_filename"
        case mediaW = "media_w"
        case mediaH = "media_h"
        case mediaSize = "media_size"
        case previewW = "preview_w"
        case previewH = "preview_h"
    }
}
