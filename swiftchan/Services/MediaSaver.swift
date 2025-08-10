//
//  MediaSaver.swift
//  swiftchan
//
//  Created on 12/8/20.
//

import SwiftUI
import Photos

class ImageSaver {
    static func saveImageToPhotoAlbum(url: URL, complete: @escaping ((Result<Void, Error>) -> Void)) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = try? Data(contentsOf: url) else { return }
            PHPhotoLibrary.shared().performChanges({
                PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: nil)
            }, completionHandler: { _, error in
                if let error = error {
                    complete(.failure(error))
                }
                complete(.success(()))
            })
        }
    }
}
