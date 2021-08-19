//
//  MediaSaver.swift
//  swiftchan
//
//  Created by vanities on 12/8/20.
//

import SwiftUI

class ImageSaver: NSObject {
    var successHandler: (() -> Void)?
    var errorHandler: ((Error) -> Void)?
    var completionHandler: ((Result<Void, Error>) -> Void)?

    init(completionHandler: ((Result<Void, Error>) -> Void)?) {
        self.completionHandler = completionHandler
    }

    func saveImageToPhotos(url: URL) {
        self.loadImage(url: url) { image in
            if let image = image {
                self.saveImageToPhotoAlbum(image: image)
            }
        }

    }

    // images
    func saveImageToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError), nil)
    }

    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            completionHandler?(.failure(error))
        } else {
            completionHandler?(.success(()))
        }
    }

    func loadImage(url: URL, complete: @escaping (UIImage?) -> Void) {
        if let data = try? Data(contentsOf: url) {
            if let image = UIImage(data: data) {
                complete(image)
            } else {
                debugPrint("Unable to save data to photo album")
                complete(nil)
            }
        } else {
            debugPrint("Unable to save data to photo album")
            complete(nil)
        }
    }
}
