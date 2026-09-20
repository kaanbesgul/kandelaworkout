import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @State private var selectedSession: WorkoutSession?
    @State private var showPastWorkoutEntry = false

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyState
                } else {
                    List {
                        summaryCard
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 16))

                        if sessions.count >= 2 {
                            volumeChartCard
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 10, trailing: 16))
                        }

                        ForEach(sessions) { session in
                            Button {
                                selectedSession = session
                            } label: {
                                sessionRow(session)
                            }
                            .buttonStyle(.plain)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        }
                        .onDelete(perform: deleteSessions)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Theme.background)
                }
            }
            .navigationTitle("Geçmiş")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPastWorkoutEntry = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
            }
            .navigationDestination(item: $selectedSession) { session in
                WorkoutSessionDetailView(session: session)
            }
            .sheet(isPresented: $showPastWorkoutEntry) {
                PastWorkoutEntryView()
            }
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.13))
                    .frame(width: 92, height: 92)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(Color.accentColor.gradient)
            }

            VStack(spacing: 6) {
                Text("Henüz antrenman yok")
                    .font(.title3.weight(.bold))
                Text("Kaydettiğin antrenmanlar burada\nözetiyle birlikte listelenecek.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }

    // MARK: - Summary

    private var summaryCard: some View {
        HStack(spacing: 0) {
            StatTile(value: "\(sessions.count)", label: "Antrenman")

            Divider().frame(height: 34)

            StatTile(value: "\(thisWeekCount)", label: "Bu Hafta", tint: .blue)

            Divider().frame(height: 34)

            StatTile(value: formattedWeight(totalVolume), label: "Toplam Kg", tint: .green)
        }
        .cardStyle(padding: 16)
    }

    private var thisWeekCount: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return sessions.filter { $0.date >= cutoff }.count
    }

    private var totalVolume: Double {
        sessions.reduce(0) { $0 + $1.totalVolume }
    }

    // MARK: - Volume chart

    private var volumeChartCard: some View {
        let points = Array(sessions.prefix(12).reversed())

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.accentColor)
                Text("Hacim Trendi")
                    .font(.subheadline.weight(.bold))
                Spacer(minLength: 0)
                Text("Son \(points.count) antrenman")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Chart(points) { session in
                AreaMark(
                    x: .value("Tarih", session.date),
                    y: .value("Hacim", session.totalVolume)
                )
                .foregroundStyle(Color.accentColor.opacity(0.12).gradient)
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Tarih", session.date),
                    y: .value("Hacim", session.totalVolume)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                PointMark(
                    x: .value("Tarih", session.date),
                    y: .value("Hacim", session.totalVolume)
                )
                .foregroundStyle(Color.accentColor)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated).locale(Locale(identifier: "tr_TR")))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 150)
        }
        .cardStyle(padding: 16)
    }

    // MARK: - Row

    private func sessionRow(_ session: WorkoutSession) -> some View {
        HStack(spacing: 13) {
            RegionBadge(region: session.exercises.first?.region, size: 44)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(session.date.trDayMonth)
                        .font(.subheadline.weight(.bold))
                    Text(session.date.trTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let program = session.program {
                        ProgramTag(program: program)
                    }
                }

                Text(exerciseSummary(for: session))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    MetricPill(icon: "square.stack.3d.up.fill", text: "\(session.totalSets) set")
                    if session.totalVolume > 0 {
                        MetricPill(icon: "scalemass.fill", text: "\(formattedWeight(session.totalVolume)) kg", tint: .green)
                    }
                    if let duration = session.workoutDurationMinutes, duration > 0 {
                        MetricPill(icon: "stopwatch.fill", text: "\(duration) dk", tint: .teal)
                    } else if session.totalDurationMinutes > 0 {
                        MetricPill(icon: "clock.fill", text: "\(session.totalDurationMinutes) dk", tint: .teal)
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .cardStyle(padding: 14)
    }

    private func exerciseSummary(for session: WorkoutSession) -> String {
        session.exercises.map(\.name).joined(separator: " · ")
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
    }
}

// MARK: - Detail

private struct WorkoutSessionDetailView: View {
    let session: WorkoutSession

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard

                ForEach(session.exercises) { exercise in
                    exerciseCard(exercise)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Theme.background)
        .navigationTitle(session.date.trDayMonth)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.date.trDayMonthWeekday)
                        .font(.headline)
                    HStack(spacing: 4) {
                        Text(session.date.trTime)
                        if let duration = session.workoutDurationMinutes, duration > 0 {
                            Text("· \(duration) dk sürdü")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if let program = session.program {
                    ProgramTag(program: program)
                }
            }

            Divider()

            HStack(spacing: 0) {
                StatTile(value: "\(session.exercises.count)", label: "Hareket")

                Divider().frame(height: 34)

                StatTile(value: "\(session.totalSets)", label: "Set", tint: .blue)

                Divider().frame(height: 34)

                if session.totalVolume > 0 {
                    StatTile(value: formattedWeight(session.totalVolume), label: "Toplam Kg", tint: .green)
                } else if let duration = session.workoutDurationMinutes, duration > 0 {
                    StatTile(value: "\(duration)", label: "Dakika", tint: .teal)
                } else {
                    StatTile(value: "\(session.totalDurationMinutes)", label: "Dakika", tint: .teal)
                }
            }
        }
        .cardStyle()
    }

    private func exerciseCard(_ exercise: ExerciseEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 13) {
                RegionBadge(region: exercise.region)

                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.name)
                        .font(.headline)
                    Text(exercise.region?.rawValue ?? "\(exercise.sets.count) set")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            VStack(spacing: 6) {
                ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Theme.fill))

                        Spacer(minLength: 0)

                        switch exercise.measurement {
                        case .duration:
                            Text("\(set.durationMinutes ?? 0)")
                                .font(.callout.weight(.bold))
                                .monospacedDigit()
                            Text("dakika")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.tertiary)

                        case .bodyweightReps:
                            Text("\(set.reps)")
                                .font(.callout.weight(.bold))
                                .monospacedDigit()
                            Text("tekrar")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.tertiary)

                        case .repsWeight:
                            Text("\(set.reps)")
                                .font(.callout.weight(.bold))
                                .monospacedDigit()
                            Text("tekrar")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.tertiary)
                            Text("×")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.tertiary)
                            Text(formattedWeight(set.weight))
                                .font(.callout.weight(.bold))
                                .monospacedDigit()
                            Text("kg")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.background)
                    )
                }
            }
        }
        .cardStyle()
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [WorkoutSession.self, ExerciseEntry.self, SetEntry.self], inMemory: true)
}
