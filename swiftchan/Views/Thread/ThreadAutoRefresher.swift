import SwiftUI
import Combine
import Defaults

class ThreadAutoRefresher: ObservableObject {
    @Published private var autoRefreshTimer: Double = 0
    @Published private(set) var timer: Publishers.Autoconnect<Timer.TimerPublisher>
    @Published private var pauseAutoRefresh: Bool = false

    init() {
        timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
    }

    func setTimer() {
        timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
    }

    func cancelTimer() {
        timer.upstream.connect().cancel()
    }

    // Returns true if hit reset limit
    func incrementRefreshTimer() -> Bool {
        guard !pauseAutoRefresh, Defaults[.autoRefreshEnabled] else { return false }
        withAnimation {
            autoRefreshTimer += Int(autoRefreshTimer) >= Defaults[.autoRefreshThreadTime] ? Double(-Defaults[.autoRefreshThreadTime]) : 1
        }
        if autoRefreshTimer == .zero {
            return true
        }
        return false
    }
}
