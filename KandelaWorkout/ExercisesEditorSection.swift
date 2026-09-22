import SwiftUI

struct DraftSet: Identifiable, Codable, Equatable {
    var id = UUID()
    var reps: String = ""
    var weight: String = ""
    var duration: String = ""
}

struct DraftExercise: Identifiable, Codable, Equatable {
    var id = UUID()
    var exerciseName: String?
    var sets: [DraftSet] = [DraftSet()]

    var region: MuscleGroup? {
        exerciseName.flatMap { ExerciseLibrary.region(forExercise: $0) }
    }

    var measurement: ExerciseMeasurement {
        exerciseName.map { ExerciseLibrary.measurement(forExercise: $0) } ?? .repsWeight
    }
}

/// Builds a `WorkoutSession` from draft exercises, dropping any exercise/set that was never filled in.
/// Returns nil if nothing valid was entered.
func buildWorkoutSession(
    date: Date,
    program: WorkoutProgram?,
    exercises: [DraftExercise],
    durationMinutes: Int?
) -> WorkoutSession? {
    let session = WorkoutSession(date: date, program: program, durationMinutes: durationMinutes)

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

    guard !session.exercises.isEmpty else { return nil }
    return session
}

func canSaveExercises(_ exercises: [DraftExercise]) -> Bool {
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

/// Shared "pick exercises, add sets" editor used by both the live workout entry screen
/// and the past-workout entry form.
struct ExercisesEditorSection: View {
    @Binding var exercises: [DraftExercise]
    var selectedProgram: WorkoutProgram?
    var onSetAdded: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            ForEach($exercises) { $exercise in
                exerciseCard(exercise: $exercise)
            }

            addExerciseButton
        }
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
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Theme.fill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Theme.fillStrong, lineWidth: 1)
                    )
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
                            .background(Circle().fill(Theme.fill))
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
                onSetAdded?()
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
                .background(Circle().fill(Theme.fill))

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
                    .background(Circle().fill(Theme.fill))
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.background)
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
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Theme.border, lineWidth: 1)
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
}
