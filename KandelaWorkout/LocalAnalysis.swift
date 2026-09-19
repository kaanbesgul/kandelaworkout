import SwiftUI

struct Insight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let tint: Color
}

enum LocalAnalysis {
    static func insights(for sessions: [WorkoutSession]) -> [Insight] {
        guard !sessions.isEmpty else { return [] }

        var result: [Insight] = []

        if let frequency = frequencyInsight(sessions) { result.append(frequency) }
        if let trend = volumeTrendInsight(sessions) { result.append(trend) }
        if let distribution = distributionInsight(sessions) { result.append(distribution) }
        if let neglected = neglectedInsight(sessions) { result.append(neglected) }
        if let records = recordsInsight(sessions) { result.append(records) }
        if let rest = restInsight(sessions) { result.append(rest) }

        return result
    }

    // MARK: - Sıklık

    private static func frequencyInsight(_ sessions: [WorkoutSession]) -> Insight? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -28, to: .now) ?? .now
        let recent = sessions.filter { $0.date >= cutoff }
        guard !recent.isEmpty else { return nil }

        let perWeek = Double(recent.count) / 4.0
        let detail = String(
            format: "Son 4 haftada %d antrenman yaptın, haftada ortalama %.1f. %@",
            recent.count,
            perWeek,
            perWeek >= 3 ? "Bu tempo kas gelişimi için ideal." : "Haftada 3'e çıkarmak gelişimini hızlandırır."
        )

        return Insight(
            icon: "calendar",
            title: "Antrenman sıklığın",
            detail: detail,
            tint: .blue
        )
    }

    // MARK: - Hacim trendi

    private static func volumeTrendInsight(_ sessions: [WorkoutSession]) -> Insight? {
        let withVolume = sessions.filter { $0.totalVolume > 0 }
        guard withVolume.count >= 4 else { return nil }

        let recent = withVolume.prefix(3).reduce(0) { $0 + $1.totalVolume }
        let previous = withVolume.dropFirst(3).prefix(3).reduce(0) { $0 + $1.totalVolume }
        guard previous > 0 else { return nil }

        let change = (recent - previous) / previous * 100
        let rising = change >= 0

        let detail = String(
            format: "Son 3 antrenmanın toplam hacmi %@ kg, önceki 3'e göre %%%.0f %@.",
            formattedWeight(recent),
            abs(change),
            rising ? "artmış" : "azalmış"
        )

        return Insight(
            icon: rising ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis",
            title: rising ? "Hacmin artıyor" : "Hacmin düşüyor",
            detail: detail,
            tint: rising ? .green : .orange
        )
    }

    // MARK: - Bölge dağılımı

    private static func distributionInsight(_ sessions: [WorkoutSession]) -> Insight? {
        var setsByRegion: [MuscleGroup: Int] = [:]
        var total = 0

        for session in sessions {
            for exercise in session.exercises {
                guard let region = exercise.region else { continue }
                setsByRegion[region, default: 0] += exercise.sets.count
                total += exercise.sets.count
            }
        }

        guard total > 0 else { return nil }

        let top = setsByRegion
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { "\($0.key.rawValue) %\(Int(Double($0.value) / Double(total) * 100))" }
            .joined(separator: " · ")

        return Insight(
            icon: "chart.pie.fill",
            title: "En çok çalıştığın bölgeler",
            detail: "\(top). Toplam \(total) set kaydedildi.",
            tint: .purple
        )
    }

    // MARK: - İhmal edilen bölgeler

    private static func neglectedInsight(_ sessions: [WorkoutSession]) -> Insight? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now
        let recentRegions = Set(
            sessions
                .filter { $0.date >= cutoff }
                .flatMap { $0.exercises.compactMap(\.region) }
        )

        let strengthRegions: [MuscleGroup] = [.gogus, .sirt, .omuz, .kol, .bacak, .kalca, .karin]
        let missing = strengthRegions.filter { !recentRegions.contains($0) }

        guard !missing.isEmpty else {
            return Insight(
                icon: "checkmark.seal.fill",
                title: "Dengeli çalışıyorsun",
                detail: "Son 2 haftada tüm ana kas bölgelerine dokunmuşsun. Böyle devam!",
                tint: .green
            )
        }

        return Insight(
            icon: "exclamationmark.triangle.fill",
            title: "İhmal edilen bölgeler",
            detail: "Son 2 haftada hiç çalışmadığın bölgeler: \(missing.map(\.rawValue).joined(separator: ", ")).",
            tint: .orange
        )
    }

    // MARK: - Rekorlar

    private static func recordsInsight(_ sessions: [WorkoutSession]) -> Insight? {
        var bestWeight: [String: Double] = [:]

        for session in sessions {
            for exercise in session.exercises {
                for set in exercise.sets where set.weight > 0 {
                    bestWeight[exercise.name] = max(bestWeight[exercise.name] ?? 0, set.weight)
                }
            }
        }

        guard !bestWeight.isEmpty else { return nil }

        let top = bestWeight
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { "\($0.key) \(formattedWeight($0.value)) kg" }
            .joined(separator: " · ")

        return Insight(
            icon: "trophy.fill",
            title: "Kişisel rekorların",
            detail: top,
            tint: .yellow
        )
    }

    // MARK: - Dinlenme

    private static func restInsight(_ sessions: [WorkoutSession]) -> Insight? {
        guard let last = sessions.first else { return nil }

        let days = Calendar.current.dateComponents([.day], from: last.date, to: .now).day ?? 0

        let detail: String
        switch days {
        case 0: detail = "Bugün antrenman yaptın. Toparlanmaya da zaman ayır."
        case 1: detail = "Son antrenmanın dün. Tempon iyi gidiyor."
        case 2...4: detail = "Son antrenmanından \(days) gün geçti. Sıradaki için iyi bir zaman."
        default: detail = "Son antrenmanından \(days) gün geçti. Ritmi kaybetmemek için bugün kısa bir seans yapabilirsin."
        }

        return Insight(
            icon: "moon.zzz.fill",
            title: "Son antrenman",
            detail: detail,
            tint: .teal
        )
    }
}
