import SwiftUI
import SwiftData

struct PastWorkoutEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var durationText = ""
    @State private var selectedProgram: WorkoutProgram?
    @State private var exercises: [DraftExercise] = [DraftExercise()]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    dateCard
                    programSelector

                    VStack(alignment: .leading, spacing: 12) {
                        StepHeader(number: 3, title: "Hareketleri ekle")
                            .padding(.leading, 4)

                        ExercisesEditorSection(exercises: $exercises, selectedProgram: selectedProgram)
                    }
                }
                .padding(16)
            }
            .environment(\.locale, Locale(identifier: "tr_TR"))
            .contentShape(Rectangle())
            .onTapGesture { hideKeyboard() }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background)
            .navigationTitle("Geçmiş Antrenman Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .fontWeight(.bold)
                        .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Bitti") { hideKeyboard() }
                        .font(.headline)
                }
            }
        }
    }

    // MARK: - Date & duration

    private var dateCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            StepHeader(number: 1, title: "Ne zaman ve ne kadar sürdü?")

            DatePicker("Tarih", selection: $date, in: ...Date())
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(Color.accentColor)

            HStack(spacing: 6) {
                TextField("0", text: $durationText)
                    .keyboardType(.numberPad)
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                Text("dakika")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.fillStrong, lineWidth: 1)
            )
        }
        .cardStyle()
    }

    // MARK: - Program

    private var programSelector: some View {
        VStack(alignment: .leading, spacing: 14) {
            StepHeader(number: 2, title: "Program (opsiyonel)")

            FlowLayout(spacing: 8) {
                ForEach(WorkoutProgram.allCases) { program in
                    programChip(program)
                }
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
                        .fill(Theme.fill)
                        .overlay(Capsule().strokeBorder(Theme.fillStrong, lineWidth: 1))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private var canSave: Bool {
        canSaveExercises(exercises)
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func save() {
        let durationMinutes = Int(durationText)

        guard let session = buildWorkoutSession(
            date: date,
            program: selectedProgram,
            exercises: exercises,
            durationMinutes: durationMinutes
        ) else { return }

        modelContext.insert(session)
        dismiss()
    }
}

#Preview {
    PastWorkoutEntryView()
        .modelContainer(for: [WorkoutSession.self, ExerciseEntry.self, SetEntry.self], inMemory: true)
}
