//
//  FileExport.swift
//  swiftchan
//
//  Created on 12/8/20.
//

import SwiftUI
import UniformTypeIdentifiers

struct FileExport: FileDocument {

    let url: String

    static let readableContentTypes = [UTType.video, UTType.movie, UTType.image]
    static let writableContentTypes = [UTType.video, UTType.movie, UTType.image]

    init(url: String) {
        self.url = url
    }

    init(configuration: ReadConfiguration) throws {
        self.url = ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        do {
            let url = CacheManager().directoryFor(stringUrl: self.url)
            return try FileWrapper(url: url.absoluteURL, options: .immediate)
        } catch {
            return FileWrapper()
        }
    }
}
