import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var date: Date
    var programRawValue: String?
    @Relationship(deleteRule: .cascade, inverse: \ExerciseEntry.session)
    var exercises: [ExerciseEntry]

    init(date: Date = .now, program: WorkoutProgram? = nil, exercises: [ExerciseEntry] = []) {
        self.date = date
        self.programRawValue = program?.rawValue
        self.exercises = exercises
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
    var weight: Double?
    var height: Double?

    init(weight: Double? = nil, height: Double? = nil) {
        self.weight = weight
        self.height = height
    }

    var bmi: Double? {
        guard let weight, let height, height > 0 else { return nil }
        let heightMeters = height / 100
        return weight / (heightMeters * heightMeters)
    }

    var bmiCategory: String? {
        guard let bmi else { return nil }
        switch bmi {
        case ..<18.5: return "Zayıf"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Fazla Kilolu"
        default: return "Obez"
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
