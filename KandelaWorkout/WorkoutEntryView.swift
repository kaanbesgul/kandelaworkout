import SwiftUI
import SwiftData

struct WorkoutEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(RestTimerService.self) private var restTimer
    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse) private var templates: [WorkoutTemplate]
    @Query private var profiles: [UserProfile]

    @State private var exercises: [DraftExercise] = [DraftExercise()]
    @State private var selectedProgram: WorkoutProgram?
    @State private var didSave = false
    @State private var showTimerSheet = false
    @State private var isWorkoutActive = false
    @State private var sessionStartDate: Date?
    @State private var finishedDurationMinutes: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if restTimer.isActive {
                        timerBanner
                    }

                    workoutTimerCard

                    programSelector

                    VStack(alignment: .leading, spacing: 12) {
                        StepHeader(number: 2, title: "Hareketleri ekle")
                            .padding(.leading, 4)

                        if !templates.isEmpty {
                            templateSelector
                        }

                        ExercisesEditorSection(
                            exercises: $exercises,
                            selectedProgram: selectedProgram,
                            onSetAdded: startAutoRestTimerIfNeeded
                        )
                    }

                    saveButton
                        .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background)
            .navigationTitle("Antrenman")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showTimerSheet = true
                    } label: {
                        Image(systemName: restTimer.isActive ? "timer.circle.fill" : "timer")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(restTimer.isActive ? Color.accentColor : Color.primary)
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Bitti") {
                        hideKeyboard()
                    }
                    .font(.headline)
                }
            }
            .sheet(isPresented: $showTimerSheet) {
                RestTimerSheet()
            }
            .alert("Antrenman kaydedildi", isPresented: $didSave) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Geçmiş sekmesinden görüntüleyebilirsin.")
            }
        }
    }

    // MARK: - Workout timer

    private var workoutTimerCard: some View {
        Group {
            if isWorkoutActive, let start = sessionStartDate {
                TimelineView(.periodic(from: start, by: 1)) { context in
                    let elapsed = max(0, Int(context.date.timeIntervalSince(start)))

                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "stopwatch.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text(formattedElapsed(elapsed))
                                .font(.subheadline.weight(.bold))
                                .monospacedDigit()
                        }
                        .foregroundStyle(Color.accentColor)

                        Spacer(minLength: 0)

                        Button {
                            finishWorkout()
                        } label: {
                            Text("Antrenman Bitti")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(Capsule().fill(Color.red.gradient))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Theme.fill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Theme.fillStrong, lineWidth: 1)
                    )
                }
            } else {
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "stopwatch")
                            .font(.system(size: 12, weight: .bold))
                        Text(finishedDurationMinutes.map { "Süre: \($0) dk" } ?? "Antrenman süresi kaydedilmiyor")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)

                    Spacer(minLength: 0)

                    Button {
                        startWorkout()
                    } label: {
                        Label("Antrenmanı Başlat", systemImage: "play.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Capsule().fill(Color.accentColor.gradient))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.fill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Theme.fillStrong, lineWidth: 1)
                )
            }
        }
    }

    private func formattedElapsed(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func startWorkout() {
        sessionStartDate = .now
        isWorkoutActive = true
        finishedDurationMinutes = nil
    }

    private func finishWorkout() {
        guard let start = sessionStartDate else { return }
        finishedDurationMinutes = max(0, Int(Date().timeIntervalSince(start) / 60))
        isWorkoutActive = false
    }

    // MARK: - Rest timer

    private var timerBanner: some View {
        Button {
            showTimerSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: restTimer.isFinished ? "checkmark.circle.fill" : "timer")
                    .font(.system(size: 15, weight: .bold))

                Text(restTimer.isFinished ? "Süre doldu!" : "Dinleniyor")
                    .font(.subheadline.weight(.bold))

                Spacer(minLength: 8)

                Text(restTimer.isFinished ? "0:00" : restTimer.formattedRemaining)
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .opacity(0.7)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill((restTimer.isFinished ? Color.green : Color.accentColor).gradient)
                    .shadow(color: (restTimer.isFinished ? Color.green : Color.accentColor).opacity(0.35), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Templates

    private var templateSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bir şablondan başla")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 8) {
                ForEach(templates) { template in
                    templateChip(template)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.fill.opacity(0.5))
        )
    }

    private func templateChip(_ template: WorkoutTemplate) -> some View {
        let isActive = isTemplateActive(template)

        return Button {
            applyTemplate(template)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isActive ? "checkmark.circle.fill" : (template.program?.icon ?? "list.bullet.clipboard.fill"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isActive ? .white : Color.secondary)
                Text(template.name)
                    .font(.subheadline.weight(.semibold))
                Text("\(template.exerciseNames.count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isActive ? .white.opacity(0.85) : Color.secondary)
            }
            .foregroundStyle(isActive ? .white : .primary)
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background {
                if isActive {
                    Capsule()
                        .fill(Color.accentColor.gradient)
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                } else {
                    Capsule()
                        .fill(Theme.fillStrong)
                        .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                withAnimation(.snappy) {
                    modelContext.delete(template)
                }
            } label: {
                Label("Şablonu Sil", systemImage: "trash")
            }
        }
    }

    private func isTemplateActive(_ template: WorkoutTemplate) -> Bool {
        exercises.map(\.exerciseName) == template.exerciseNames.map { Optional($0) }
    }

    private func applyTemplate(_ template: WorkoutTemplate) {
        if isTemplateActive(template) {
            exercises = [DraftExercise()]
            if template.program != nil, selectedProgram == template.program {
                selectedProgram = nil
            }
            hideKeyboard()
            return
        }

        let newExercises = template.exerciseNames.map { name -> DraftExercise in
            var draft = DraftExercise()
            draft.exerciseName = name
            return draft
        }
        exercises = newExercises.isEmpty ? [DraftExercise()] : newExercises
        if let program = template.program {
            selectedProgram = program
        }
        hideKeyboard()
    }

    // MARK: - Program

    private var programSelector: some View {
        VStack(alignment: .leading, spacing: 14) {
            StepHeader(number: 1, title: "Bugün hangi programı yapıyorsun?")

            FlowLayout(spacing: 8) {
                ForEach(WorkoutProgram.allCases) { program in
                    programChip(program)
                }
            }

            if selectedProgram == nil {
                Text("İstersen seçmeden de devam edebilirsin.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .cardStyle()
    }

    private func programChip(_ program: WorkoutProgram) -> some View {
        let isSelected = selectedProgram == program

        return Button {
            withAnimation(.snappy) {
                selectedProgram = isSelected ? nil : program
                exercises = [DraftExercise()]
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: program.icon)
                    .font(.system(size: 12, weight: .bold))
                Text(program.rawValue)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.accentColor.gradient)
                        .shadow(color: Color.accentColor.opacity(0.45), radius: 8, x: 0, y: 4)
                } else {
                    Capsule()
                        .fill(Theme.fill)
                        .overlay(Capsule().strokeBorder(Theme.fillStrong, lineWidth: 1))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save button

    private var saveButton: some View {
        Button {
            saveWorkout()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("Antrenmanı Kaydet")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(canSave ? AnyShapeStyle(Color.accentColor.gradient) : AnyShapeStyle(Color.secondary.opacity(0.3)))
            )
            .shadow(color: canSave ? Color.accentColor.opacity(0.35) : .clear, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .animation(.snappy, value: canSave)
    }

    // MARK: - Actions

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func startAutoRestTimerIfNeeded() {
        guard let profile = profiles.first, profile.autoRestTimerEnabled else { return }
        restTimer.start(minutes: profile.autoRestTimerMinutes)
    }

    private var canSave: Bool {
        canSaveExercises(exercises)
    }

    private func saveWorkout() {
        let durationMinutes: Int? = {
            if let finishedDurationMinutes { return finishedDurationMinutes }
            if isWorkoutActive, let start = sessionStartDate {
                return max(0, Int(Date().timeIntervalSince(start) / 60))
            }
            return nil
        }()

        guard let session = buildWorkoutSession(
            date: sessionStartDate ?? .now,
            program: selectedProgram,
            exercises: exercises,
            durationMinutes: durationMinutes
        ) else { return }

        hideKeyboard()
        modelContext.insert(session)
        withAnimation(.snappy) {
            exercises = [DraftExercise()]
            selectedProgram = nil
        }
        isWorkoutActive = false
        sessionStartDate = nil
        finishedDurationMinutes = nil
        didSave = true
    }
}

#Preview {
    WorkoutEntryView()
        .modelContainer(for: [WorkoutSession.self, ExerciseEntry.self, SetEntry.self, WorkoutTemplate.self], inMemory: true)
        .environment(RestTimerService())
}
