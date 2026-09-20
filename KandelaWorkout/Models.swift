import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var date: Date
    var programRawValue: String?
    var workoutDurationMinutes: Int?
    @Relationship(deleteRule: .cascade, inverse: \ExerciseEntry.session)
    var exercises: [ExerciseEntry]

    init(
        date: Date = .now,
        program: WorkoutProgram? = nil,
        exercises: [ExerciseEntry] = [],
        durationMinutes: Int? = nil
    ) {
        self.date = date
        self.programRawValue = program?.rawValue
        self.exercises = exercises
        self.workoutDurationMinutes = durationMinutes
    }

    var program: WorkoutProgram? {
        programRawValue.flatMap { WorkoutProgram(rawValue: $0) }
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    var totalVolume: Double {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { $0 + Double($1.reps) * $1.weight }
        }
    }

    var totalDurationMinutes: Int {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { $0 + ($1.durationMinutes ?? 0) }
        }
    }
}

@Model
final class ExerciseEntry {
    var name: String
    var regionRawValue: String?
    var session: WorkoutSession?
    @Relationship(deleteRule: .cascade, inverse: \SetEntry.exercise)
    var sets: [SetEntry]

    init(name: String, region: MuscleGroup? = nil, sets: [SetEntry] = []) {
        self.name = name
        self.regionRawValue = region?.rawValue
        self.sets = sets
    }

    var region: MuscleGroup? {
        regionRawValue.flatMap { MuscleGroup(rawValue: $0) }
    }

    var measurement: ExerciseMeasurement {
        ExerciseLibrary.measurement(forExercise: name)
    }
}

@Model
final class WorkoutTemplate {
    var name: String
    var createdAt: Date
    var programRawValue: String?
    var exerciseNames: [String]

    init(name: String, program: WorkoutProgram? = nil, exerciseNames: [String]) {
        self.name = name
        self.createdAt = .now
        self.programRawValue = program?.rawValue
        self.exerciseNames = exerciseNames
    }

    var program: WorkoutProgram? {
        programRawValue.flatMap { WorkoutProgram(rawValue: $0) }
    }
}

@Model
final class UserProfile {
    var height: Double?
    var autoRestTimerEnabled: Bool = false
    var autoRestTimerMinutes: Int = 3

    init(height: Double? = nil, autoRestTimerEnabled: Bool = false, autoRestTimerMinutes: Int = 3) {
        self.height = height
        self.autoRestTimerEnabled = autoRestTimerEnabled
        self.autoRestTimerMinutes = autoRestTimerMinutes
    }
}

@Model
final class WeightEntry {
    var date: Date
    var weight: Double

    init(date: Date = .now, weight: Double) {
        self.date = date
        self.weight = weight
    }
}

enum BMICalculator {
    static func bmi(weight: Double, heightCm: Double) -> Double? {
        guard heightCm > 0 else { return nil }
        let heightMeters = heightCm / 100
        return weight / (heightMeters * heightMeters)
    }

    static func category(bmi: Double) -> String {
        switch bmi {
        case ..<18.5: "Zayıf"
        case 18.5..<25: "Normal"
        case 25..<30: "Fazla Kilolu"
        default: "Obez"
        }
    }
}

@Model
final class SetEntry {
    var reps: Int
    var weight: Double
    var durationMinutes: Int?
    var exercise: ExerciseEntry?

    init(reps: Int = 0, weight: Double = 0, durationMinutes: Int? = nil) {
        self.reps = reps
        self.weight = weight
        self.durationMinutes = durationMinutes
    }
}
