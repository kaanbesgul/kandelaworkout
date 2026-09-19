import SwiftUI

enum MuscleGroup: String, CaseIterable, Identifiable, Hashable {
    case gogus = "Göğüs"
    case sirt = "Sırt"
    case omuz = "Omuz"
    case kol = "Kol"
    case bacak = "Bacak"
    case kalca = "Kalça"
    case karin = "Karın"
    case kardiyo = "Kardiyo"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .gogus: "figure.strengthtraining.traditional"
        case .sirt: "figure.strengthtraining.functional"
        case .omuz: "dumbbell.fill"
        case .kol: "figure.arms.open"
        case .bacak: "figure.walk"
        case .kalca: "figure.core.training"
        case .karin: "figure.flexibility"
        case .kardiyo: "figure.run"
        }
    }

    var tint: Color {
        switch self {
        case .gogus: .orange
        case .sirt: .blue
        case .omuz: .purple
        case .kol: .red
        case .bacak: .green
        case .kalca: .pink
        case .karin: .yellow
        case .kardiyo: .teal
        }
    }
}

enum ExerciseMeasurement {
    case repsWeight
    case bodyweightReps
    case duration
}

enum ExerciseLibrary {
    private static let turkishLocale = Locale(identifier: "tr_TR")

    private static let bodyweightExercises: Set<String> = [
        "Şınav", "Mekik (Crunch)", "Leg Raise", "Ab Wheel", "Barfiks",
        "Diamond Push-Up (Elmas Şınav)", "Dips (Göğüs Dip)", "Chin-Up (Ters Barfiks)",
        "Bench Dip", "Box Jump", "Bicycle Crunch", "Dead Bug", "Hanging Leg Raise",
        "Reverse Crunch", "Sit-Up", "Toe Touch", "V-Up", "Donkey Kick", "Frog Pump",
        "Sissy Squat",
    ]

    private static let durationExercises: Set<String> = [
        "Plank", "Bisiklet", "Eliptik", "İp Atlama", "Koşu Bandı", "Rowing Machine",
        "Side Plank", "Wall Sit", "Mountain Climber", "Stairmaster", "Yüzme",
        "Açık Hava Koşusu", "Açık Hava Bisikleti", "Kickboxing", "Battle Rope",
        "Sled Push", "Assault Bike",
    ]

    private static let exercisesByRegion: [MuscleGroup: [String]] = [
        .gogus: [
            "Bench Press",
            "Cable Crossover",
            "Chest Press Makinesi",
            "Diamond Push-Up (Elmas Şınav)",
            "Dips (Göğüs Dip)",
            "Dumbbell Bench Press",
            "Eğimli Bench Press",
            "Eğimli Dumbbell Press",
            "Cable Fly (Alt Kablo)",
            "Landmine Press",
            "Machine Fly",
            "Pec Deck (Kelebek)",
            "Şınav",
            "Smith Machine Bench Press",
            "Svend Press",
            "Ters Eğimli Bench Press",
            "Ters Eğimli Dumbbell Press",
        ],
        .sirt: [
            "Barfiks",
            "Chin-Up (Ters Barfiks)",
            "Close Grip Lat Pulldown",
            "Deadlift",
            "Good Morning",
            "Hyperextension",
            "Kürek Çekme (Barbell Row)",
            "Lat Pulldown",
            "Meadows Row",
            "Rack Pull",
            "Renegade Row",
            "Seated Cable Row",
            "Straight Arm Pulldown",
            "T-Bar Row",
            "Tek Kol Dumbbell Row",
            "Wide Grip Lat Pulldown",
        ],
        .omuz: [
            "Arka Omuz Kaldırış (Rear Delt Fly)",
            "Arnold Press",
            "Barbell Shrug",
            "Cable Front Raise",
            "Cable Lateral Raise",
            "Dumbbell Shoulder Press",
            "Face Pull",
            "Machine Shoulder Press",
            "Ön Kaldırış (Front Raise)",
            "Overhead Press",
            "Push Press",
            "Reverse Pec Deck",
            "Shrug (Trapez)",
            "Upright Row",
            "Yan Kaldırış (Lateral Raise)",
        ],
        .kol: [
            "21s Curl",
            "Barbell Curl",
            "Bench Dip",
            "Cable Curl",
            "Cable Overhead Extension",
            "Close Grip Bench Press",
            "Concentration Curl",
            "Dumbbell Curl",
            "Hammer Curl",
            "Overhead Triceps Extension",
            "Preacher Curl",
            "Skull Crusher",
            "Spider Curl",
            "Triceps Dip",
            "Triceps Kickback",
            "Triceps Pushdown",
            "Zottman Curl",
        ],
        .bacak: [
            "Box Jump",
            "Bulgar Squat",
            "Calf Raise",
            "Front Squat",
            "Goblet Squat",
            "Hack Squat",
            "Leg Curl",
            "Leg Extension",
            "Leg Press",
            "Lunge",
            "Romanian Deadlift",
            "Seated Calf Raise",
            "Sissy Squat",
            "Squat",
            "Standing Calf Raise",
            "Step-Up",
            "Wall Sit",
        ],
        .kalca: [
            "Abductor Machine",
            "Adductor Machine",
            "Cable Kickback",
            "Curtsy Lunge",
            "Donkey Kick",
            "Frog Pump",
            "Glute Bridge",
            "Hip Thrust",
            "Single Leg Hip Thrust",
            "Sumo Deadlift",
        ],
        .karin: [
            "Ab Wheel",
            "Bicycle Crunch",
            "Cable Crunch",
            "Dead Bug",
            "Hanging Leg Raise",
            "Leg Raise",
            "Mekik (Crunch)",
            "Mountain Climber",
            "Plank",
            "Reverse Crunch",
            "Russian Twist",
            "Side Plank",
            "Sit-Up",
            "Toe Touch",
            "V-Up",
        ],
        .kardiyo: [
            "Assault Bike",
            "Açık Hava Bisikleti",
            "Açık Hava Koşusu",
            "Battle Rope",
            "Bisiklet",
            "Eliptik",
            "İp Atlama",
            "Kickboxing",
            "Koşu Bandı",
            "Rowing Machine",
            "Sled Push",
            "Stairmaster",
            "Yüzme",
        ],
    ]

    static var sortedRegions: [MuscleGroup] {
        MuscleGroup.allCases.sorted {
            $0.rawValue.compare($1.rawValue, locale: turkishLocale) == .orderedAscending
        }
    }

    static func sortedExercises(for region: MuscleGroup) -> [String] {
        (exercisesByRegion[region] ?? []).sorted {
            $0.compare($1, locale: turkishLocale) == .orderedAscending
        }
    }

    static func region(forExercise name: String) -> MuscleGroup? {
        exercisesByRegion.first { _, names in names.contains(name) }?.key
    }

    static func recommendedExercises(for program: WorkoutProgram) -> [String] {
        program.regions.flatMap { sortedExercises(for: $0) }
    }

    static func measurement(forExercise name: String) -> ExerciseMeasurement {
        if durationExercises.contains(name) { return .duration }
        if bodyweightExercises.contains(name) { return .bodyweightReps }
        return .repsWeight
    }
}
