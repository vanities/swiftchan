//
//  VLCThumnailView.swift
//  swiftchan
//
//  Created by vanities on 11/6/20.
//

import AVFoundation
import SwiftUI
import MobileVLCKit

/*
class VLCThumbnailUIView: UIView, VLCMediaThumbnailerDelegate {
    func mediaThumbnailerDidTimeOut(_ mediaThumbnailer: VLCMediaThumbnailer!) {
        return
    }
    
    func mediaThumbnailer(_ mediaThumbnailer: VLCMediaThumbnailer!, didFinishThumbnail thumbnail: CGImage!) {
        self.delegate?.didGetThumbnail(thumbnail: thumbnail)
    }
    
    let thumbnailer: VLCMediaThumbnailer = VLCMediaThumbnailer()
    let url: URL
    var delegate: VLCThumbnailUIViewDelegate?
    
    init(url: URL) {
        self.url = url
        super.init(frame: .zero)
        self.thumbnailer.delegate = self
        self.setCachedThumbnail()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Private
    private func setThumbnail(cacheUrl: URL) {
        DispatchQueue.main.async {
            let media = VLCMedia(url: cacheUrl)
            self.thumbnailer.media = media
            self.thumbnailer.fetchThumbnail()
        }
    }
    private func setCachedThumbnail() {
        CacheManager.shared.getFileWith(stringUrl: self.url.absoluteString) { result in
            switch result {
            case .success(let url):
                self.setThumbnail(cacheUrl: url)
                break
            case .failure(let error):
                print(error, " failure in the Cache of video")
                break
            }
        }
    }
    
}
protocol VLCThumbnailUIViewDelegate: class {
    func didGetThumbnail(thumbnail: CGImage!)
}
 */

/*
struct VLCThumbnailView: UIViewRepresentable {
    let thumbnailer: VLCMediaThumbnailer = VLCMediaThumbnailer()
    let url: URL

    let thumbnail: (UIImage) -> Void

    func makeUIView(context: Context) -> UIView {
        let uiView = UIView()
        self.thumbnailer.delegate = context.coordinator
        print("make", url)

        //#if DEBUG
        self.setThumbnail(cacheUrl: url)
        //#else
        //self.setCachedThumbnail()
        //#endif

        return uiView
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<VLCThumbnailView>) {
        print("update", url)
        return
    }

    public static func dismantleUIView(_ uiView: UIView, coordinator: VLCThumbnailView.Coordinator) {
        //coordinator.parent.playerList.mediaList = nil
    }

    // MARK: Private
    private func setThumbnail(cacheUrl: URL) {
            let media = VLCMedia(url: cacheUrl)
            self.thumbnailer.media = media
            self.thumbnailer.fetchThumbnail()
            print("fetch", url)
    }

    private func setCachedThumbnail() {
        CacheManager.shared.getFileWith(stringUrl: self.url.absoluteString) { result in
            switch result {
            case .success(let url):
                self.setThumbnail(cacheUrl: url)
                break
            case .failure(let error):
                print(error, " failure in the Cache of video")
                break
            }
        }
    }

    // MARK: Coordinator
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, VLCMediaThumbnailerDelegate {
        var parent: VLCThumbnailView

        init(_ parent: VLCThumbnailView) {
            self.parent = parent
        }

        // MARK: Thumbnailer Delegate
        func mediaThumbnailerDidTimeOut(_ mediaThumbnailer: VLCMediaThumbnailer!) {
            return
        }

        func mediaThumbnailer(_ mediaThumbnailer: VLCMediaThumbnailer!, didFinishThumbnail thumbnail: CGImage!) {
            print("setting", self.parent.url)
            self.parent.thumbnail(UIImage(cgImage: thumbnail))
            print("set", self.parent.url)
        }
    }
}

struct VlcThumbnailViewDemo_Previews: PreviewProvider {
    static var previews: some View {
        var i: Image = Image(systemName: "play")
        return ZStack {
            VLCThumbnailView(url: URLExamples.webm) { t in
                i = Image(uiImage: t)
            }
            i
        }
    }
}
*/
class VLCThumbnailView: VLCMediaThumbnailerDelegate {
    let thumbnailer: VLCMediaThumbnailer = VLCMediaThumbnailer()
    let url: URL

    let thumbnail: (UIImage) -> Void
    
    
    init(url: URL, thumbnail: @escaping (UIImage) -> Void) {
        self.url = url
        self.thumbnail = thumbnail
        self.thumbnailer.delegate = self
        self.setThumbnail(cacheUrl: url)
    }

    // MARK: Private
    private func setThumbnail(cacheUrl: URL) {
            let media = VLCMedia(url: cacheUrl)
            self.thumbnailer.media = media
            self.thumbnailer.fetchThumbnail()
            print("fetch", url)
    }

    private func setCachedThumbnail() {
        CacheManager.shared.getFileWith(stringUrl: self.url.absoluteString) { result in
            switch result {
            case .success(let url):
                self.setThumbnail(cacheUrl: url)
                break
            case .failure(let error):
                print(error, " failure in the Cache of video")
                break
            }
        }
    }


        // MARK: Thumbnailer Delegate
        func mediaThumbnailerDidTimeOut(_ mediaThumbnailer: VLCMediaThumbnailer!) {
            return
        }

        func mediaThumbnailer(_ mediaThumbnailer: VLCMediaThumbnailer!, didFinishThumbnail thumbnail: CGImage!) {
            self.thumbnail(UIImage(cgImage: thumbnail))
        }
}

struct VlcThumbnailViewDemo_Previews: PreviewProvider {
    static var previews: some View {
        var i: Image = Image(systemName: "play")
        VLCThumbnailView(url: URLExamples.webm) { t in
            i = Image(uiImage: t)
        }
        return ZStack {
            i
        }
    }
}
