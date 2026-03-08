import SwiftUI
import Combine

@Observable
class ThreadAutoRefresher {
    private(set) var secondsRemaining: Int = 0
    var pauseAutoRefresh: Bool = false
    var isActive: Bool = true

    private var timerCancellable: AnyCancellable?
    private var cachedRefreshEnabled: Bool = false
    private var cachedRefreshTime: Int = 10

    var onRefresh: (() -> Void)?

    init() {
        updateCachedSettings()
        resetTimer()
        startTimer()
    }

    deinit {
        cancelTimer()
    }

    func updateCachedSettings() {
        cachedRefreshEnabled = UserDefaults.getAutoRefreshEnabled()
        cachedRefreshTime = max(5, UserDefaults.getAutoRefreshThreadTime() > 0 ? UserDefaults.getAutoRefreshThreadTime() : 10)
    }

    func startTimer() {
        cancelTimer()
        isActive = true
        updateCachedSettings()
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
        guard isActive, !pauseAutoRefresh, cachedRefreshEnabled else { return }

        secondsRemaining -= 1

        if secondsRemaining <= 0 {
            resetTimer()
            onRefresh?()
        }
    }

    func resetTimer() {
        secondsRemaining = cachedRefreshTime
    }

    var progress: Double {
        Double(secondsRemaining) / Double(cachedRefreshTime)
    }
}
