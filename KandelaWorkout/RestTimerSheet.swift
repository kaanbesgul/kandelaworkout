import SwiftUI

struct RestTimerSheet: View {
    @Environment(RestTimerService.self) private var restTimer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Spacer(minLength: 0)

                if restTimer.isActive {
                    countdownView
                } else {
                    presetPicker
                }

                Spacer(minLength: 0)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dinlenme Sayacı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    // MARK: - Preset picker

    private var presetPicker: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.13))
                    .frame(width: 110, height: 110)
                Image(systemName: "timer")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Color.accentColor.gradient)
            }

            VStack(spacing: 4) {
                Text("Bir dinlenme süresi seç")
                    .font(.headline)
                Text("Süre bitince titreşim ve ses ile haber verir.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 16) {
                presetButton(minutes: 1)
                presetButton(minutes: 3)
                presetButton(minutes: 5)
            }
        }
    }

    private func presetButton(minutes: Int) -> some View {
        Button {
            restTimer.start(minutes: minutes)
        } label: {
            VStack(spacing: 2) {
                Text("\(minutes)")
                    .font(.title.weight(.heavy))
                Text("dakika")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(width: 84, height: 84)
            .background(Circle().fill(Color.accentColor.gradient))
            .shadow(color: Color.accentColor.opacity(0.35), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Countdown

    private var countdownView: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .stroke(Color(.tertiarySystemFill), lineWidth: 14)

                Circle()
                    .trim(from: 0, to: restTimer.progress)
                    .stroke(
                        (restTimer.isFinished ? Color.green : Color.accentColor).gradient,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: restTimer.progress)

                VStack(spacing: 6) {
                    Text(restTimer.isFinished ? "0:00" : restTimer.formattedRemaining)
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .monospacedDigit()

                    Text(statusText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(restTimer.isFinished ? .green : .secondary)
                }
            }
            .frame(width: 220, height: 220)

            if restTimer.isFinished {
                Button {
                    restTimer.cancel()
                    dismiss()
                } label: {
                    Text("Tamam")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.green.gradient))
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 14) {
                    Button {
                        restTimer.cancel()
                    } label: {
                        Label("İptal", systemImage: "xmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(.tertiarySystemFill)))
                    }
                    .buttonStyle(.plain)

                    Button {
                        if restTimer.isRunning {
                            restTimer.pause()
                        } else {
                            restTimer.resume()
                        }
                    } label: {
                        Label(
                            restTimer.isRunning ? "Duraklat" : "Devam Et",
                            systemImage: restTimer.isRunning ? "pause.fill" : "play.fill"
                        )
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.accentColor.gradient))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var statusText: String {
        if restTimer.isFinished { return "Süre doldu! 🎉" }
        return restTimer.isRunning ? "Dinleniyor…" : "Duraklatıldı"
    }
}

#Preview {
    RestTimerSheet()
        .environment(RestTimerService())
}
