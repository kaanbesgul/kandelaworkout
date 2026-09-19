import SwiftUI

enum WorkoutProgram: String, CaseIterable, Identifiable, Hashable {
    case fullBody = "Full Body"
    case push = "Push"
    case pull = "Pull"
    case legs = "Legs"
    case kardiyo = "Kardiyo"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fullBody: "square.grid.2x2.fill"
        case .push: "arrow.up.circle.fill"
        case .pull: "arrow.down.circle.fill"
        case .legs: "figure.walk"
        case .kardiyo: "figure.run"
        }
    }

    var tint: Color {
        switch self {
        case .fullBody: .indigo
        case .push: .red
        case .pull: .blue
        case .legs: .green
        case .kardiyo: .teal
        }
    }

    var regions: [MuscleGroup] {
        switch self {
        case .fullBody: [.gogus, .sirt, .bacak, .omuz, .karin]
        case .push: [.gogus, .omuz, .kol]
        case .pull: [.sirt, .kol]
        case .legs: [.bacak, .kalca]
        case .kardiyo: [.kardiyo]
        }
    }
}
