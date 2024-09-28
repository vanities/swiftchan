import SwiftUI
import Combine

@Observable
class ThreadAutoRefresher {
    // TODO: fix this from redrawing the whole posts in ThreadView, make this Published
    private(set) var autoRefreshTimer: Double = 0
    private(set) var timer: Publishers.Autoconnect<Timer.TimerPublisher>
    var pauseAutoRefresh: Bool = false

    init() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }

    func setTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }

    func cancelTimer() {
        timer.upstream.connect().cancel()
    }

    // Returns true if hit reset limit
    @MainActor
    func incrementRefreshTimer() -> Bool {
        guard !pauseAutoRefresh, UserDefaults.getAutoRefreshEnabled() else { return false }
        withAnimation(.linear(duration: 1)) {
            autoRefreshTimer += Int(autoRefreshTimer) >= UserDefaults.getAutoRefreshThreadTime() ? Double(-UserDefaults.getAutoRefreshThreadTime()) : 1
        }
        if autoRefreshTimer == .zero {
            return true
        }
        return false
    }
}
