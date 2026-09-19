import SwiftUI
import SwiftData
import FoundationModels

// MARK: - On-device service

@available(iOS 26.0, *)
enum WorkoutCoach {
    static var unavailableMessage: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return "Bu cihaz Apple Intelligence'ı desteklemiyor (iPhone 15 Pro ve üzeri gerekiyor)."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Apple Intelligence kapalı. Ayarlar → Apple Intelligence & Siri bölümünden açabilirsin."
        case .unavailable(.modelNotReady):
            return "Model henüz indiriliyor. Birkaç dakika sonra tekrar dene."
        case .unavailable:
            return "Cihaz üstü yapay zekâ şu anda kullanılamıyor."
        }
    }

    static func stream(
        instructions: String,
        prompt: String,
        onUpdate: @escaping @MainActor (String) -> Void
    ) async throws {
        let session = LanguageModelSession(instructions: instructions)
        let stream = session.streamResponse(
            to: prompt,
            options: GenerationOptions(temperature: 0.6)
        )

        for try await snapshot in stream {
            let text = snapshot.content
            await MainActor.run { onUpdate(text) }
        }
    }
}

// MARK: - Engine

enum AnalysisEngine: String, CaseIterable, Identifiable {
    case device
    case local

    var id: String { rawValue }

    var title: String {
        switch self {
        case .device: "Cihaz"
        case .local: "Yerel"
        }
    }

    var caption: String {
        switch self {
        case .device: "Apple Intelligence ile cihazda çalışır, veriler telefondan çıkmaz."
        case .local: "Yapay zekâ gerektirmez, kayıtlarından istatistik çıkarır."
        }
    }
}

// MARK: - Preset questions

private struct CoachPrompt: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let question: String
}

private let coachPrompts: [CoachPrompt] = [
    CoachPrompt(
        title: "Genel analiz",
        icon: "chart.bar.doc.horizontal",
        question: "Antrenman geçmişimi genel olarak değerlendir. Neyi iyi yapıyorum, neyi geliştirmeliyim?"
    ),
    CoachPrompt(
        title: "İlerleme",
        icon: "chart.line.uptrend.xyaxis",
        question: "Zaman içinde ilerliyor muyum? Ağırlık ve hacim olarak gelişimimi yorumla."
    ),
    CoachPrompt(
        title: "Eksik bölgeler",
        icon: "exclamationmark.triangle",
        question: "Hangi kas bölgelerini ihmal ediyorum? Dengesizlik var mı?"
    ),
    CoachPrompt(
        title: "Program önerisi",
        icon: "calendar",
        question: "Geçmişime bakarak önümüzdeki hafta için bana bir antrenman programı öner."
    ),
]

// MARK: - View

struct AIAnalysisView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    @State private var engine: AnalysisEngine = .local
    @State private var didPickEngine = false

    @State private var question = ""
    @State private var askedQuestion: String?
    @State private var answer = ""
    @State private var errorMessage: String?
    @State private var isAnalyzing = false
    @State private var analysisTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    introCard
                    enginePicker

                    if sessions.isEmpty {
                        noticeCard(
                            icon: "tray",
                            title: "Henüz veri yok",
                            message: "Analiz için önce birkaç antrenman kaydetmen gerekiyor."
                        )
                    } else {
                        switch engine {
                        case .device:
                            if let unavailable = deviceUnavailableMessage {
                                noticeCard(
                                    icon: "sparkles.slash",
                                    title: "Cihaz üstü yapay zekâ yok",
                                    message: unavailable + "\n\nAlttaki \"Yerel\" sekmesi her cihazda çalışır."
                                )
                            } else {
                                questionCard
                            }
                        case .local:
                            localInsightsCard
                        }
                    }

                    if engine != .local, askedQuestion != nil || isAnalyzing {
                        answerCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
            }
            .contentShape(Rectangle())
            .onTapGesture { hideKeyboard() }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("AI Koç")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Bitti") { hideKeyboard() }
                        .font(.headline)
                }
            }
            .onAppear {
                selectDefaultEngineIfNeeded()
            }
        }
    }

    // MARK: Intro

    private var introCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.gradient)
                    .shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text("Antrenman koçun")
                    .font(.headline)
                Text(sessions.isEmpty
                     ? "Kayıtların analiz edilecek."
                     : "\(min(sessions.count, 15)) antrenman kaydın analiz edilecek.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .cardStyle()
    }

    private var enginePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Analiz motoru", selection: $engine) {
                ForEach(AnalysisEngine.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: engine) {
                didPickEngine = true
                answer = ""
                askedQuestion = nil
                errorMessage = nil
            }

            Text(engine.caption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .cardStyle(padding: 14)
    }

    private func noticeCard(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline.weight(.bold))
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    // MARK: Local insights

    private var localInsightsCard: some View {
        let insights = LocalAnalysis.insights(for: sessions)

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.accentColor)
                Text("Kayıtlarından çıkarımlar")
                    .font(.subheadline.weight(.bold))
                Spacer(minLength: 0)
            }

            ForEach(insights) { insight in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: insight.icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(insight.tint.gradient))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(insight.title)
                            .font(.subheadline.weight(.bold))
                        Text(insight.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .cardStyle()
    }

    // MARK: Question

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            StepHeader(number: 1, title: "Ne sormak istersin?")

            FlowLayout(spacing: 8) {
                ForEach(coachPrompts) { prompt in
                    Button {
                        hideKeyboard()
                        question = prompt.question
                        runAnalysis(prompt.question)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: prompt.icon)
                                .font(.system(size: 11, weight: .bold))
                            Text(prompt.title)
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Color.accentColor.opacity(0.13)))
                    }
                    .buttonStyle(.plain)
                    .disabled(isAnalyzing)
                }
            }

            TextField("Kendi sorunu yaz…", text: $question, axis: .vertical)
                .lineLimit(1...4)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                )

            Button {
                hideKeyboard()
                runAnalysis(question)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .bold))
                    Text(isAnalyzing ? "Analiz ediliyor…" : "Analiz Et")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(canAnalyze ? AnyShapeStyle(Color.accentColor.gradient) : AnyShapeStyle(Color.secondary.opacity(0.3)))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canAnalyze)
            .animation(.snappy, value: canAnalyze)
        }
        .cardStyle()
    }

    // MARK: Answer

    private var answerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.accentColor)
                Text("Analiz")
                    .font(.subheadline.weight(.bold))

                Spacer(minLength: 0)

                if isAnalyzing {
                    ProgressView()
                        .controlSize(.small)
                } else if !answer.isEmpty {
                    Button {
                        UIPasteboard.general.string = answer
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color(.tertiarySystemFill)))
                    }
                    .buttonStyle(.plain)
                }
            }

            if let askedQuestion {
                Text(askedQuestion)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.tertiarySystemFill))
                    )
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            } else if answer.isEmpty {
                Text("Kayıtların inceleniyor…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(markdown(answer))
                    .font(.subheadline)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .cardStyle()
    }

    // MARK: Logic

    private var deviceUnavailableMessage: String? {
        if #available(iOS 26.0, *) {
            return WorkoutCoach.unavailableMessage
        } else {
            return "Bu özellik iOS 26 ve üzeri gerektiriyor."
        }
    }

    private var canAnalyze: Bool {
        !isAnalyzing && !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func selectDefaultEngineIfNeeded() {
        guard !didPickEngine else { return }
        engine = deviceUnavailableMessage == nil ? .device : .local
    }

    private func markdown(_ text: String) -> AttributedString {
        (try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(text)
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func runAnalysis(_ prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isAnalyzing else { return }

        analysisTask?.cancel()
        askedQuestion = trimmed
        answer = ""
        errorMessage = nil
        isAnalyzing = true

        let fullPrompt = buildPrompt(question: trimmed)

        analysisTask = Task {
            do {
                switch engine {
                case .device:
                    if #available(iOS 26.0, *) {
                        try await WorkoutCoach.stream(
                            instructions: Self.instructions,
                            prompt: fullPrompt
                        ) { partial in
                            answer = partial
                        }
                    } else {
                        errorMessage = "Bu özellik iOS 26 ve üzeri gerektiriyor."
                    }

                case .local:
                    break
                }
            } catch {
                errorMessage = "Analiz tamamlanamadı: \(error.localizedDescription)"
            }

            isAnalyzing = false
        }
    }

    private static let instructions = """
    Sen deneyimli bir spor salonu antrenörüsün. Kullanıcının antrenman kayıtlarını inceleyip Türkçe cevap veriyorsun.
    Kurallar:
    - Sadece verilen antrenman verilerine dayan, veri yoksa tahmin uydurma.
    - Kısa ve net yaz, en fazla 6 madde kullan.
    - Somut sayılara atıfta bulun (set sayısı, tekrar, kilo, bölge).
    - Samimi ve motive edici bir dil kullan, abartılı sağlık iddiasında bulunma.
    - Ağrı veya sakatlık söz konusuysa doktora yönlendir.
    """

    private func buildPrompt(question: String) -> String {
        """
        Antrenman geçmişim (en yeni önce):
        \(historyContext)

        Toplam özet: \(sessions.count) antrenman, \(totalSets) set, \(formattedWeight(totalVolume)) kg toplam hacim.

        Sorum: \(question)
        """
    }

    private var historyContext: String {
        sessions.prefix(15).map { session in
            var header = "• \(session.date.trDayMonth)"
            if let program = session.program {
                header += " (\(program.rawValue))"
            }

            let exerciseLines = session.exercises.map { exercise -> String in
                let region = exercise.region?.rawValue ?? "bilinmiyor"
                let sets = exercise.sets.map { set -> String in
                    switch exercise.measurement {
                    case .duration:
                        return "\(set.durationMinutes ?? 0) dk"
                    case .bodyweightReps:
                        return "\(set.reps) tekrar"
                    case .repsWeight:
                        return "\(set.reps)x\(formattedWeight(set.weight))kg"
                    }
                }.joined(separator: ", ")
                return "   - \(exercise.name) [\(region)]: \(sets)"
            }

            return ([header] + exerciseLines).joined(separator: "\n")
        }.joined(separator: "\n")
    }

    private var totalSets: Int {
        sessions.reduce(0) { $0 + $1.totalSets }
    }

    private var totalVolume: Double {
        sessions.reduce(0) { $0 + $1.totalVolume }
    }
}

#Preview {
    AIAnalysisView()
        .modelContainer(for: [WorkoutSession.self, ExerciseEntry.self, SetEntry.self], inMemory: true)
}
