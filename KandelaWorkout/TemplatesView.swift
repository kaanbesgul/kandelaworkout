import SwiftUI
import SwiftData

struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse) private var templates: [WorkoutTemplate]

    @State private var showBuilder = false
    @State private var editingTemplate: WorkoutTemplate?

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(templates) { template in
                            Button {
                                editingTemplate = template
                            } label: {
                                templateRow(template)
                            }
                            .buttonStyle(.plain)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    modelContext.delete(template)
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                                Button {
                                    editingTemplate = template
                                } label: {
                                    Label("Düzenle", systemImage: "pencil")
                                }
                                .tint(.accentColor)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Şablonlar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showBuilder = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
            }
            .sheet(isPresented: $showBuilder) {
                TemplateBuilderView()
            }
            .sheet(item: $editingTemplate) { template in
                TemplateBuilderView(existingTemplate: template)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.13))
                    .frame(width: 92, height: 92)
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(Color.accentColor.gradient)
            }

            VStack(spacing: 6) {
                Text("Henüz şablon yok")
                    .font(.title3.weight(.bold))
                Text("Push, Pull, Leg gibi hep aynı hareketleri\nyaptığın günler için şablon oluştur.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showBuilder = true
            } label: {
                Label("Şablon Oluştur", systemImage: "plus")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.accentColor.gradient))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private func templateRow(_ template: WorkoutTemplate) -> some View {
        HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.gradient)
                    .shadow(color: Color.accentColor.opacity(0.35), radius: 6, x: 0, y: 3)
                Image(systemName: template.program?.icon ?? "list.bullet.clipboard.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(template.name)
                        .font(.subheadline.weight(.bold))
                    if let program = template.program {
                        ProgramTag(program: program)
                    }
                }

                Text(template.exerciseNames.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                MetricPill(icon: "square.stack.3d.up.fill", text: "\(template.exerciseNames.count) hareket")
            }

            Spacer(minLength: 0)
        }
        .cardStyle(padding: 14)
    }

}

// MARK: - Builder

private struct DraftTemplateExercise: Identifiable {
    let id = UUID()
    var exerciseName: String?
}

private struct TemplateBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var existingTemplate: WorkoutTemplate?

    @State private var name = ""
    @State private var selectedProgram: WorkoutProgram?
    @State private var slots: [DraftTemplateExercise] = [DraftTemplateExercise()]

    init(existingTemplate: WorkoutTemplate? = nil) {
        self.existingTemplate = existingTemplate
        _name = State(initialValue: existingTemplate?.name ?? "")
        _selectedProgram = State(initialValue: existingTemplate?.program)
        let names = existingTemplate?.exerciseNames ?? []
        _slots = State(initialValue: names.isEmpty
            ? [DraftTemplateExercise()]
            : names.map { name in
                var slot = DraftTemplateExercise()
                slot.exerciseName = name
                return slot
            }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    nameCard
                    programCard
                    exercisesCard
                }
                .padding(16)
            }
            .contentShape(Rectangle())
            .onTapGesture { hideKeyboard() }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(existingTemplate == nil ? "Yeni Şablon" : "Şablonu Düzenle")
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

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            StepHeader(number: 1, title: "Şablona bir isim ver")
            TextField("Örn. Push Günüm", text: $name)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                )
        }
        .cardStyle()
    }

    private var programCard: some View {
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
                        .fill(Color(.tertiarySystemFill))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var exercisesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            StepHeader(number: 3, title: "Hareketleri ekle")

            VStack(spacing: 10) {
                ForEach($slots) { $slot in
                    slotRow(slot: $slot)
                }
            }

            Button {
                withAnimation(.snappy) {
                    slots.append(DraftTemplateExercise())
                }
            } label: {
                Label("Hareket Ekle", systemImage: "plus")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                Color.accentColor.opacity(0.45),
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .cardStyle()
    }

    private func slotRow(slot: Binding<DraftTemplateExercise>) -> some View {
        let region = slot.wrappedValue.exerciseName.flatMap { ExerciseLibrary.region(forExercise: $0) }

        return HStack(spacing: 10) {
            RegionBadge(region: region, size: 36)

            Menu {
                if let program = selectedProgram {
                    Section("Önerilen · \(program.rawValue)") {
                        ForEach(ExerciseLibrary.recommendedExercises(for: program), id: \.self) { name in
                            Button(name) { slot.wrappedValue.exerciseName = name }
                        }
                    }
                }

                Section("Tüm Hareketler") {
                    ForEach(ExerciseLibrary.sortedRegions) { libraryRegion in
                        Menu(libraryRegion.rawValue) {
                            ForEach(ExerciseLibrary.sortedExercises(for: libraryRegion), id: \.self) { name in
                                Button(name) { slot.wrappedValue.exerciseName = name }
                            }
                        }
                    }
                }
            } label: {
                PickerChip(
                    title: slot.wrappedValue.exerciseName ?? "Hareket Seç",
                    isPlaceholder: slot.wrappedValue.exerciseName == nil
                )
            }

            if slots.count > 1 {
                Button {
                    withAnimation(.snappy) {
                        slots.removeAll { $0.id == slot.wrappedValue.id }
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
    }

    private var canSave: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasExercise = slots.contains { $0.exerciseName != nil }
        return hasName && hasExercise
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func save() {
        var seen = Set<String>()
        let uniqueNames = slots.compactMap(\.exerciseName).filter { seen.insert($0).inserted }
        guard !uniqueNames.isEmpty else { return }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        if let existingTemplate {
            existingTemplate.name = trimmedName
            existingTemplate.programRawValue = selectedProgram?.rawValue
            existingTemplate.exerciseNames = uniqueNames
        } else {
            let template = WorkoutTemplate(name: trimmedName, program: selectedProgram, exerciseNames: uniqueNames)
            modelContext.insert(template)
        }
        dismiss()
    }
}

#Preview {
    TemplatesView()
        .modelContainer(for: [WorkoutSession.self, ExerciseEntry.self, SetEntry.self, WorkoutTemplate.self], inMemory: true)
}
