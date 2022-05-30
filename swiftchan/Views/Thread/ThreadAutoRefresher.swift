import SwiftUI
import Combine
import Defaults

class ThreadAutoRefresher: ObservableObject {
    private(set) var autoRefreshTimer: Double = 0
    private(set) var timer: Publishers.Autoconnect<Timer.TimerPublisher>
    @Published var pauseAutoRefresh: Bool = false

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
    func incrementRefreshTimer() -> Bool {
        guard !pauseAutoRefresh, Defaults[.autoRefreshEnabled] else { return false }
        withAnimation {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.autoRefreshTimer += Int(strongSelf.autoRefreshTimer) >= Defaults[.autoRefreshThreadTime] ? Double(-Defaults[.autoRefreshThreadTime]) : 1
            }
        }
        if autoRefreshTimer == .zero {
            return true
        }
        return false
    }
}
