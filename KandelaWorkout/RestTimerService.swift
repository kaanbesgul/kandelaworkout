import Foundation
import Observation
import UIKit
import AudioToolbox

@Observable
final class RestTimerService {
    private(set) var totalSeconds: Int = 0
    private(set) var remainingSeconds: Int = 0
    private(set) var isRunning: Bool = false
    private(set) var isFinished: Bool = false

    private var endDate: Date?
    private var pausedRemaining: Int = 0
    private var timer: Timer?

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let totalSeconds = "restTimer.totalSeconds"
        static let isRunning = "restTimer.isRunning"
        static let pausedRemaining = "restTimer.pausedRemaining"
        static let endDate = "restTimer.endDate"
    }

    init() {
        restore()
    }

    var isActive: Bool { totalSeconds > 0 }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var formattedRemaining: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func start(minutes: Int) {
        totalSeconds = minutes * 60
        endDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
        pausedRemaining = 0
        isFinished = false
        isRunning = true
        refresh()
        persist()
        scheduleTimer()
    }

    func pause() {
        guard isRunning else { return }
        refresh()
        pausedRemaining = remainingSeconds
        endDate = nil
        isRunning = false
        invalidateTimer()
        persist()
    }

    func resume() {
        guard !isRunning, pausedRemaining > 0 else { return }
        endDate = Date().addingTimeInterval(TimeInterval(pausedRemaining))
        isRunning = true
        refresh()
        persist()
        scheduleTimer()
    }

    func cancel() {
        invalidateTimer()
        isRunning = false
        isFinished = false
        totalSeconds = 0
        remainingSeconds = 0
        endDate = nil
        pausedRemaining = 0
        clearPersisted()
    }

    /// Recomputes the remaining time from the stored end date. Safe to call anytime
    /// (e.g. when the app returns to the foreground) to correct any drift caused by
    /// the app being backgrounded, since the countdown is anchored to a wall-clock
    /// end date rather than a manually decremented counter.
    func refresh() {
        guard isRunning, let endDate else { return }
        let remaining = max(0, Int(endDate.timeIntervalSinceNow.rounded()))
        remainingSeconds = remaining
        if remaining <= 0 {
            finish()
        }
    }

    private func scheduleTimer() {
        invalidateTimer()
        let newTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func finish() {
        invalidateTimer()
        isRunning = false
        isFinished = true
        endDate = nil
        pausedRemaining = 0
        remainingSeconds = 0
        persist()

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(SystemSoundID(1005))
    }

    // MARK: - Persistence

    private func persist() {
        guard totalSeconds > 0 else {
            clearPersisted()
            return
        }
        defaults.set(totalSeconds, forKey: Keys.totalSeconds)
        defaults.set(isRunning, forKey: Keys.isRunning)
        defaults.set(pausedRemaining, forKey: Keys.pausedRemaining)
        if let endDate {
            defaults.set(endDate.timeIntervalSince1970, forKey: Keys.endDate)
        } else {
            defaults.removeObject(forKey: Keys.endDate)
        }
    }

    private func clearPersisted() {
        defaults.removeObject(forKey: Keys.totalSeconds)
        defaults.removeObject(forKey: Keys.isRunning)
        defaults.removeObject(forKey: Keys.pausedRemaining)
        defaults.removeObject(forKey: Keys.endDate)
    }

    private func restore() {
        let total = defaults.integer(forKey: Keys.totalSeconds)
        guard total > 0 else { return }

        totalSeconds = total
        let wasRunning = defaults.bool(forKey: Keys.isRunning)
        pausedRemaining = defaults.integer(forKey: Keys.pausedRemaining)

        if wasRunning, defaults.object(forKey: Keys.endDate) != nil {
            let savedEndDate = Date(timeIntervalSince1970: defaults.double(forKey: Keys.endDate))
            if savedEndDate > Date() {
                endDate = savedEndDate
                isRunning = true
                refresh()
                scheduleTimer()
            } else {
                // The rest period finished while the app was closed/backgrounded.
                remainingSeconds = 0
                isFinished = true
            }
        } else {
            remainingSeconds = pausedRemaining
        }
    }
}
