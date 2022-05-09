//
//  MediaView.swift
//  swiftchan
//
//  Created by vanities on 11/11/20.
//

import Foundation
import SwiftUI
import Kingfisher

struct MediaView: View {
    let media: Media
    @State var playWebm: Bool = false

    var onMediaChanged: ((Bool) -> Void)?

    @ViewBuilder
    var body: some View {
        switch media.format {
        case .image:
            ImageView(url: media.url)
                .onZoomChanged { zoomed in
                    onMediaChanged?(zoomed)
                }
                .mediaDownloadMenu(url: media.url)
        case .webm:
            ZStack {
                ImageView(
                    url: media.thumbnailUrl,
                    canGesture: false
                )

                VLCContainerView(
                    url: media.url,
                    play: $playWebm
                )
                .onChange(of: media.isSelected) { selected in
                    playWebm = selected
                }
                .onAppear {
                    playWebm = media.isSelected
                }
            }
        case .gif:
            KFAnimatedImage(media.url)
                .configure { _ in
                    // read current/max here or progress view
                    //view.animator?.currentFrameIndex

                }
                .mediaDownloadMenu(url: media.url)
                .scaledToFit()
        case .none:
            EmptyView()
        }
    }
}

extension MediaView: Buildable {
    func onMediaChanged(_ callback: ((Bool) -> Void)?) -> Self {
        mutating(keyPath: \.onMediaChanged, value: callback)
    }
}

#if DEBUG
struct MediaView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ThreadView.ViewModel(boardName: "pol", id: 0)
        let urls = [
                URLExamples.image,
                URLExamples.gif,
                URLExamples.webm
            ]
        viewModel.setMedia(mediaUrls: urls, thumbnailMediaUrls: urls)

        return Group {
            MediaView(
                media: viewModel.media[0]
            )
            MediaView(
                media: viewModel.media[1]
            )
            MediaView(
                media: viewModel.media[2]
            )
        }
    }
}
#endif

extension URLSession {
    func download(from url: URL, delegate: URLSessionTaskDelegate? = nil, progress parent: Progress) async throws -> (URL, URLResponse) {
        try await download(for: URLRequest(url: url), progress: parent)
    }

    func download(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil, progress parent: Progress) async throws -> (URL, URLResponse) {
        let progress = Progress()
        parent.addChild(progress, withPendingUnitCount: 1)

        let bufferSize = 65_536
        let estimatedSize: Int64 = 1_000_000

        let (asyncBytes, response) = try await bytes(for: request, delegate: delegate)
        let expectedLength = response.expectedContentLength                             // note, if server cannot provide expectedContentLength, this will be -1
        progress.totalUnitCount = expectedLength > 0 ? expectedLength : estimatedSize

        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        guard let output = OutputStream(url: fileURL, append: false) else {
            throw URLError(.cannotOpenFile)
        }
        output.open()

        var buffer = Data()
        if expectedLength > 0 {
            buffer.reserveCapacity(min(bufferSize, Int(expectedLength)))
        } else {
            buffer.reserveCapacity(bufferSize)
        }

        var count: Int64 = 0
        for try await byte in asyncBytes {
            try Task.checkCancellation()

            count += 1
            buffer.append(byte)

            if buffer.count >= bufferSize {
                try output.write(buffer)
                buffer.removeAll(keepingCapacity: true)

                if expectedLength < 0 || count > expectedLength {
                    progress.totalUnitCount = count + estimatedSize
                }
                progress.completedUnitCount = count
            }
        }

        if !buffer.isEmpty {
            try output.write(buffer)
        }

        output.close()

        progress.totalUnitCount = count
        progress.completedUnitCount = count

        return (fileURL, response)
    }
}

extension OutputStream {

    /// Write `Data` to `OutputStream`
    ///
    /// - parameter data:                  The `Data` to write.

    func write(_ data: Data) throws {
        try data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) throws in
            guard var pointer = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return
            }

            var bytesRemaining = buffer.count

            while bytesRemaining > 0 {
                let bytesWritten = write(pointer, maxLength: bytesRemaining)
                if bytesWritten < 0 {
                    return
                }

                bytesRemaining -= bytesWritten
                pointer += bytesWritten
            }
        }
    }
}
