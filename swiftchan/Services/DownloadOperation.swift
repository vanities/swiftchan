//
//  DownloadOperation.swift
//  swiftchan
//
//  Created on 5/9/21.
//
// https://fluffy.es/download-files-sequentially/

import Foundation

class DownloadOperation: Operation, @unchecked Sendable {
    private(set) var task: URLSessionDownloadTask!
    let downloadTaskURL: URL

    private let stateLock = NSRecursiveLock()

    enum OperationState: Int {
        case ready
        case executing
        case finished
    }

    private var _state: OperationState = .ready

    private var state: OperationState {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return _state
        }
        set {
            stateLock.lock()
            willChangeValue(forKey: "isExecuting")
            willChangeValue(forKey: "isFinished")
            _state = newValue
            didChangeValue(forKey: "isExecuting")
            didChangeValue(forKey: "isFinished")
            stateLock.unlock()
        }
    }

    override var isReady: Bool { return state == .ready }
    override var isExecuting: Bool { return state == .executing }
    override var isFinished: Bool { return state == .finished }

    init(session: URLSession, downloadTaskURL: URL, completionHandler: (@Sendable (URL?, URLResponse?, Error?) -> Void)?) {
        self.downloadTaskURL = downloadTaskURL
        super.init()

        task = session.downloadTask(with: downloadTaskURL, completionHandler: { [weak self] (localURL, response, error) in
            completionHandler?(localURL, response, error)

            // Dispatch state change to main thread so KVO notifications
            // (observed by NSOperationQueue) don't race with addOperation/cancel on main.
            DispatchQueue.main.async {
                guard let self, self.isExecuting else { return }
                self.state = .finished
            }
        })
    }

    override func start() {
        if self.isCancelled {
            state = .finished
            return
        }

        state = .executing

        debugPrint("downloading \(task.originalRequest?.url?.absoluteString ?? "")")
        self.task.resume()
    }

    override func cancel() {
        super.cancel()

        // If the operation hasn't started yet, mark finished so the queue can clean it up.
        // If it's executing, the completion handler will handle the transition.
        if state == .ready {
            state = .finished
        }

        task.cancel()
    }
}
