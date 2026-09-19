import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var profile: UserProfile?
    @State private var weightText = ""
    @State private var heightText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    introCard
                    measurementsCard

                    if let bmi = profile?.bmi {
                        bmiCard(bmi: bmi, category: profile?.bmiCategory ?? "")
                    }
                }
                .padding(16)
            }
            .contentShape(Rectangle())
            .onTapGesture { hideKeyboard() }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profil")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Bitti") { hideKeyboard() }
                        .font(.headline)
                }
            }
            .onAppear(perform: loadInitialValues)
        }
    }

    // MARK: - Intro

    private var introCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.gradient)
                    .shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                Image(systemName: "person.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text("Profilin")
                    .font(.headline)
                Text("Kilo ve boyunu gir, vücut kitle indeksini otomatik görelim.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .cardStyle()
    }

    // MARK: - Measurements

    private var measurementsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            StepHeader(number: 1, title: "Kilo ve boy")

            HStack(spacing: 12) {
                fieldBlock(title: "Kilo", suffix: "kg", text: $weightText, keyboard: .decimalPad) { newValue in
                    ensureProfile().weight = Double(newValue.replacingOccurrences(of: ",", with: "."))
                }

                fieldBlock(title: "Boy", suffix: "cm", text: $heightText, keyboard: .numberPad) { newValue in
                    ensureProfile().height = Double(newValue)
                }
            }
        }
        .cardStyle()
    }

    private func fieldBlock(
        title: String,
        suffix: String,
        text: Binding<String>,
        keyboard: UIKeyboardType,
        onChange: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                TextField("0", text: text)
                    .keyboardType(keyboard)
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                Text(suffix)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
            )
        }
        .frame(maxWidth: .infinity)
        .onChange(of: text.wrappedValue) { _, newValue in
            onChange(newValue)
        }
    }

    // MARK: - BMI

    private func bmiCard(bmi: Double, category: String) -> some View {
        HStack(spacing: 16) {
            StatTile(value: String(format: "%.1f", bmi), label: "BMI", tint: .accentColor)

            Divider().frame(height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(category)
                    .font(.subheadline.weight(.bold))
                Text("Vücut kitle indeksi")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .cardStyle(padding: 16)
    }

    // MARK: - Logic

    @discardableResult
    private func ensureProfile() -> UserProfile {
        if let profile {
            return profile
        }
        if let existing = profiles.first {
            profile = existing
            return existing
        }
        let newProfile = UserProfile()
        modelContext.insert(newProfile)
        profile = newProfile
        return newProfile
    }

    private func loadInitialValues() {
        let current = ensureProfile()
        weightText = current.weight.map { formattedWeight($0) } ?? ""
        heightText = current.height.map { String(Int($0)) } ?? ""
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
