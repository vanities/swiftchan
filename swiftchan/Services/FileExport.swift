//
//  FileExport.swift
//  swiftchan
//
//  Created by vanities on 12/8/20.
//

import SwiftUI
import UniformTypeIdentifiers

struct FileExport: FileDocument {

    let url: String

    static var readableContentTypes = [UTType.video, UTType.movie, UTType.image]
    static var writableContentTypes = [UTType.video, UTType.movie, UTType.image]

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
