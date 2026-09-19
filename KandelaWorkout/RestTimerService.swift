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

    private var timer: Timer?

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
        invalidateTimer()
        totalSeconds = minutes * 60
        remainingSeconds = totalSeconds
        isFinished = false
        isRunning = true
        scheduleTimer()
    }

    func pause() {
        isRunning = false
        invalidateTimer()
    }

    func resume() {
        guard remainingSeconds > 0 else { return }
        isRunning = true
        scheduleTimer()
    }

    func cancel() {
        invalidateTimer()
        isRunning = false
        isFinished = false
        totalSeconds = 0
        remainingSeconds = 0
    }

    private func scheduleTimer() {
        invalidateTimer()
        let newTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard remainingSeconds > 0 else { return }
        remainingSeconds -= 1
        if remainingSeconds == 0 {
            finish()
        }
    }

    private func finish() {
        invalidateTimer()
        isRunning = false
        isFinished = true

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(SystemSoundID(1005))
    }
}
