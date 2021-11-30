//
//  DownloadQueue.swift
//  swiftchan
//
//  Created by vanities on 5/3/21.
//

import Foundation

class VideoPrefetcher {
    let queue = OperationQueue()

    init() {
        queue.maxConcurrentOperationCount = 1
        queue.underlyingQueue = .main
    }
}
