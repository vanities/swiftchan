//
//  GIFPlayerUiView.swift
//  swiftchan
//
//  Created by vanities on 11/22/20.
//

import UIKit

class GIFPlayerView: UIView {
    let imageView = UIImageView()

    convenience init(url: URL) {
       self.init()
        CacheManager.shared.getFileWith(stringUrl: url.absoluteString) { [weak self] result in
            switch result {
            case .success(let cachedUrl):
                DispatchQueue.main.async {
                let gif = UIImage.gif(url: cachedUrl.absoluteString)
                self?.imageView.image = gif
                self?.imageView.contentMode = .scaleAspectFit
                    if let view = self?.imageView {
                        self?.addSubview(view)

                    }
                }
            case .failure(let error):
                print(error, " failure in the Cache of video")
            }
        }

    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
}
