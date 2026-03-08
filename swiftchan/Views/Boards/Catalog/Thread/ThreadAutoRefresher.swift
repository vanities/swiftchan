import SwiftUI
import Combine

@Observable
class ThreadAutoRefresher {
    private(set) var secondsRemaining: Int = 0
    var pauseAutoRefresh: Bool = false
    var isActive: Bool = true

    private var timerCancellable: AnyCancellable?

    var onRefresh: (() -> Void)?

    init() {
        resetTimer()
        startTimer()
    }

    deinit {
        cancelTimer()
    }

    func startTimer() {
        cancelTimer()
        isActive = true
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.timerTick()
            }
    }

    func cancelTimer() {
        isActive = false
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func timerTick() {
        guard isActive, !pauseAutoRefresh, UserDefaults.getAutoRefreshEnabled() else { return }

        secondsRemaining -= 1

        if secondsRemaining <= 0 {
            resetTimer()
            onRefresh?()
        }
    }

    func resetTimer() {
        let refreshTime = max(5, UserDefaults.getAutoRefreshThreadTime() > 0 ? UserDefaults.getAutoRefreshThreadTime() : 10)
        secondsRemaining = refreshTime
    }

    /// Progress from 0.0 to 1.0 representing time remaining
    var progress: Double {
        let refreshTime = max(5, UserDefaults.getAutoRefreshThreadTime() > 0 ? UserDefaults.getAutoRefreshThreadTime() : 10)
        return Double(secondsRemaining) / Double(refreshTime)
    }
}
