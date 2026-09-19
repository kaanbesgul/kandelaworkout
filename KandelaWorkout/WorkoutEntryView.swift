import SwiftUI
import SwiftData

private struct DraftSet: Identifiable {
    let id = UUID()
    var reps: String = ""
    var weight: String = ""
    var duration: String = ""
}

private struct DraftExercise: Identifiable {
    let id = UUID()
    var exerciseName: String?
    var sets: [DraftSet] = [DraftSet()]

    var region: MuscleGroup? {
        exerciseName.flatMap { ExerciseLibrary.region(forExercise: $0) }
    }

    var measurement: ExerciseMeasurement {
        exerciseName.map { ExerciseLibrary.measurement(forExercise: $0) } ?? .repsWeight
    }
}

struct WorkoutEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(RestTimerService.self) private var restTimer
    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse) private var templates: [WorkoutTemplate]

    @State private var exercises: [DraftExercise] = [DraftExercise()]
    @State private var selectedProgram: WorkoutProgram?
    @State private var didSave = false
    @State private var showTimerSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if restTimer.isActive {
                        timerBanner
                    }

                    programSelector

                    VStack(alignment: .leading, spacing: 12) {
                        StepHeader(number: 2, title: "Hareketleri ekle")
                            .padding(.leading, 4)

                        if !templates.isEmpty {
                            templateSelector
                        }

                        ForEach($exercises) { $exercise in
                            exerciseCard(exercise: $exercise)
                        }

                        addExerciseButton
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
            .background(Color(.systemGroupedBackground))
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
                .fill(Color(.tertiarySystemFill).opacity(0.5))
        )
    }

    private func templateChip(_ template: WorkoutTemplate) -> some View {
        Button {
            applyTemplate(template)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: template.program?.icon ?? "list.bullet.clipboard.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                Text(template.name)
                    .font(.subheadline.weight(.semibold))
                Text("\(template.exerciseNames.count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(Capsule().fill(Color(.secondarySystemGroupedBackground)))
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

    private func applyTemplate(_ template: WorkoutTemplate) {
        withAnimation(.snappy) {
            let newExercises = template.exerciseNames.map { name -> DraftExercise in
                var draft = DraftExercise()
                draft.exerciseName = name
                return draft
            }
            exercises = newExercises.isEmpty ? [DraftExercise()] : newExercises
            if let program = template.program {
                selectedProgram = program
            }
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
                        .fill(Color(.tertiarySystemFill))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Exercise card

    @ViewBuilder
    private func exerciseCard(exercise: Binding<DraftExercise>) -> some View {
        let draft = exercise.wrappedValue
        let region = draft.region

        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Menu {
                    if let program = selectedProgram {
                        Section("Önerilen · \(program.rawValue)") {
                            ForEach(ExerciseLibrary.recommendedExercises(for: program), id: \.self) { name in
                                Button(name) {
                                    exercise.wrappedValue.exerciseName = name
                                }
                            }
                        }
                    }

                    Section("Tüm Hareketler") {
                        ForEach(ExerciseLibrary.sortedRegions) { libraryRegion in
                            Menu(libraryRegion.rawValue) {
                                ForEach(ExerciseLibrary.sortedExercises(for: libraryRegion), id: \.self) { name in
                                    Button(name) {
                                        exercise.wrappedValue.exerciseName = name
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        RegionBadge(region: region, size: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(draft.exerciseName ?? "Hareket seç")
                                .font(.headline)
                                .foregroundStyle(draft.exerciseName == nil ? .secondary : .primary)
                                .lineLimit(1)
                            Text(subtitle(for: draft))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if exercises.count > 1 {
                    Button {
                        withAnimation(.snappy) {
                            exercises.removeAll { $0.id == draft.id }
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Color(.tertiarySystemFill)))
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(spacing: 8) {
                ForEach(exercise.sets) { $set in
                    let index = (exercise.wrappedValue.sets.firstIndex { $0.id == set.id } ?? 0) + 1
                    setRow(index: index, set: $set, measurement: draft.measurement) {
                        withAnimation(.snappy) {
                            exercise.wrappedValue.sets.removeAll { $0.id == set.id }
                        }
                    }
                }
            }

            Button {
                withAnimation(.snappy) {
                    exercise.wrappedValue.sets.append(DraftSet())
                }
            } label: {
                Label("Set Ekle", systemImage: "plus")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.accentColor.opacity(0.1)))
            }
            .buttonStyle(.plain)
        }
        .cardStyle()
    }

    private func subtitle(for draft: DraftExercise) -> String {
        guard let region = draft.region else { return "Listeden bir hareket seç" }
        return "\(region.rawValue) · \(draft.sets.count) set"
    }

    // MARK: - Set row

    private func setRow(
        index: Int,
        set: Binding<DraftSet>,
        measurement: ExerciseMeasurement,
        onDelete: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 10) {
            Text("\(index)")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color(.tertiarySystemFill)))

            switch measurement {
            case .repsWeight:
                numberField("Tekrar", text: set.reps, keyboard: .numberPad)
                Text("×")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.tertiary)
                numberField("Kg", text: set.weight, keyboard: .decimalPad)
                unitLabel("kg")

            case .bodyweightReps:
                numberField("Tekrar", text: set.reps, keyboard: .numberPad)
                unitLabel("tekrar")
                Spacer(minLength: 0)

            case .duration:
                numberField("Süre", text: set.duration, keyboard: .numberPad)
                unitLabel("dakika")
                Spacer(minLength: 0)
            }

            Button(action: onDelete) {
                Image(systemName: "minus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color(.tertiarySystemFill)))
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGroupedBackground))
        )
    }

    private func numberField(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .multilineTextAlignment(.center)
            .font(.callout.weight(.semibold))
            .monospacedDigit()
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
            )
    }

    private func unitLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.tertiary)
    }

    // MARK: - Buttons

    private var addExerciseButton: some View {
        Button {
            withAnimation(.snappy) {
                exercises.append(DraftExercise())
            }
        } label: {
            Label("Hareket Ekle", systemImage: "plus")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            Color.accentColor.opacity(0.45),
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])
                        )
                )
        }
        .buttonStyle(.plain)
    }

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

    private var canSave: Bool {
        exercises.contains { exercise in
            guard exercise.exerciseName != nil else { return false }
            switch exercise.measurement {
            case .duration:
                return exercise.sets.contains { Int($0.duration) != nil }
            case .repsWeight, .bodyweightReps:
                return exercise.sets.contains { Int($0.reps) != nil }
            }
        }
    }

    private func saveWorkout() {
        let session = WorkoutSession(program: selectedProgram)

        for draftExercise in exercises {
            guard let name = draftExercise.exerciseName else { continue }

            let validSets = draftExercise.sets.compactMap { draftSet -> SetEntry? in
                switch draftExercise.measurement {
                case .duration:
                    guard let minutes = Int(draftSet.duration) else { return nil }
                    return SetEntry(durationMinutes: minutes)
                case .bodyweightReps:
                    guard let reps = Int(draftSet.reps) else { return nil }
                    return SetEntry(reps: reps)
                case .repsWeight:
                    guard let reps = Int(draftSet.reps) else { return nil }
                    let weight = Double(draftSet.weight.replacingOccurrences(of: ",", with: ".")) ?? 0
                    return SetEntry(reps: reps, weight: weight)
                }
            }
            guard !validSets.isEmpty else { continue }

            let exerciseEntry = ExerciseEntry(name: name, region: draftExercise.region, sets: validSets)
            session.exercises.append(exerciseEntry)
        }

        guard !session.exercises.isEmpty else { return }

        hideKeyboard()
        modelContext.insert(session)
        withAnimation(.snappy) {
            exercises = [DraftExercise()]
            selectedProgram = nil
        }
        didSave = true
    }
}

#Preview {
    WorkoutEntryView()
        .modelContainer(for: [WorkoutSession.self, ExerciseEntry.self, SetEntry.self, WorkoutTemplate.self], inMemory: true)
        .environment(RestTimerService())
}
