import SwiftUI
import SwiftData
import Charts

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]

    @State private var profile: UserProfile?
    @State private var weightInput = ""
    @State private var heightText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    introCard
                    weightCard
                    heightCard

                    if let bmi = currentBMI {
                        bmiCard(bmi: bmi, category: BMICalculator.category(bmi: bmi))
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
                Text("Kilonu düzenli gir, ilerlemeni grafikte takip et.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .cardStyle()
    }

    // MARK: - Weight tracking

    private var weightCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            StepHeader(number: 1, title: "Kilonu takip et")

            if let latest = weightEntries.first {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(formattedWeight(latest.weight))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("kg")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    if let delta = weightDelta, delta != 0 {
                        MetricPill(
                            icon: delta > 0 ? "arrow.up.right" : "arrow.down.right",
                            text: "\(delta > 0 ? "+" : "")\(formattedWeight(delta)) kg",
                            tint: delta > 0 ? .orange : .green
                        )
                    }

                    Spacer(minLength: 0)

                    Text(latest.date.trDayMonth)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                TextField("Bugünkü kilon", text: $weightInput)
                    .keyboardType(.decimalPad)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.tertiarySystemFill))
                    )

                Button {
                    logWeight()
                } label: {
                    Text("Kaydet")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule().fill(
                                canLogWeight
                                    ? AnyShapeStyle(Color.accentColor.gradient)
                                    : AnyShapeStyle(Color.secondary.opacity(0.3))
                            )
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canLogWeight)
            }

            if weightEntries.count >= 2 {
                weightChart
            } else {
                Text("Trend grafiği için en az 2 kilo kaydı gerekiyor.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }

    private var weightChart: some View {
        let points = Array(weightEntries.reversed())
        let values = points.map(\.weight)
        let minValue = (values.min() ?? 0) - 2
        let maxValue = (values.max() ?? 0) + 2

        return Chart(points) { entry in
            AreaMark(
                x: .value("Tarih", entry.date),
                y: .value("Kilo", entry.weight)
            )
            .foregroundStyle(Color.accentColor.opacity(0.12).gradient)
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Tarih", entry.date),
                y: .value("Kilo", entry.weight)
            )
            .foregroundStyle(Color.accentColor.gradient)
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

            PointMark(
                x: .value("Tarih", entry.date),
                y: .value("Kilo", entry.weight)
            )
            .foregroundStyle(Color.accentColor)
        }
        .chartYScale(domain: minValue...maxValue)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 160)
        .padding(.top, 4)
    }

    private var weightDelta: Double? {
        guard weightEntries.count >= 2 else { return nil }
        return weightEntries[0].weight - weightEntries[1].weight
    }

    private var canLogWeight: Bool {
        Double(weightInput.replacingOccurrences(of: ",", with: ".")) != nil
    }

    private var currentBMI: Double? {
        guard let weight = weightEntries.first?.weight, let height = profile?.height else { return nil }
        return BMICalculator.bmi(weight: weight, heightCm: height)
    }

    private func logWeight() {
        guard let value = Double(weightInput.replacingOccurrences(of: ",", with: ".")) else { return }

        if let todayEntry = weightEntries.first(where: { Calendar.current.isDateInToday($0.date) }) {
            todayEntry.weight = value
        } else {
            modelContext.insert(WeightEntry(weight: value))
        }

        weightInput = ""
        hideKeyboard()
    }

    // MARK: - Height

    private var heightCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            StepHeader(number: 2, title: "Boyun")

            HStack(spacing: 6) {
                TextField("0", text: $heightText)
                    .keyboardType(.numberPad)
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                Text("cm")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
            )
            .onChange(of: heightText) { _, newValue in
                ensureProfile().height = Double(newValue)
            }
        }
        .cardStyle()
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
        if let profile { return profile }
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
        heightText = current.height.map { String(Int($0)) } ?? ""
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self, WeightEntry.self], inMemory: true)
}
