import SwiftUI
import Combine

@Observable
class ThreadAutoRefresher {
    private(set) var autoRefreshTimer: Double = 0
    var pauseAutoRefresh: Bool = false
    var isActive: Bool = true
    
    private var timerCancellable: AnyCancellable?

    init() {
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
        guard isActive else { return }
        Task { @MainActor in
            _ = self.incrementRefreshTimer()
        }
    }

    var onRefresh: (() -> Void)?
    
    // Returns true if hit reset limit
    @MainActor
    func incrementRefreshTimer() -> Bool {
        guard !pauseAutoRefresh, UserDefaults.getAutoRefreshEnabled() else { return false }
        
        autoRefreshTimer += 1
        
        // Get refresh time with validation - minimum 5 seconds, default 10
        let refreshTime = max(5, UserDefaults.getAutoRefreshThreadTime() > 0 ? UserDefaults.getAutoRefreshThreadTime() : 10)
        
        if autoRefreshTimer >= Double(refreshTime) {
            autoRefreshTimer = 0
            onRefresh?()
            return true
        }
        return false
    }
    
    func resetTimer() {
        autoRefreshTimer = 0
    }
}
